import 'package:jaspr/jaspr.dart';
import 'package:jaspr_hooks/jaspr_hooks.dart';
import 'package:jaspr_test/jaspr_test.dart';

import 'support/capturing_binding.dart';
import 'support/harness.dart';

void main() {
  test('hot reload preserves state, refs and IDs while refreshing caches and callbacks', () async {
    final binding = CapturingTestComponentsBinding(isClient: true);
    addTearDown(binding.detachRootComponent);
    var version = 1;
    late ValueNotifier<int> count;
    late ObjectRef<int> reference;
    late int memo;
    late int Function() callback;
    late String id;
    var nullableBuilds = 0;
    binding.attachRootComponent(
      HookIdScope(
        seed: 'reload',
        child: HookBuilder(
          builder: (_) {
            count = useState(0);
            reference = useRef(10);
            id = useId();
            final captured = version;
            memo = useMemoized(() => captured);
            callback = useCallback(() => captured);
            useMemoized<Object?>(() {
              nullableBuilds++;
              return null;
            });
            return const Component.empty();
          },
        ),
      ),
    );
    final originalCount = count;
    final originalReference = reference;
    final originalCallback = callback;
    final originalId = id;
    count.value = 7;
    reference.value = 42;
    version = 2;
    await binding.pump();
    expect(memo, 1);
    expect(callback(), 1);
    expect(nullableBuilds, 1);

    binding.reassembleHooks();
    await binding.pump();
    expect(count, same(originalCount));
    expect(count.value, 7);
    expect(reference, same(originalReference));
    expect(reference.value, 42);
    expect(id, originalId);
    expect(memo, 2);
    expect(callback(), 2);
    expect(callback, isNot(same(originalCallback)));
    expect(nullableBuilds, 2);
    expect(binding.errors, isEmpty);
  });

  test('hot reload cleans effects once and keeps the latest resource disposer', () async {
    final binding = CapturingTestComponentsBinding(isClient: true);
    addTearDown(binding.detachRootComponent);
    final events = <String>[];
    var version = 1;
    binding.attachRootComponent(
      HookBuilder(
        builder: (_) {
          final captured = version;
          useEffect(() {
            events.add('effect:$captured');
            return () => events.add('cleanup:$captured');
          }, const []);
          usePostFrameEffect(() {
            events.add('post:$captured');
            return () => events.add('post-cleanup:$captured');
          }, const []);
          useDisposable(() {
            events.add('resource:$captured');
            return captured;
          }, (resource) => events.add('dispose:$resource:$captured'));
          return const Component.empty();
        },
      ),
    );
    expect(events, ['effect:1', 'resource:1', 'post:1']);
    version = 2;
    binding.reassembleHooks();
    await binding.pump();
    expect(events, [
      'effect:1',
      'resource:1',
      'post:1',
      'cleanup:1',
      'effect:2',
      'dispose:1:1',
      'resource:2',
      'post-cleanup:1',
      'post:2',
    ]);
    binding.detachRootComponent();
    expect(events.sublist(events.length - 3), ['dispose:2:2', 'post-cleanup:2', 'cleanup:2']);
    expect(binding.errors, isEmpty);
  });

  test('hot reload invalidates queued post-frame effects before the first frame', () async {
    final binding = CapturingTestComponentsBinding(isClient: true, deferInitialPostFrameCallbacks: true);
    addTearDown(binding.detachRootComponent);
    final events = <int>[];
    var version = 1;
    binding.attachRootComponent(
      HookBuilder(
        builder: (_) {
          final captured = version;
          usePostFrameEffect(() {
            events.add(captured);
            return null;
          }, const []);
          return const Component.empty();
        },
      ),
    );
    version = 2;
    binding.reassembleHooks();
    await binding.pump();
    expect(events, [2]);
  });

  test('unmount after reassembly cleans the old resource without recreating it', () {
    final binding = CapturingTestComponentsBinding(isClient: true);
    final events = <String>[];
    binding.attachRootComponent(
      HookBuilder(
        builder: (_) {
          useDisposable(() {
            events.add('create');
            return 1;
          }, (_) => events.add('dispose'));
          return const Component.empty();
        },
      ),
    );
    binding.reassembleHooks();
    binding.detachRootComponent();
    expect(events, ['create', 'dispose']);
  });

  test('hot reload resets a mismatched suffix and preserves earlier state', () async {
    final binding = CapturingTestComponentsBinding(isClient: true);
    addTearDown(binding.detachRootComponent);
    final events = <String>[];
    var changed = false;
    late ValueNotifier<int> count;
    binding.attachRootComponent(
      HookBuilder(
        builder: (_) {
          count = useState(0);
          if (changed) {
            useRef(1);
          } else {
            useEffect(
              () =>
                  () => events.add('cleanup'),
              const [],
            );
          }
          return const Component.empty();
        },
      ),
    );
    count.value = 9;
    await binding.pump();
    changed = true;
    binding.reassembleHooks();
    await binding.pump();
    expect(count.value, 9);
    expect(events, ['cleanup']);
    expect(binding.errors, isEmpty);
  });

  test('server reassembly refreshes caches without starting browser effects', () async {
    final binding = CapturingTestComponentsBinding(isClient: false);
    addTearDown(binding.detachRootComponent);
    var version = 1;
    int? memo;
    binding.attachRootComponent(
      HookBuilder(
        builder: (_) {
          memo = useMemoized(() => version);
          useEffect(() => throw StateError('server effect'), const []);
          usePostFrameEffect(() => throw StateError('server post-frame effect'), const []);
          return const Component.empty();
        },
      ),
    );
    await binding.pump();
    version = 2;
    binding.reassembleHooks();
    await binding.pump();
    expect(memo, 2);
    expect(binding.errors, isEmpty);
  });

  test('reassembly reports callback and resource cleanup failures and continues', () async {
    final binding = CapturingTestComponentsBinding(isClient: true);
    addTearDown(binding.detachRootComponent);
    final events = <String>[];
    binding.attachRootComponent(
      HookBuilder(
        builder: (_) {
          use(const _ThrowingReassembleHook());
          useDisposable(
            () {
              events.add('create');
              return 0;
            },
            (_) {
              throw StateError('cleanup');
            },
          );
          useEffect(() {
            events.add('effect');
            return null;
          }, const []);
          return const Component.empty();
        },
      ),
    );
    binding.reassembleHooks();
    await binding.pump();
    expect(events, ['create', 'effect', 'create', 'effect']);
    expect(binding.errors, hasLength(2));
  });

  test('onReload bypasses optional rebuild caches without resetting client state', () async {
    final binding = CapturingTestComponentsBinding(isClient: true);
    addTearDown(binding.detachRootComponent);
    late _OptionalRebuildState optional;
    late Element owner;
    var builds = 0;
    var version = 1;
    var reload = false;
    int? rendered;
    final harness = TestHarnessController();
    final child = HookBuilder(
      builder: (context) {
        owner = context as Element;
        use(_OptionalRebuildHook((state) => optional = state));
        rendered = version;
        builds++;
        return const Component.empty();
      },
    );
    binding.attachRootComponent(
      TestHarness(
        controller: harness,
        builder: () {
          if (reload) owner.onReload();
          return child;
        },
      ),
    );
    version = 2;
    optional.markMayNeedRebuild();
    reload = true;
    harness.rebuild();
    await binding.pump();
    expect(builds, 2);
    expect(rendered, 2);
  });
}

class _ThrowingReassembleHook extends Hook<void> {
  const _ThrowingReassembleHook();

  @override
  HookState<void, _ThrowingReassembleHook> createState() => _ThrowingReassembleState();
}

class _ThrowingReassembleState extends HookState<void, _ThrowingReassembleHook> {
  @override
  void reassemble() => throw StateError('reassemble');

  @override
  void build(BuildContext context) {}
}

class _OptionalRebuildHook extends Hook<void> {
  const _OptionalRebuildHook(this.capture);
  final void Function(_OptionalRebuildState) capture;
  @override
  HookState<void, _OptionalRebuildHook> createState() => _OptionalRebuildState();
}

class _OptionalRebuildState extends HookState<void, _OptionalRebuildHook> {
  @override
  bool shouldRebuild() => false;
  @override
  void build(BuildContext context) => hook.capture(this);
}
