import 'dart:async';

import 'package:jaspr/server.dart';
import 'package:jaspr_hooks/server.dart';
import 'package:jaspr_test/server_test.dart';

import 'support/capturing_binding.dart';
import 'support/pending_child.dart';

void main() {
  testServer('AsyncHookComponent keeps context and hooks across sequential awaits', (tester) async {
    tester.pumpComponent(const HookIdScope(seed: 'async-profile', child: _AsyncProfile()));
    final response = await tester.request('/profile');
    expect(response.statusCode, 200);
    expect(response.body, contains('before:42:after:/profile:true'));
    expect(response.body, contains('id="profile-'));
  });

  testServer('AsyncHookBuilder isolates interleaved siblings and nested sync/async hosts', (tester) async {
    final first = Completer<void>();
    final second = Completer<void>();
    final contexts = <String, BuildContext>{};
    Component sibling(String name, Future<void> gate) => AsyncHookBuilder(
      builder: (context) async {
        contexts[name] = useContext();
        final reference = useRef(name);
        await gate;
        expect(useContext(), same(context));
        final label = useMemoized(() => '${reference.value}:done');
        return HookBuilder(
          builder: (syncContext) {
            contexts['$name:sync'] = useContext();
            expect(useContext(), same(syncContext));
            return AsyncHookBuilder(
              builder: (nestedContext) async {
                await Future<void>.value();
                contexts['$name:nested'] = useContext();
                expect(useContext(), same(nestedContext));
                return Component.text('$label:${useRef('nested').value}');
              },
            );
          },
        );
      },
    );
    tester.pumpComponent(Component.fragment([sibling('first', first.future), sibling('second', second.future)]));
    final request = tester.request('/');
    await pumpEventQueue();
    expect(contexts.keys, containsAll(['first', 'second']));
    second.complete();
    await pumpEventQueue();
    first.complete();
    final response = await request;
    expect(response.statusCode, 200);
    expect(response.body, contains('first:done:nested'));
    expect(response.body, contains('second:done:nested'));
    expect(contexts.values.toSet(), hasLength(6));
  });

  testServer('overlapping requests preserve their owner before and after each await', (tester) async {
    final gates = <String, Completer<void>>{};
    tester.pumpComponent(
      AsyncHookBuilder(
        builder: (context) async {
          final path = useContext().binding.currentUrl;
          final reference = useRef(path);
          await (gates['$path:1'] = Completer<void>()).future;
          expect(useContext(), same(context));
          final middle = useMemoized(() => useContext().binding.currentUrl);
          await (gates['$path:2'] = Completer<void>()).future;
          final end = useRef(useContext().binding.currentUrl);
          return Component.text('${reference.value}:$middle:${end.value}');
        },
      ),
    );
    final first = tester.request('/first');
    final second = tester.request('/second');
    await pumpEventQueue();
    gates['/second:1']!.complete();
    await pumpEventQueue();
    gates['/first:1']!.complete();
    await pumpEventQueue();
    gates['/second:2']!.complete();
    final secondResponse = await second;
    gates['/first:2']!.complete();
    final firstResponse = await first;
    expect(firstResponse.body, contains('/first:/first:/first'));
    expect(secondResponse.body, contains('/second:/second:/second'));
  });

  test('effects stay inactive, live sources reject, and async state is read-only', () async {
    final binding = CapturingTestComponentsBinding(isClient: false);
    addTearDown(binding.detachRootComponent);
    final errors = <Object>[];
    binding.attachRootComponent(
      AsyncHookBuilder(
        builder: (_) async {
          useEffect(() => throw StateError('server effect'));
          await Future<void>.value();
          usePostFrameEffect(() => throw StateError('server post-frame effect'));
          final state = useState(1);
          final guarded = useGuardedState(2);
          final counter = useCounter(3);
          for (final operation in <void Function()>[
            () => state.value = 9,
            () => guarded.value = 9,
            counter.increment,
          ]) {
            try {
              operation();
            } catch (error) {
              errors.add(error);
            }
          }
          expect(state.value, 1);
          expect(guarded.value, 2);
          expect(counter.value, 3);
          useFuture<int>(null, initialData: 4);
          useStream<int>(null, initialData: 5);
          return const Component.empty();
        },
      ),
    );
    await binding.pump();
    expect(errors, hasLength(3));
    expect(errors, everyElement(isA<StateError>()));
    expect(binding.errors, isEmpty);

    final invalid = CapturingTestComponentsBinding(isClient: false);
    addTearDown(invalid.detachRootComponent);
    invalid.attachRootComponent(
      AsyncHookBuilder(
        builder: (_) async {
          await Future<void>.value();
          useFuture(Future<int>.value(1));
          return const Component.empty();
        },
      ),
    );
    await invalid.pump();
    expect(invalid.errors.single.error, isA<StateError>());
    expect(invalid.errors.single.error.toString(), contains('non-null Future'));
  });

  test('closed sessions reject late callbacks even while the element remains mounted', () async {
    final binding = CapturingTestComponentsBinding(isClient: false);
    addTearDown(binding.detachRootComponent);
    final gate = Completer<void>();
    late Future<Object> escaped;
    binding.attachRootComponent(
      AsyncHookBuilder(
        builder: (_) async {
          useRef(0);
          escaped = gate.future.then((_) {
            try {
              useContext();
              return 'unexpected hook access';
            } catch (error) {
              return error;
            }
          });
          await Future<void>.value();
          return const Component.empty();
        },
      ),
    );
    await binding.pump();
    gate.complete();
    final error = await escaped;
    expect(error, isA<StateError>());
    expect(error.toString(), contains('completed or been unmounted'));
    expect(binding.errors, isEmpty);
  });

  test('failures after await dispose all hook resources once in reverse order', () async {
    final binding = CapturingTestComponentsBinding(isClient: false);
    addTearDown(binding.detachRootComponent);
    final events = <String>[];
    binding.attachRootComponent(
      AsyncHookBuilder(
        builder: (_) async {
          useDisposable(() => 1, (_) => events.add('first'));
          await Future<void>.value();
          useDisposable(() => 2, (_) {
            events.add('second');
            throw StateError('cleanup failed');
          });
          throw StateError('build failed');
        },
      ),
    );
    await binding.pump();
    expect(events, ['second', 'first']);
    expect(binding.errors.map((error) => error.error.toString()), [
      contains('cleanup failed'),
      contains('build failed'),
    ]);
    binding.detachRootComponent();
    expect(events, ['second', 'first']);
  });

  test('unmount during suspension cancels the build and ignores late results/errors', () async {
    final binding = CapturingTestComponentsBinding(isClient: false);
    addTearDown(binding.detachRootComponent);
    final pending = PendingChildController();
    final gate = Completer<void>();
    var disposed = 0;
    var lateChildBuilt = false;
    Object? lateError;
    binding.attachRootComponent(
      PendingChild(
        controller: pending,
        child: AsyncHookBuilder(
          builder: (_) async {
            useDisposable(Object.new, (_) => disposed++);
            await gate.future;
            try {
              useRef('too late');
            } catch (error) {
              lateError = error;
            }
            return HookBuilder(
              builder: (_) {
                lateChildBuilt = true;
                return const Component.empty();
              },
            );
          },
        ),
      ),
    );
    await pumpEventQueue();
    pending.unmount();
    await binding.pump();
    expect(disposed, 1);
    gate.complete();
    await binding.pump();
    expect(lateError, isA<StateError>());
    expect(lateChildBuilt, isFalse);
    expect(disposed, 1);
    expect(binding.errors, isEmpty);
  });

  test('same-owner rebuilds are serialized and only the newest configuration renders', () async {
    final binding = CapturingTestComponentsBinding(isClient: false);
    addTearDown(binding.detachRootComponent);
    final gate = Completer<void>();
    final rendered = <String>[];
    final events = <String>[];
    late Element element;
    binding.attachRootComponent(
      AsyncHookBuilder(
        builder: (context) async {
          element = context as Element;
          useRef('first');
          events.add('first');
          await gate.future;
          return HookBuilder(
            builder: (_) {
              rendered.add('first');
              return const Component.empty();
            },
          );
        },
      ),
    );
    await pumpEventQueue();
    element.update(
      AsyncHookBuilder(
        builder: (_) async {
          useRef('second');
          events.add('second');
          await Future<void>.value();
          return HookBuilder(
            builder: (_) {
              rendered.add('second');
              return const Component.empty();
            },
          );
        },
      ),
    );
    final updated = Future<void>.sync(element.performRebuild);
    expect(events, ['first']);
    gate.complete();
    await updated;
    await binding.pump();
    expect(events, ['first', 'second']);
    expect(rendered, ['second']);
    expect(binding.errors, isEmpty);
  });

  test('a synchronous builder failure closes the session and disposes initialized hooks', () async {
    final binding = CapturingTestComponentsBinding(isClient: false);
    addTearDown(binding.detachRootComponent);
    var disposed = 0;
    binding.attachRootComponent(
      AsyncHookBuilder(
        builder: (_) {
          useDisposable(Object.new, (_) => disposed++);
          throw StateError('synchronous builder failure');
        },
      ),
    );
    await binding.pump();
    expect(disposed, 1);
    expect(binding.errors.single.error.toString(), contains('synchronous builder failure'));
  });

  testServer('ordinary async descendants do not inherit their parent hook session', (tester) async {
    tester.pumpComponent(
      AsyncHookBuilder(
        builder: (_) async {
          useRef('parent');
          await Future<void>.value();
          return AsyncBuilder(
            builder: (_) async {
              expect(() => useRef('not a hook host'), throwsStateError);
              await Future<void>.value();
              expect(useContext, throwsStateError);
              return const Component.empty();
            },
          );
        },
      ),
    );
    final response = await tester.request('/');
    expect(response.statusCode, 200);
  });
}

class _AsyncProfile extends AsyncHookComponent {
  const _AsyncProfile();

  @override
  Future<Component> build(BuildContext context) async {
    final before = useRef('before');
    await Future<void>.value();
    final data = useMemoized(() => 42);
    await Future<void>.value();
    final after = useRef('after');
    final id = useId(prefix: 'profile');
    return Component.element(
      tag: 'p',
      id: id,
      children: [
        Component.text(
          '${before.value}:$data:${after.value}:${useContext().binding.currentUrl}:${identical(context, useContext())}',
        ),
      ],
    );
  }
}
