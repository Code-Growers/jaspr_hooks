import 'package:jaspr/jaspr.dart';
import 'package:jaspr_hooks/jaspr_hooks.dart';
import 'package:jaspr_test/jaspr_test.dart';

import 'support/capturing_binding.dart';
import 'support/harness.dart';

void main() {
  group('hook hosts', () {
    test('use throws outside a hook build', () {
      expect(
        () => use(_ProbeHook('outside', <String>[])),
        throwsA(isA<StateError>()),
      );
    });

    testComponents('HookBuilder exposes its own BuildContext', (tester) async {
      BuildContext? builderContext;
      BuildContext? hookContext;

      tester.pumpComponent(
        HookBuilder(
          builder: (context) {
            builderContext = context;
            hookContext = useContext();
            return const Component.text('built');
          },
        ),
      );

      expect(hookContext, same(builderContext));
      expect(find.text('built'), findsOneComponent);
    });

    testComponents('HookComponent owns hook state and rebuilds', (tester) async {
      ValueNotifier<int>? counter;
      ValueNotifier<int>? firstCounter;
      tester.pumpComponent(
        _StatelessHookHost(
          onBuild: (value) {
            firstCounter ??= value;
            counter = value;
          },
        ),
      );
      expect(find.text('count:0'), findsOneComponent);

      counter!.value = 1;
      await tester.pump();

      expect(find.text('count:1'), findsOneComponent);
      expect(counter, same(firstCounter));
    });

    testComponents('StatefulHookComponent supports hooks from State.build', (
      tester,
    ) async {
      ValueNotifier<int>? counter;
      tester.pumpComponent(
        _StatefulHookHost(onBuild: (value) => counter = value),
      );

      expect(find.text('stateful:2'), findsOneComponent);
      counter!.value = 3;
      await tester.pump();
      expect(find.text('stateful:3'), findsOneComponent);
    });

    testComponents('StatefulHookComponent disposes State before hook resources', (
      tester,
    ) async {
      final harness = TestHarnessController();
      final events = <String>[];

      tester.pumpComponent(
        TestHarness(
          controller: harness,
          builder: () => _StatefulDisposalHost(events: events),
        ),
      );

      harness.unmountChild();
      await tester.pump();

      expect(
        events.where(
          (event) => event == 'state.dispose' || event == 'dispose:hook',
        ),
        <String>['state.dispose', 'dispose:hook'],
      );
    });

    test('stateful cleanup errors are reported after State.dispose and isolated', () async {
      final binding = CapturingTestComponentsBinding(isClient: true);
      addTearDown(binding.detachRootComponent);
      final harness = TestHarnessController();
      final events = <String>[];

      binding.attachRootComponent(
        TestHarness(
          controller: harness,
          builder: () => _StatefulEffectCleanupHost(events: events),
        ),
      );

      harness.unmountChild();
      await binding.pump();

      expect(
        events,
        <String>['state.dispose', 'cleanup:second', 'cleanup:first'],
      );
      expect(binding.errors.single.error, isA<StateError>());
      expect(
        binding.reportingComponentTypes,
        <Type>[_StatefulEffectCleanupHost],
      );
    });
  });

  group('identity and event hooks', () {
    testComponents('useEvent keeps identity and invokes the latest handler', (tester) async {
      final harness = TestHarnessController();
      var multiplier = 2;
      StableEventCallback<int, int>? callback;
      StableEventCallback<int, int>? first;

      tester.pumpComponent(
        TestHarness(
          controller: harness,
          builder: () => HookBuilder(
            builder: (context) {
              callback = useEvent<int, int>((value) => value * multiplier);
              first ??= callback;
              return const Component.empty();
            },
          ),
        ),
      );

      expect(callback!(3), 6);
      multiplier = 4;
      harness.rebuild();
      await tester.pump();
      expect(callback, same(first));
      expect(first!(3), 12);
    });

    testComponents('useId is stable, unique by hook slot, and prefix-aware', (tester) async {
      final harness = TestHarnessController();
      var prefix = 'field';
      var ids = <String>[];

      tester.pumpComponent(
        TestHarness(
          controller: harness,
          builder: () => HookBuilder(
            builder: (context) {
              ids = <String>[useId(prefix: prefix), useId(prefix: prefix)];
              return Component.text(ids.join(','));
            },
          ),
        ),
      );

      final initial = List<String>.of(ids);
      expect(initial.toSet(), hasLength(2));
      expect(initial, everyElement(startsWith('field-')));

      harness.rebuild();
      await tester.pump();
      expect(ids, initial);

      prefix = 'dialog';
      harness.rebuild();
      await tester.pump();
      expect(ids, everyElement(startsWith('dialog-')));
      expect(ids, isNot(initial));
    });

    test('useId rejects invalid prefixes', () async {
      expect(() => useId(), throwsStateError);
      final binding = CapturingTestComponentsBinding(isClient: true);
      addTearDown(binding.detachRootComponent);
      binding.attachRootComponent(
        HookBuilder(
          builder: (context) {
            useId(prefix: '');
            return const Component.empty();
          },
        ),
      );
      await binding.pump();
      expect(binding.errors.single.error, isA<ArgumentError>());
    });
  });

  group('ordered runtime', () {
    test('Hook.shouldPreserveState compares ordered key contents', () {
      final events = <String>[];
      expect(
        Hook.shouldPreserveState(
          _ProbeHook('a', events, keys: const <Object?>[1, 2]),
          _ProbeHook('b', events, keys: const <Object?>[1, 2]),
        ),
        isTrue,
      );
      expect(
        Hook.shouldPreserveState(
          _ProbeHook('a', events, keys: const <Object?>[1, 2]),
          _ProbeHook('b', events, keys: const <Object?>[2, 1]),
        ),
        isFalse,
      );
      expect(
        Hook.shouldPreserveState(
          _ProbeHook('a', events),
          _ProbeHook('b', events, keys: const <Object?>[]),
        ),
        isFalse,
      );
    });

    testComponents('preserves positional state across rebuilds', (tester) async {
      final harness = TestHarnessController();
      final events = <String>[];
      Object? firstA;
      Object? firstB;
      Object? nextA;
      Object? nextB;
      var build = 0;

      Component child() => HookBuilder(
        builder: (context) {
          final a = use(_ProbeHook('a', events));
          final b = use(_ProbeHook('b', events));
          if (build == 0) {
            firstA = a;
            firstB = b;
          } else {
            nextA = a;
            nextB = b;
          }
          return Component.text('$build');
        },
      );

      tester.pumpComponent(TestHarness(controller: harness, builder: child));
      build++;
      harness.rebuild();
      await tester.pump();

      expect(nextA, same(firstA));
      expect(nextB, same(firstB));
      expect(
        events,
        containsAllInOrder(<String>[
          'init:a',
          'build:a',
          'init:b',
          'build:b',
          'update:a->a',
          'build:a',
          'update:b->b',
          'build:b',
        ]),
      );
    });

    testComponents('key equality preserves and key changes replace state', (
      tester,
    ) async {
      final harness = TestHarnessController();
      final events = <String>[];
      List<Object?> keys = <Object?>[double.nan, 0.0];
      Object? token;
      _ProbeHookState? state;

      Component child() => HookBuilder(
        builder: (context) {
          token = use(
            _ProbeHook(
              'keyed',
              events,
              keys: keys,
              capture: (value) => state = value,
            ),
          );
          return const Component.empty();
        },
      );

      tester.pumpComponent(TestHarness(controller: harness, builder: child));
      final initial = token;
      final initialState = state;
      expect(initialState!.mounted, isTrue);

      keys = <Object?>[double.nan, 0.0];
      harness.rebuild();
      await tester.pump();
      expect(token, same(initial), reason: 'NaN keys compare as equal');

      keys = <Object?>[double.nan, -0.0];
      harness.rebuild();
      await tester.pump();
      expect(token, isNot(same(initial)), reason: 'signed zero replaces state');
      expect(initialState.mounted, isFalse);
      expect(state!.mounted, isTrue);

      final signedZeroToken = token;
      final sharedKeys = <Object?>[1];
      keys = sharedKeys;
      harness.rebuild();
      await tester.pump();
      final sharedToken = token;
      expect(sharedToken, isNot(same(signedZeroToken)));

      sharedKeys[0] = 2;
      harness.rebuild();
      await tester.pump();
      expect(
        token,
        same(sharedToken),
        reason: 'an identical key-list instance short-circuits comparison',
      );
    });

    testComponents('disposes trailing hooks and unmounts in reverse order', (
      tester,
    ) async {
      final harness = TestHarnessController();
      final events = <String>[];
      var hookCount = 3;

      Component child() => HookBuilder(
        builder: (context) {
          if (hookCount > 0) use(_ProbeHook('a', events));
          if (hookCount > 1) use(_ProbeHook('b', events));
          if (hookCount > 2) use(_ProbeHook('c', events));
          return const Component.empty();
        },
      );

      tester.pumpComponent(TestHarness(controller: harness, builder: child));
      events.clear();

      hookCount = 1;
      harness.rebuild();
      await tester.pump();
      expect(
        events.where((event) => event.startsWith('dispose:')),
        orderedEquals(<String>['dispose:c', 'dispose:b']),
      );

      events.clear();
      harness.unmountChild();
      await tester.pump();
      expect(events, contains('deactivate:a'));
      expect(events.last, 'dispose:a');
    });

    test('reports a changed hook type without corrupting the cursor', () async {
      final binding = CapturingTestComponentsBinding(isClient: true);
      addTearDown(binding.detachRootComponent);
      final harness = TestHarnessController();
      final events = <String>[];
      var useOtherType = false;

      Component child() => HookBuilder(
        builder: (context) {
          if (useOtherType) {
            use(_OtherProbeHook());
          } else {
            use(_ProbeHook('probe', events));
          }
          return const Component.empty();
        },
      );

      binding.attachRootComponent(
        TestHarness(controller: harness, builder: child),
      );
      useOtherType = true;
      harness.rebuild();
      await binding.pump();

      expect(binding.errors, hasLength(1));
      expect(binding.errors.single.error, isA<StateError>());
      expect(binding.errors.single.error.toString(), contains('Hook'));
      expect(() => use(_OtherProbeHook()), throwsA(isA<StateError>()));
    });

    test('clears the current hook element after a failed build', () async {
      final binding = CapturingTestComponentsBinding(isClient: true);
      addTearDown(binding.detachRootComponent);
      final harness = TestHarnessController();
      var fail = true;

      Component child() => HookBuilder(
        builder: (context) {
          useRef(1);
          if (fail) throw StateError('expected build failure');
          return const Component.text('recovered');
        },
      );

      binding.attachRootComponent(
        TestHarness(controller: harness, builder: child),
      );
      expect(binding.errors.single.error, isA<StateError>());
      expect(() => useRef(2), throwsA(isA<StateError>()));

      fail = false;
      harness.rebuild();
      await binding.pump();
      expect(binding.errors, hasLength(1));
    });

    test(
      'failed keyed replacement disposes old and partial new state once',
      () async {
        final binding = CapturingTestComponentsBinding(isClient: true);
        addTearDown(binding.detachRootComponent);
        final harness = TestHarnessController();
        final events = <String>[];
        var generation = 0;
        var failInitialization = false;

        Component child() => HookBuilder(
          builder: (context) {
            use(
              _FailingInitHook(
                generation,
                events,
                failInitialization: failInitialization,
              ),
            );
            return const Component.empty();
          },
        );

        binding.attachRootComponent(
          TestHarness(controller: harness, builder: child),
        );
        expect(events, <String>['init:0', 'build:0']);
        events.clear();

        generation = 1;
        failInitialization = true;
        harness.rebuild();
        await binding.pump();

        expect(
          events,
          <String>['init:1', 'dispose:1', 'dispose:0'],
          reason: 'partial new state and displaced old state are each owned once',
        );
        expect(
          events.where((event) => event == 'dispose:0'),
          hasLength(1),
        );
        expect(
          events.where((event) => event == 'dispose:1'),
          hasLength(1),
        );
        expect(binding.errors, hasLength(1));
        expect(binding.errors.single.error, isA<StateError>());
        expect(binding.reportingComponentTypes, <Type>[HookBuilder]);
      },
    );

    testComponents('optional rebuild can be rejected or accepted', (tester) async {
      final shouldRebuild = ValueNotifier<bool>(false);
      final events = <String>[];
      _ProbeHookState? state;
      var componentBuilds = 0;

      tester.pumpComponent(
        HookBuilder(
          builder: (context) {
            componentBuilds++;
            use(
              _ProbeHook(
                'optional',
                events,
                capture: (value) => state = value,
                optionalRebuild: () => shouldRebuild.value,
              ),
            );
            return Component.text('$componentBuilds');
          },
        ),
      );

      state!.requestOptionalRebuild();
      await tester.pump();
      expect(componentBuilds, 1);
      expect(events, contains('shouldRebuild:optional:false'));

      shouldRebuild.value = true;
      state!.requestOptionalRebuild();
      await tester.pump();
      expect(componentBuilds, 2);
      expect(events, contains('shouldRebuild:optional:true'));
    });

    testComponents('custom HookState.setState schedules a rebuild', (tester) async {
      _ProbeHookState? state;
      var builds = 0;
      tester.pumpComponent(
        HookBuilder(
          builder: (context) {
            builds++;
            use(
              _ProbeHook(
                'state',
                <String>[],
                capture: (value) => state = value,
              ),
            );
            return Component.text('$builds');
          },
        ),
      );

      state!.forceRebuild();
      await tester.pump();
      expect(builds, 2);
    });

    testComponents('forwards inherited dependency changes', (tester) async {
      final harness = TestHarnessController();
      final counter = _BuildCounter();
      final consumer = _InheritedConsumer(counter);
      var inheritedValue = 1;

      Component child() => _IntInherited(
        value: inheritedValue,
        child: consumer,
      );

      tester.pumpComponent(TestHarness(controller: harness, builder: child));
      expect(counter.builds, 1);
      expect(counter.lastValue, 1);

      inheritedValue = 2;
      harness.rebuild();
      await tester.pump();

      expect(counter.builds, 2);
      expect(counter.lastValue, 2);
    });
  });
}

