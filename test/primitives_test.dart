import 'dart:async';

import 'package:jaspr/jaspr.dart';
import 'package:jaspr_hooks/jaspr_hooks.dart';
import 'package:jaspr_test/jaspr_test.dart';

import 'support/capturing_binding.dart';
import 'support/harness.dart';

void main() {
  group('state and references', () {
    testComponents('useState preserves state, rebuilds, and owns disposal', (
      tester,
    ) async {
      final harness = TestHarnessController();
      var initialValue = 1;
      ValueNotifier<int>? state;
      var builds = 0;

      Component child() => HookBuilder(
        builder: (context) {
          builds++;
          state = useState(initialValue);
          return Component.text('value:${state!.value}');
        },
      );

      tester.pumpComponent(TestHarness(controller: harness, builder: child));
      final original = state;
      initialValue = 99;
      harness.rebuild();
      await tester.pump();

      expect(state, same(original));
      expect(state!.value, 1, reason: 'later initial values are ignored');

      state!.value = 2;
      await tester.pump();
      expect(builds, 3);
      expect(find.text('value:2'), findsOneComponent);

      harness.unmountChild();
      await tester.pump();
      expect(() => state!.value = 3, throwsA(anything));
    });

    testComponents('useRef preserves a mutable cell without rebuilding', (
      tester,
    ) async {
      final harness = TestHarnessController();
      ObjectRef<int>? ref;
      var builds = 0;

      Component child() => HookBuilder(
        builder: (context) {
          builds++;
          ref = useRef(1);
          return Component.text('ref:${ref!.value}');
        },
      );

      tester.pumpComponent(TestHarness(controller: harness, builder: child));
      final original = ref;
      ref!.value = 2;
      await tester.pump();
      expect(builds, 1);

      harness.rebuild();
      await tester.pump();
      expect(ref, same(original));
      expect(find.text('ref:2'), findsOneComponent);
    });

    testComponents('useIsMounted changes after disposal', (tester) async {
      final harness = TestHarnessController();
      IsMounted? isMounted;

      Component child() => HookBuilder(
        builder: (context) {
          isMounted = useIsMounted();
          return const Component.empty();
        },
      );

      tester.pumpComponent(TestHarness(controller: harness, builder: child));
      expect(isMounted!(), isTrue);

      harness.unmountChild();
      await tester.pump();
      expect(isMounted!(), isFalse);
    });
  });

  group('memoization', () {
    testComponents('useMemoized and useCallback use ordered keys', (tester) async {
      final harness = TestHarnessController();
      var key = 0;
      var memoCalls = 0;
      Object? memoized;
      int Function()? callback;

      Component child() => HookBuilder(
        builder: (context) {
          memoized = useMemoized(() {
            memoCalls++;
            return Object();
          }, <Object?>[key]);
          callback = useCallback(() => key, <Object?>[key]);
          return const Component.empty();
        },
      );

      tester.pumpComponent(TestHarness(controller: harness, builder: child));
      final firstMemo = memoized;
      final firstCallback = callback;

      harness.rebuild();
      await tester.pump();
      expect(memoized, same(firstMemo));
      expect(callback, same(firstCallback));
      expect(memoCalls, 1);

      key = 1;
      harness.rebuild();
      await tester.pump();
      expect(memoized, isNot(same(firstMemo)));
      expect(callback, isNot(same(firstCallback)));
      expect(callback!(), 1);
      expect(memoCalls, 2);
    });
  });

  group('previous values and reducers', () {
    testComponents('usePrevious exposes the preceding build value', (tester) async {
      final harness = TestHarnessController();
      var value = 'first';
      String? previous;

      Component child() => HookBuilder(
        builder: (context) {
          previous = usePrevious(value);
          return Component.text('previous:$previous');
        },
      );

      tester.pumpComponent(TestHarness(controller: harness, builder: child));
      expect(previous, isNull);

      value = 'second';
      harness.rebuild();
      await tester.pump();
      expect(previous, 'first');

      value = 'third';
      harness.rebuild();
      await tester.pump();
      expect(previous, 'second');
    });

    testComponents('useValueChanged carries its prior result', (tester) async {
      final harness = TestHarnessController();
      var value = 1;
      int? result;
      final calls = <String>[];

      Component child() => HookBuilder(
        builder: (context) {
          result = useValueChanged<int, int>(value, (oldValue, oldResult) {
            calls.add('$oldValue:$oldResult');
            return (oldResult ?? 0) + oldValue;
          });
          return Component.text('$result');
        },
      );

      tester.pumpComponent(TestHarness(controller: harness, builder: child));
      expect(result, isNull);
      expect(calls, isEmpty);

      value = 2;
      harness.rebuild();
      await tester.pump();
      expect(result, 1);

      value = 3;
      harness.rebuild();
      await tester.pump();
      expect(result, 3);
      expect(calls, <String>['1:null', '2:1']);
    });

    testComponents('useReducer initializes and dispatches synchronously', (
      tester,
    ) async {
      Store<int, int>? store;
      var reducerCalls = 0;

      tester.pumpComponent(
        HookBuilder(
          builder: (context) {
            store = useReducer<int, int>(
              (state, action) {
                reducerCalls++;
                return state + action;
              },
              initialState: 10,
              initialAction: 2,
            );
            return Component.text('state:${store!.state}');
          },
        ),
      );

      expect(store!.state, 12);
      expect(reducerCalls, 1);

      store!.dispatch(3);
      expect(store!.state, 15);
      await tester.pump();
      expect(find.text('state:15'), findsOneComponent);

      store!.dispatch(0);
      await tester.pump();
      expect(store!.state, 15);
      expect(reducerCalls, 3);
    });
  });

  group('effects', () {
    testComponents('useEffect without keys cleans before every rerun', (
      tester,
    ) async {
      final harness = TestHarnessController();
      final events = <String>[];
      var build = 0;

      Component child() => HookBuilder(
        builder: (context) {
          final current = build;
          useEffect(() {
            events.add('effect:$current');
            return () => events.add('cleanup:$current');
          });
          return const Component.empty();
        },
      );

      tester.pumpComponent(TestHarness(controller: harness, builder: child));
      expect(events, <String>['effect:0']);

      build = 1;
      harness.rebuild();
      await tester.pump();
      expect(
        events,
        <String>['effect:0', 'cleanup:0', 'effect:1'],
      );
    });

    testComponents('keyed effect initializes before replaced cleanup', (
      tester,
    ) async {
      final harness = TestHarnessController();
      final events = <String>[];
      var key = 0;

      Component child() => HookBuilder(
        builder: (context) {
          final current = key;
          useEffect(() {
            events.add('effect:$current');
            return () => events.add('cleanup:$current');
          }, <Object?>[key]);
          return const Component.empty();
        },
      );

      tester.pumpComponent(TestHarness(controller: harness, builder: child));
      key = 1;
      harness.rebuild();
      await tester.pump();

      expect(
        events,
        <String>['effect:0', 'effect:1', 'cleanup:0'],
      );

      harness.unmountChild();
      await tester.pump();
      expect(events.last, 'cleanup:1');
    });

    test('one failing cleanup does not prevent the others', () async {
      final binding = CapturingTestComponentsBinding(isClient: true);
      addTearDown(binding.detachRootComponent);
      final harness = TestHarnessController();
      final events = <String>[];

      binding.attachRootComponent(
        TestHarness(
          controller: harness,
          builder: () => HookBuilder(
            builder: (context) {
              useEffect(() {
                return () {
                  events.add('cleanup:first');
                  throw StateError('cleanup failed');
                };
              }, const <Object?>[]);
              useEffect(() {
                return () => events.add('cleanup:second');
              }, const <Object?>[]);
              return const Component.empty();
            },
          ),
        ),
      );

      harness.unmountChild();
      await binding.pump();

      expect(
        events,
        containsAll(<String>['cleanup:first', 'cleanup:second']),
      );
      expect(binding.errors.single.error, isA<StateError>());
    });

    test(
      'unmount reports before clearing component and continues reverse cleanup',
      () async {
        final binding = CapturingTestComponentsBinding(isClient: true);
        addTearDown(binding.detachRootComponent);
        final harness = TestHarnessController();
        final events = <String>[];

        binding.attachRootComponent(
          TestHarness(
            controller: harness,
            builder: () => HookBuilder(
              builder: (context) {
                useEffect(() {
                  return () => events.add('cleanup:first');
                }, const <Object?>[]);
                useEffect(() {
                  return () => events.add('cleanup:second');
                }, const <Object?>[]);
                useEffect(() {
                  return () {
                    events.add('cleanup:third');
                    throw StateError('third cleanup failed');
                  };
                }, const <Object?>[]);
                return const Component.empty();
              },
            ),
          ),
        );

        harness.unmountChild();
        await binding.pump();

        expect(
          events,
          <String>['cleanup:third', 'cleanup:second', 'cleanup:first'],
        );
        expect(binding.errors.single.error, isA<StateError>());
        expect(binding.reportingComponentTypes, <Type>[HookBuilder]);
      },
    );

    test('throwing post-frame effect does not block later callbacks', () {
      final binding = CapturingTestComponentsBinding(isClient: true);
      addTearDown(binding.detachRootComponent);
      final events = <String>[];

      binding.attachRootComponent(
        HookBuilder(
          builder: (context) {
            usePostFrameEffect(() {
              events.add('throwing');
              throw StateError('post-frame effect failed');
            }, const <Object?>[]);
            usePostFrameEffect(() {
              events.add('later');
              return null;
            }, const <Object?>[]);
            return const Component.empty();
          },
        ),
      );

      expect(events, <String>['throwing', 'later']);
      expect(binding.errors.single.error, isA<StateError>());
      expect(binding.reportingComponentTypes, <Type>[HookBuilder]);
    });

    test('disposing before the frame invalidates a queued post-frame effect', () async {
      final binding = CapturingTestComponentsBinding(
        isClient: true,
        deferInitialPostFrameCallbacks: true,
      );
      addTearDown(binding.detachRootComponent);
      final harness = TestHarnessController();
      final events = <String>[];

      binding.attachRootComponent(
        TestHarness(
          controller: harness,
          builder: () => HookBuilder(
            builder: (context) {
              usePostFrameEffect(() {
                events.add('post-frame');
                return null;
              }, const <Object?>[]);
              events.add('build');
              return const Component.empty();
            },
          ),
        ),
      );
      expect(events, <String>['build']);

      harness.unmountChild();
      await binding.pump();

      expect(events, <String>['build']);
    });

    test('changing keys before the frame runs only the latest effect', () async {
      final binding = CapturingTestComponentsBinding(
        isClient: true,
        deferInitialPostFrameCallbacks: true,
      );
      addTearDown(binding.detachRootComponent);
      final harness = TestHarnessController();
      final events = <String>[];
      var key = 0;

      Component child() => HookBuilder(
        builder: (context) {
          final current = key;
          usePostFrameEffect(() {
            events.add('post:$current');
            return null;
          }, <Object?>[current]);
          events.add('build:$current');
          return const Component.empty();
        },
      );

      binding.attachRootComponent(
        TestHarness(controller: harness, builder: child),
      );
      expect(events, <String>['build:0']);

      key = 1;
      harness.rebuild();
      await binding.pump();

      expect(events, <String>['build:0', 'build:1', 'post:1']);
    });

    testComponents('usePostFrameEffect runs after build and cleans up', (
      tester,
    ) async {
      final harness = TestHarnessController();
      final events = <String>[];
      var key = 0;

      Component child() => HookBuilder(
        builder: (context) {
          final current = key;
          usePostFrameEffect(() {
            events.add('post:$current');
            return () => events.add('cleanup:$current');
          }, <Object?>[key]);
          events.add('build:$current');
          return const Component.empty();
        },
      );

      tester.pumpComponent(TestHarness(controller: harness, builder: child));
      expect(events, <String>['build:0', 'post:0']);

      key = 1;
      harness.rebuild();
      await tester.pump();
      expect(
        events,
        <String>[
          'build:0',
          'post:0',
          'build:1',
          'cleanup:0',
          'post:1',
        ],
      );
    });
  });

  group('debounce', () {
    testComponents('useDebounced publishes only the latest delayed value', (
      tester,
    ) async {
      final harness = TestHarnessController();
      var source = 'a';
      String? debounced;

      Component child() => HookBuilder(
        builder: (context) {
          debounced = useDebounced(source, const Duration(milliseconds: 15));
          return Component.text('debounced:$debounced');
        },
      );

      tester.pumpComponent(TestHarness(controller: harness, builder: child));
      expect(debounced, isNull);

      source = 'b';
      harness.rebuild();
      await tester.pump();
      source = 'c';
      harness.rebuild();
      await tester.pump();

      await Future<void>.delayed(const Duration(milliseconds: 30));
      await tester.pump();
      expect(debounced, 'c');
      expect(find.text('debounced:c'), findsOneComponent);
    });
  });
}
