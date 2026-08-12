import 'dart:async';

import 'package:jaspr/jaspr.dart';
import 'package:jaspr_hooks/jaspr_hooks.dart';
import 'package:jaspr_test/jaspr_test.dart';

import 'support/capturing_binding.dart';
import 'support/harness.dart';

void main() {
  group('useLatest', () {
    testComponents('keeps one reference updated without notifying', (tester) async {
      final harness = TestHarnessController();
      var current = 1;
      var builds = 0;
      ObjectRef<int>? latest;

      Component child() => HookBuilder(
        builder: (context) {
          builds++;
          latest = useLatest(current);
          return Component.text('latest:${latest!.value}');
        },
      );

      tester.pumpComponent(TestHarness(controller: harness, builder: child));
      final firstReference = latest;

      current = 2;
      harness.rebuild();
      await tester.pump();

      expect(latest, same(firstReference));
      expect(latest!.value, 2);
      expect(builds, 2);

      latest!.value = 3;
      await tester.pump();
      expect(builds, 2);
    });
  });

  group('useDisposable', () {
    testComponents('owns keyed generations and retains their disposer', (tester) async {
      final harness = TestHarnessController();
      final events = <String>[];
      var generation = 0;
      var disposerLabel = 'first';
      _Resource? resource;

      Component child() => HookBuilder(
        builder: (context) {
          final generationForBuild = generation;
          final labelForBuild = disposerLabel;
          resource = useDisposable<_Resource>(
            () {
              events.add('create:$generationForBuild');
              return _Resource(generationForBuild);
            },
            (value) => events.add('dispose:$labelForBuild:${value.generation}'),
            <Object?>[generation],
          );
          return const Component.empty();
        },
      );

      tester.pumpComponent(TestHarness(controller: harness, builder: child));
      final firstResource = resource;

      disposerLabel = 'ignored';
      harness.rebuild();
      await tester.pump();
      expect(resource, same(firstResource));

      generation = 1;
      disposerLabel = 'second';
      harness.rebuild();
      await tester.pump();

      expect(resource, isNot(same(firstResource)));
      expect(
        events,
        <String>['create:0', 'create:1', 'dispose:first:0'],
      );

      harness.unmountChild();
      await tester.pump();
      expect(events.last, 'dispose:second:1');
    });

    test('isolates disposer errors and continues reverse cleanup', () async {
      final binding = CapturingTestComponentsBinding(isClient: true);
      addTearDown(binding.detachRootComponent);
      final harness = TestHarnessController();
      final events = <String>[];

      binding.attachRootComponent(
        TestHarness(
          controller: harness,
          builder: () => HookBuilder(
            builder: (context) {
              useDisposable(
                () => _Resource(1),
                (value) => events.add('dispose:${value.generation}'),
              );
              useDisposable(
                () => _Resource(2),
                (value) {
                  events.add('dispose:${value.generation}');
                  throw StateError('expected disposal failure');
                },
              );
              return const Component.empty();
            },
          ),
        ),
      );

      harness.unmountChild();
      await binding.pump();

      expect(events, <String>['dispose:2', 'dispose:1']);
      expect(binding.errors.single.error, isA<StateError>());
    });
  });

  group('useExternalStore', () {
    testComponents('subscribes, filters snapshots, switches, and unsubscribes', (tester) async {
      final harness = TestHarnessController();
      final first = _ExternalIntStore(1);
      final second = _ExternalIntStore(10);
      ExternalStoreSubscribe subscribe = first.subscribe;
      int Function() getSnapshot = first.getSnapshot;
      var builds = 0;
      int? snapshot;

      Component child() => HookBuilder(
        builder: (context) {
          builds++;
          snapshot = useExternalStore(subscribe, getSnapshot);
          return Component.text('snapshot:$snapshot');
        },
      );

      tester.pumpComponent(TestHarness(controller: harness, builder: child));
      expect(snapshot, 1);
      expect(first.activeListeners, 1);

      first.emit(1);
      await tester.pump();
      expect(builds, 1);

      first.emit(2);
      await tester.pump();
      expect(snapshot, 2);
      expect(builds, 2);

      subscribe = second.subscribe;
      getSnapshot = second.getSnapshot;
      harness.rebuild();
      await tester.pump();

      expect(snapshot, 10);
      expect(first.activeListeners, 0);
      expect(second.activeListeners, 1);

      harness.unmountChild();
      await tester.pump();
      expect(second.activeListeners, 0);
    });

    test('reports a replacement cleanup failure and still connects the new source', () async {
      final binding = CapturingTestComponentsBinding(isClient: true);
      addTearDown(binding.detachRootComponent);
      final harness = TestHarnessController();
      final events = <String>[];
      var useSecond = false;
      var firstSnapshot = 1;
      var secondSnapshot = 10;
      VoidCallback? firstListener;
      VoidCallback? secondListener;
      int? rendered;

      Dispose firstSubscribe(VoidCallback notify) {
        firstListener = notify;
        events.add('subscribe:first');
        return () {
          events.add('unsubscribe:first');
          throw StateError('expected replacement cleanup failure');
        };
      }

      Dispose secondSubscribe(VoidCallback notify) {
        secondListener = notify;
        events.add('subscribe:second');
        return () => events.add('unsubscribe:second');
      }

      binding.attachRootComponent(
        TestHarness(
          controller: harness,
          builder: () => HookBuilder(
            builder: (context) {
              rendered = useExternalStore(
                useSecond ? secondSubscribe : firstSubscribe,
                useSecond ? () => secondSnapshot : () => firstSnapshot,
              );
              return const Component.empty();
            },
          ),
        ),
      );

      useSecond = true;
      harness.rebuild();
      await binding.pump();

      expect(rendered, 10);
      expect(
        events,
        <String>['subscribe:first', 'unsubscribe:first', 'subscribe:second'],
      );
      expect(binding.errors.single.error, isA<StateError>());

      firstSnapshot = 2;
      firstListener!();
      await binding.pump();
      expect(rendered, 10);

      secondSnapshot = 11;
      secondListener!();
      await binding.pump();
      expect(rendered, 11);
    });

    testComponents('ignores notifications retained by a replaced source', (tester) async {
      final harness = TestHarnessController();
      final firstListeners = <VoidCallback>[];
      final secondListeners = <VoidCallback>[];
      var firstSnapshot = 1;
      var secondSnapshot = 10;
      var useSecond = false;
      var firstReads = 0;
      var secondReads = 0;
      int? snapshot;

      Dispose firstSubscribe(VoidCallback notify) {
        firstListeners.add(notify);
        return () {};
      }

      Dispose secondSubscribe(VoidCallback notify) {
        secondListeners.add(notify);
        return () {};
      }

      int getFirstSnapshot() {
        firstReads++;
        return firstSnapshot;
      }

      int getSecondSnapshot() {
        secondReads++;
        return secondSnapshot;
      }

      Component child() => HookBuilder(
        builder: (context) {
          snapshot = useExternalStore(
            useSecond ? secondSubscribe : firstSubscribe,
            useSecond ? getSecondSnapshot : getFirstSnapshot,
          );
          return const Component.empty();
        },
      );

      tester.pumpComponent(TestHarness(controller: harness, builder: child));
      expect(snapshot, 1);

      useSecond = true;
      harness.rebuild();
      await tester.pump();
      expect(snapshot, 10);

      final readsBeforeStaleNotification = secondReads;
      firstSnapshot = 2;
      firstListeners.single();
      await tester.pump();

      expect(snapshot, 10);
      expect(secondReads, readsBeforeStaleNotification);

      secondSnapshot = 11;
      secondListeners.single();
      await tester.pump();
      expect(snapshot, 11);
      expect(firstReads, 2);
    });

    testComponents('retains the previous snapshot when custom equality matches', (tester) async {
      final harness = TestHarnessController();
      final listeners = <VoidCallback>{};
      var snapshot = _RevisionSnapshot(1, 'first');
      _RevisionSnapshot? rendered;

      Dispose subscribe(VoidCallback notify) {
        listeners.add(notify);
        return () => listeners.remove(notify);
      }

      Component child() => HookBuilder(
        builder: (context) {
          rendered = useExternalStore<_RevisionSnapshot>(
            subscribe,
            () => snapshot,
            equals: (previous, current) => previous.revision == current.revision,
          );
          return const Component.empty();
        },
      );

      tester.pumpComponent(TestHarness(controller: harness, builder: child));
      final original = rendered;

      snapshot = _RevisionSnapshot(1, 'equal replacement');
      harness.rebuild();
      await tester.pump();
      expect(rendered, same(original));

      snapshot = _RevisionSnapshot(2, 'changed');
      for (final listener in listeners.toList()) {
        listener();
      }
      await tester.pump();
      expect(rendered, same(snapshot));
    });

    test('reports a failed unsubscribe and continues reverse cleanup', () async {
      final binding = CapturingTestComponentsBinding(isClient: true);
      addTearDown(binding.detachRootComponent);
      final harness = TestHarnessController();
      final events = <String>[];

      Dispose firstSubscribe(VoidCallback notify) {
        events.add('subscribe:first');
        return () => events.add('unsubscribe:first');
      }

      Dispose secondSubscribe(VoidCallback notify) {
        events.add('subscribe:second');
        return () {
          events.add('unsubscribe:second');
          throw StateError('expected unsubscribe failure');
        };
      }

      binding.attachRootComponent(
        TestHarness(
          controller: harness,
          builder: () => HookBuilder(
            builder: (context) {
              useExternalStore(
                firstSubscribe,
                () => 1,
              );
              useExternalStore(
                secondSubscribe,
                () => 2,
              );
              return const Component.empty();
            },
          ),
        ),
      );

      harness.unmountChild();
      await binding.pump();

      expect(
        events,
        <String>[
          'subscribe:first',
          'subscribe:second',
          'unsubscribe:second',
          'unsubscribe:first',
        ],
      );
      expect(binding.errors.single.error, isA<StateError>());
    });

    test('unsubscribes when the post-subscribe snapshot read fails', () {
      final binding = CapturingTestComponentsBinding(isClient: true);
      addTearDown(binding.detachRootComponent);
      var reads = 0;
      var activeListeners = 0;

      binding.attachRootComponent(
        HookBuilder(
          builder: (context) {
            useExternalStore(
              (notify) {
                activeListeners++;
                return () => activeListeners--;
              },
              () {
                reads++;
                if (reads > 1) {
                  throw StateError('expected snapshot failure');
                }
                return 1;
              },
            );
            return const Component.empty();
          },
        ),
      );

      expect(binding.errors.single.error, isA<StateError>());
      expect(activeListeners, 0);
    });

    testComponents('uses Dart equality with NaN and signed-zero distinctions', (tester) async {
      final listeners = <VoidCallback>{};
      var snapshot = double.nan;
      var builds = 0;

      tester.pumpComponent(
        HookBuilder(
          builder: (context) {
            builds++;
            useExternalStore<double>(
              (notify) {
                listeners.add(notify);
                return () => listeners.remove(notify);
              },
              () => snapshot,
            );
            return const Component.empty();
          },
        ),
      );

      for (final listener in listeners.toList()) {
        listener();
      }
      await tester.pump();
      expect(builds, 1, reason: 'NaN snapshots preserve state');

      snapshot = 0.0;
      for (final listener in listeners.toList()) {
        listener();
      }
      await tester.pump();
      expect(builds, 2);

      snapshot = -0.0;
      for (final listener in listeners.toList()) {
        listener();
      }
      await tester.pump();
      expect(builds, 3, reason: 'signed zero snapshots are distinct');
    });

    test('uses the server snapshot through the first client frame', () async {
      final binding = CapturingTestComponentsBinding(
        isClient: true,
        deferInitialPostFrameCallbacks: true,
      );
      addTearDown(binding.detachRootComponent);
      final store = _ExternalIntStore(2);
      int? snapshot;

      binding.attachRootComponent(
        HookBuilder(
          builder: (context) {
            snapshot = useExternalStore(
              store.subscribe,
              store.getSnapshot,
              getServerSnapshot: () => 1,
            );
            return Component.text('snapshot:$snapshot');
          },
        ),
      );

      expect(snapshot, 1);
      expect(store.activeListeners, 0);

      binding.flushDeferredPostFrameCallbacks();
      await binding.pump();

      expect(snapshot, 2);
      expect(store.activeListeners, 1);
    });

    test('preserves a custom-equal hydration snapshot', () async {
      final binding = CapturingTestComponentsBinding(
        isClient: true,
        deferInitialPostFrameCallbacks: true,
      );
      addTearDown(binding.detachRootComponent);
      final serverSnapshot = _RevisionSnapshot(1, 'server');
      final clientSnapshot = _RevisionSnapshot(1, 'client');
      _RevisionSnapshot? rendered;

      binding.attachRootComponent(
        HookBuilder(
          builder: (context) {
            rendered = useExternalStore<_RevisionSnapshot>(
              (notify) => () {},
              () => clientSnapshot,
              getServerSnapshot: () => serverSnapshot,
              equals: (previous, current) => previous.revision == current.revision,
            );
            return const Component.empty();
          },
        ),
      );

      expect(rendered, same(serverSnapshot));
      binding.flushDeferredPostFrameCallbacks();
      await binding.pump();
      expect(rendered, same(serverSnapshot));
    });

    test('reports hydration activation failures without blocking later callbacks', () async {
      final binding = CapturingTestComponentsBinding(
        isClient: true,
        deferInitialPostFrameCallbacks: true,
      );
      addTearDown(binding.detachRootComponent);
      var reads = 0;
      var activeListeners = 0;
      var laterCallbackRan = false;

      binding.attachRootComponent(
        HookBuilder(
          builder: (context) {
            useExternalStore(
              (notify) {
                activeListeners++;
                return () => activeListeners--;
              },
              () {
                reads++;
                throw StateError('expected hydration snapshot failure');
              },
              getServerSnapshot: () => 1,
            );
            return const Component.empty();
          },
        ),
      );
      binding.addPostFrameCallback(() => laterCallbackRan = true);

      binding.flushDeferredPostFrameCallbacks();
      await binding.pump();

      expect(reads, 1);
      expect(activeListeners, 0);
      expect(laterCallbackRan, isTrue);
      expect(binding.errors.single.error, isA<StateError>());
    });

    test('requires a deterministic snapshot on the server', () {
      final binding = CapturingTestComponentsBinding(isClient: false);
      addTearDown(binding.detachRootComponent);
      final store = _ExternalIntStore(1);

      binding.attachRootComponent(
        HookBuilder(
          builder: (context) {
            useExternalStore(store.subscribe, store.getSnapshot);
            return const Component.empty();
          },
        ),
      );

      expect(binding.errors.single.error, isA<StateError>());
      expect(binding.errors.single.error.toString(), contains('getServerSnapshot'));
      expect(store.activeListeners, 0);
    });

    testComponents(
      'reads the server snapshot without subscribing',
      (tester) async {
        final store = _ExternalIntStore(2);
        int? snapshot;

        tester.pumpComponent(
          HookBuilder(
            builder: (context) {
              snapshot = useExternalStore(
                store.subscribe,
                store.getSnapshot,
                getServerSnapshot: () => 1,
              );
              return const Component.empty();
            },
          ),
        );

        expect(snapshot, 1);
        expect(store.activeListeners, 0);
      },
      isClient: false,
    );
  });

  group('useInherited', () {
    testComponents('reads and subscribes to the nearest inherited component', (tester) async {
      final harness = TestHarnessController();
      var inheritedValue = 1;
      var builds = 0;
      int? value;

      Component child() => _IntInherited(
        value: inheritedValue,
        child: HookBuilder(
          builder: (context) {
            builds++;
            value = useInherited<_IntInherited>()?.value;
            return Component.text('inherited:$value');
          },
        ),
      );

      tester.pumpComponent(TestHarness(controller: harness, builder: child));
      expect(value, 1);

      inheritedValue = 2;
      harness.rebuild();
      await tester.pump();

      expect(value, 2);
      expect(builds, 2);
    });

    testComponents('returns null without a matching ancestor', (tester) async {
      _IntInherited? inherited;
      tester.pumpComponent(
        HookBuilder(
          builder: (context) {
            inherited = useInherited<_IntInherited>();
            return const Component.empty();
          },
        ),
      );
      expect(inherited, isNull);
    });
  });

  group('useImperativeHandle', () {
    testComponents('replaces on target or key changes and clears owned handles', (tester) async {
      final harness = TestHarnessController();
      final firstTarget = ObjectRef<_Handle?>(null);
      final secondTarget = ObjectRef<_Handle?>(null);
      var target = firstTarget;
      var key = 0;
      var creations = 0;

      Component child() => HookBuilder(
        builder: (context) {
          useImperativeHandle(
            target,
            () => _Handle(++creations),
            <Object?>[key],
          );
          return const Component.empty();
        },
      );

      tester.pumpComponent(TestHarness(controller: harness, builder: child));
      final firstHandle = firstTarget.value;
      expect(firstHandle?.generation, 1);

      harness.rebuild();
      await tester.pump();
      expect(firstTarget.value, same(firstHandle));
      expect(creations, 1);

      target = secondTarget;
      harness.rebuild();
      await tester.pump();
      expect(firstTarget.value, isNull);
      expect(secondTarget.value?.generation, 2);

      key = 1;
      harness.rebuild();
      await tester.pump();
      expect(secondTarget.value?.generation, 3);

      harness.unmountChild();
      await tester.pump();
      expect(secondTarget.value, isNull);
    });

    testComponents('does not clear a handle replaced by its owner', (tester) async {
      final harness = TestHarnessController();
      final target = ObjectRef<_Handle?>(null);
      final replacement = _Handle(2);

      tester.pumpComponent(
        TestHarness(
          controller: harness,
          builder: () => HookBuilder(
            builder: (context) {
              useImperativeHandle(target, () => _Handle(1), const <Object?>[]);
              return const Component.empty();
            },
          ),
        ),
      );

      target.value = replacement;
      harness.unmountChild();
      await tester.pump();
      expect(target.value, same(replacement));
    });
  });

  group('timers', () {
    testComponents('timeout keeps the latest callback and cancels when disabled', (tester) async {
      final harness = TestHarnessController();
      final events = <String>[];
      var callbackLabel = 'first';
      Duration? delay = const Duration(milliseconds: 30);

      Component child() => HookBuilder(
        builder: (context) {
          final labelForBuild = callbackLabel;
          useTimeout(() => events.add(labelForBuild), delay);
          return const Component.empty();
        },
      );

      tester.pumpComponent(TestHarness(controller: harness, builder: child));
      await Future<void>.delayed(const Duration(milliseconds: 5));

      callbackLabel = 'second';
      harness.rebuild();
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(events, <String>['second']);

      delay = const Duration(milliseconds: 20);
      harness.rebuild();
      await tester.pump();
      delay = null;
      harness.rebuild();
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(events, <String>['second']);
    });

    testComponents('interval supports immediate invocation, freshness, and cancellation', (tester) async {
      final harness = TestHarnessController();
      final events = <String>[];
      var callbackLabel = 'first';
      Duration? interval = const Duration(milliseconds: 20);

      Component child() => HookBuilder(
        builder: (context) {
          final labelForBuild = callbackLabel;
          useInterval(
            () => events.add(labelForBuild),
            interval,
            immediate: true,
          );
          return const Component.empty();
        },
      );

      tester.pumpComponent(TestHarness(controller: harness, builder: child));
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(events, <String>['first']);

      callbackLabel = 'second';
      harness.rebuild();
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(events, contains('second'));

      interval = null;
      harness.rebuild();
      await tester.pump();
      final countAfterCancellation = events.length;
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(events, hasLength(countAfterCancellation));
    });

    testComponents(
      'does not create timeout or interval activity on the server',
      (tester) async {
        final events = <String>[];

        tester.pumpComponent(
          HookBuilder(
            builder: (context) {
              useTimeout(() => events.add('timeout'), Duration.zero);
              useInterval(
                () => events.add('interval'),
                const Duration(milliseconds: 1),
                immediate: true,
              );
              return const Component.empty();
            },
          ),
        );

        await Future<void>.delayed(const Duration(milliseconds: 10));
        expect(events, isEmpty);
      },
      isClient: false,
    );
  });
}

final class _Resource {
  const _Resource(this.generation);

  final int generation;
}

final class _ExternalIntStore {
  _ExternalIntStore(this._value);

  final Set<VoidCallback> _listeners = <VoidCallback>{};
  int _value;

  int get activeListeners => _listeners.length;

  int getSnapshot() => _value;

  Dispose subscribe(VoidCallback listener) {
    _listeners.add(listener);
    return () => _listeners.remove(listener);
  }

  void emit(int value) {
    _value = value;
    for (final listener in _listeners.toList()) {
      listener();
    }
  }
}

final class _IntInherited extends InheritedComponent {
  const _IntInherited({required this.value, required super.child});

  final int value;

  @override
  bool updateShouldNotify(_IntInherited oldComponent) => value != oldComponent.value;
}

final class _Handle {
  const _Handle(this.generation);

  final int generation;
}

final class _RevisionSnapshot {
  const _RevisionSnapshot(this.revision, this.label);

  final int revision;
  final String label;
}