final class _StatelessHookHost extends HookComponent {
  _StatelessHookHost({required this.onBuild});

  final void Function(ValueNotifier<int>) onBuild;

  @override
  Component build(BuildContext context) {
    final counter = useState(0);
    onBuild(counter);
    return Component.text('count:${counter.value}');
  }
}

final class _StatefulHookHost extends StatefulHookComponent {
  const _StatefulHookHost({required this.onBuild});

  final void Function(ValueNotifier<int>) onBuild;

  @override
  State<_StatefulHookHost> createState() => _StatefulHookHostState();
}

final class _StatefulHookHostState extends State<_StatefulHookHost> {
  @override
  Component build(BuildContext context) {
    final counter = useState(2);
    component.onBuild(counter);
    return Component.text('stateful:${counter.value}');
  }
}

final class _StatefulDisposalHost extends StatefulHookComponent {
  const _StatefulDisposalHost({required this.events});

  final List<String> events;

  @override
  State<_StatefulDisposalHost> createState() => _StatefulDisposalHostState();
}

final class _StatefulDisposalHostState extends State<_StatefulDisposalHost> {
  @override
  Component build(BuildContext context) {
    use(_ProbeHook('hook', component.events));
    return const Component.empty();
  }

  @override
  void dispose() {
    component.events.add('state.dispose');
    super.dispose();
  }
}

final class _StatefulEffectCleanupHost extends StatefulHookComponent {
  const _StatefulEffectCleanupHost({required this.events});

  final List<String> events;

  @override
  State<_StatefulEffectCleanupHost> createState() {
    return _StatefulEffectCleanupHostState();
  }
}

final class _StatefulEffectCleanupHostState extends State<_StatefulEffectCleanupHost> {
  @override
  Component build(BuildContext context) {
    useEffect(() {
      return () => component.events.add('cleanup:first');
    }, const <Object?>[]);
    useEffect(() {
      return () {
        component.events.add('cleanup:second');
        throw StateError('expected stateful cleanup failure');
      };
    }, const <Object?>[]);
    return const Component.empty();
  }

  @override
  void dispose() {
    component.events.add('state.dispose');
    super.dispose();
  }
}

final class _ProbeHook extends Hook<Object> {
  const _ProbeHook(
    this.name,
    this.events, {
    this.capture,
    this.optionalRebuild,
    super.keys,
  });

  final String name;
  final List<String> events;
  final void Function(_ProbeHookState)? capture;
  final bool Function()? optionalRebuild;

  @override
  _ProbeHookState createState() => _ProbeHookState();
}

final class _ProbeHookState extends HookState<Object, _ProbeHook> {
  final Object token = Object();

  @override
  void initHook() {
    hook.events.add('init:${hook.name}');
  }

  @override
  Object build(BuildContext context) {
    hook.events.add('build:${hook.name}');
    hook.capture?.call(this);
    return token;
  }

  @override
  void didUpdateHook(_ProbeHook oldHook) {
    hook.events.add('update:${oldHook.name}->${hook.name}');
  }

  @override
  bool shouldRebuild() {
    final result = hook.optionalRebuild?.call() ?? true;
    hook.events.add('shouldRebuild:${hook.name}:$result');
    return result;
  }

  void requestOptionalRebuild() => markMayNeedRebuild();

  void forceRebuild() => setState(() {});

  @override
  void deactivate() {
    hook.events.add('deactivate:${hook.name}');
  }

  @override
  void dispose() {
    hook.events.add('dispose:${hook.name}');
  }
}

final class _OtherProbeHook extends Hook<Object> {
  const _OtherProbeHook();

  @override
  _OtherProbeHookState createState() => _OtherProbeHookState();
}

final class _OtherProbeHookState extends HookState<Object, _OtherProbeHook> {
  @override
  Object build(BuildContext context) => Object();
}

final class _FailingInitHook extends Hook<void> {
  _FailingInitHook(
    this.generation,
    this.events, {
    required this.failInitialization,
  }) : super(keys: <Object?>[generation]);

  final int generation;
  final List<String> events;
  final bool failInitialization;

  @override
  _FailingInitHookState createState() => _FailingInitHookState();
}

final class _FailingInitHookState extends HookState<void, _FailingInitHook> {
  @override
  void initHook() {
    hook.events.add('init:${hook.generation}');
    if (hook.failInitialization) {
      throw StateError('expected initHook failure');
    }
  }

  @override
  void build(BuildContext context) {
    hook.events.add('build:${hook.generation}');
  }

  @override
  void dispose() {
    hook.events.add('dispose:${hook.generation}');
  }
}

final class _IntInherited extends InheritedComponent {
  const _IntInherited({required this.value, required super.child});

  final int value;

  @override
  bool updateShouldNotify(_IntInherited oldComponent) {
    return value != oldComponent.value;
  }
}

final class _BuildCounter {
  int builds = 0;
  int? lastValue;
}

final class _InheritedConsumer extends HookComponent {
  const _InheritedConsumer(this.counter);

  final _BuildCounter counter;

  @override
  Component build(BuildContext context) {
    final hookContext = useContext();
    final inherited = hookContext.dependOnInheritedComponentOfExactType<_IntInherited>();
    counter
      ..builds = counter.builds + 1
      ..lastValue = inherited?.value;
    return Component.text('inherited:${inherited?.value}');
  }
}
