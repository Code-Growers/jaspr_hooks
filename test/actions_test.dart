import 'dart:async';

import 'package:jaspr/jaspr.dart';
import 'package:jaspr_hooks/jaspr_hooks.dart';
import 'package:jaspr_test/jaspr_test.dart';

import 'support/harness.dart';

void main() {
  group('useAsyncAction', () {
    testComponents('captures an unread initial state at hook creation', (tester) async {
      final harness = TestHarnessController();
      var initialState = 1;
      AsyncAction<int, int>? controller;

      Component child() => HookBuilder(
        builder: (context) {
          controller = useAsyncAction<int, int>(
            initialState: initialState,
            action: (state, input) => state + input,
          );
          return const Component.empty();
        },
      );

      tester.pumpComponent(TestHarness(controller: harness, builder: child));
      initialState = 10;
      harness.rebuild();
      await tester.pump();

      expect(controller!.state, 1);
      expect(await controller!.dispatch(2), 3);
      await tester.pump();
      controller!.reset();
      expect(controller!.state, 1);
    });

    testComponents('runs sequential actions against the latest committed state', (
      tester,
    ) async {
      final completers = <int, Completer<int>>{};
      final calls = <String>[];
      AsyncAction<int, int>? controller;

      tester.pumpComponent(
        HookBuilder(
          builder: (context) {
            controller = useAsyncAction<int, int>(
              initialState: 10,
              action: (state, input) {
                calls.add('$state:$input');
                return (completers[input] = Completer<int>()).future;
              },
            );
            return Component.text(
              '${controller!.state}:${controller!.isPending}',
            );
          },
        ),
      );

      final first = controller!.dispatch(1);
      final second = controller!.dispatch(2);
      expect(calls, <String>['10:1']);
      expect(controller!.isPending, isTrue);

      completers[1]!.complete(11);
      expect(await first, 11);
      await tester.pump();
      expect(calls, <String>['10:1', '11:2']);
      expect(controller!.state, 11);
      expect(controller!.isPending, isTrue);

      completers[2]!.complete(13);
      expect(await second, 13);
      await tester.pump();
      expect(controller!.state, 13);
      expect(controller!.isPending, isFalse);
    });

    testComponents('latest applies only the newest result and error', (
      tester,
    ) async {
      final completers = <int, Completer<int>>{};
      AsyncAction<int, int>? controller;

      tester.pumpComponent(
        HookBuilder(
          builder: (context) {
            controller = useAsyncAction<int, int>(
              initialState: 0,
              concurrency: ActionConcurrency.latest,
              action: (state, input) => (completers[input] = Completer<int>()).future,
            );
            return const Component.empty();
          },
        ),
      );

      final first = controller!.dispatch(1);
      final second = controller!.dispatch(2);
      completers[1]!.complete(1);
      expect(await first, 1);
      await tester.pump();
      expect(controller!.state, 0);
      expect(controller!.isPending, isTrue);

      completers[2]!.completeError(StateError('latest failed'));
      await expectLater(second, throwsA(isA<StateError>()));
      await tester.pump();
      expect(controller!.state, 0);
      expect(controller!.isPending, isFalse);
      expect(controller!.error, isA<StateError>());
      expect(controller!.stackTrace, isNotNull);
    });

    testComponents('drop rejects overlaps and accepts a later dispatch', (
      tester,
    ) async {
      final completers = <Completer<int>>[];
      AsyncAction<int, int>? controller;

      tester.pumpComponent(
        HookBuilder(
          builder: (context) {
            controller = useAsyncAction<int, int>(
              initialState: 0,
              concurrency: ActionConcurrency.drop,
              action: (state, input) {
                final completer = Completer<int>();
                completers.add(completer);
                return completer.future;
              },
            );
            return const Component.empty();
          },
        ),
      );

      final first = controller!.dispatch(1);
      await expectLater(
        controller!.dispatch(2),
        throwsA(isA<ActionDroppedException>()),
      );
      expect(completers, hasLength(1));
      completers.single.complete(1);
      expect(await first, 1);
      await tester.pump();

      final third = controller!.dispatch(3);
      expect(completers, hasLength(2));
      completers.last.complete(4);
      expect(await third, 4);
      await tester.pump();
      expect(controller!.state, 4);
    });

    testComponents('concurrent applies results in completion order', (
      tester,
    ) async {
      final completers = <int, Completer<int>>{};
      final previousStates = <int>[];
      AsyncAction<int, int>? controller;

      tester.pumpComponent(
        HookBuilder(
          builder: (context) {
            controller = useAsyncAction<int, int>(
              initialState: 0,
              concurrency: ActionConcurrency.concurrent,
              action: (state, input) {
                previousStates.add(state);
                return (completers[input] = Completer<int>()).future;
              },
            );
            return const Component.empty();
          },
        ),
      );

      final first = controller!.dispatch(1);
      final second = controller!.dispatch(2);
      expect(previousStates, <int>[0, 0]);

      completers[2]!.complete(2);
      expect(await second, 2);
      await tester.pump();
      expect(controller!.state, 2);
      expect(controller!.isPending, isTrue);

      completers[1]!.complete(1);
      expect(await first, 1);
      await tester.pump();
      expect(controller!.state, 1);
      expect(controller!.isPending, isFalse);
    });

    testComponents('reset cancels queued work and suppresses running results', (
      tester,
    ) async {
      final completer = Completer<int>();
      AsyncAction<int, int>? controller;

      tester.pumpComponent(
        HookBuilder(
          builder: (context) {
            controller = useAsyncAction<int, int>(
              initialState: 5,
              action: (state, input) => completer.future,
            );
            return const Component.empty();
          },
        ),
      );

      final running = controller!.dispatch(1);
      final queued = controller!.dispatch(2);
      final queuedExpectation = expectLater(
        queued,
        throwsA(isA<ActionCancelledException>()),
      );
      controller!.reset();
      await queuedExpectation;
      expect(controller!.state, 5);
      expect(controller!.isPending, isFalse);

      completer.complete(99);
      expect(await running, 99);
      await tester.pump();
      expect(controller!.state, 5);
      expect(controller!.isPending, isFalse);
    });

    testComponents('uses the latest callback while preserving its controller', (
      tester,
    ) async {
      final harness = TestHarnessController();
      var multiplier = 2;
      AsyncAction<int, int>? controller;

      Component child() => HookBuilder(
        builder: (context) {
          controller = useAsyncAction<int, int>(
            initialState: 1,
            action: (state, input) async => state + input * multiplier,
          );
          return const Component.empty();
        },
      );

      tester.pumpComponent(TestHarness(controller: harness, builder: child));
      final original = controller;
      multiplier = 3;
      harness.rebuild();
      await tester.pump();
      expect(controller, same(original));
      await controller!.dispatch(2);
      await tester.pump();
      expect(controller!.state, 7);
    });

    testComponents(
      'is deterministic on the server and rejects mutations',
      (tester) async {
        AsyncAction<int, int>? controller;
        tester.pumpComponent(
          HookBuilder(
            builder: (context) {
              controller = useAsyncAction<int, int>(
                initialState: 4,
                action: (state, input) async => state + input,
              );
              return Component.text('${controller!.state}');
            },
          ),
        );

        expect(controller!.state, 4);
        expect(controller!.isPending, isFalse);
        expect(() => controller!.dispatch(1), throwsA(isA<StateError>()));
        expect(controller!.reset, throwsA(isA<StateError>()));
      },
      isClient: false,
    );
  });

  group('useOptimistic', () {
    testComponents('commits and rolls back independently', (tester) async {
      OptimisticState<int, int>? optimistic;

      tester.pumpComponent(
        HookBuilder(
          builder: (context) {
            optimistic = useOptimistic<int, int>(10, (state, update) {
              return state + update;
            });
            return Component.text('${optimistic!.value}');
          },
        ),
      );

      final first = optimistic!.add(1);
      final second = optimistic!.add(2);
      await tester.pump();
      expect(optimistic!.value, 13);
      expect(optimistic!.pendingCount, 2);

      first.commit(11);
      await tester.pump();
      expect(optimistic!.value, 13);
      expect(first.isPending, isFalse);
      expect(second.isPending, isTrue);

      second.rollback();
      await tester.pump();
      expect(optimistic!.value, 11);
      expect(optimistic!.hasPendingUpdates, isFalse);
    });

    testComponents('rebases pending updates over authoritative changes', (
      tester,
    ) async {
      final harness = TestHarnessController();
      var authoritative = 10;
      OptimisticState<int, int>? optimistic;

      Component child() => HookBuilder(
        builder: (context) {
          optimistic = useOptimistic<int, int>(
            authoritative,
            (state, update) => state + update,
          );
          return const Component.empty();
        },
      );

      tester.pumpComponent(TestHarness(controller: harness, builder: child));
      optimistic!.add(3);
      await tester.pump();
      expect(optimistic!.value, 13);

      authoritative = 20;
      harness.rebuild();
      await tester.pump();
      expect(optimistic!.value, 23);
    });

    testComponents('distinguishes signed-zero authoritative inputs', (tester) async {
      final harness = TestHarnessController();
      var authoritative = 0.0;
      OptimisticState<double, double>? optimistic;

      Component child() => HookBuilder(
        builder: (context) {
          optimistic = useOptimistic<double, double>(
            authoritative,
            (state, update) => state + update,
          );
          return const Component.empty();
        },
      );

      tester.pumpComponent(TestHarness(controller: harness, builder: child));
      expect(optimistic!.value.isNegative, isFalse);

      authoritative = -0.0;
      harness.rebuild();
      await tester.pump();
      expect(optimistic!.value.isNegative, isTrue);
    });

    testComponents('run commits success and rolls back failure', (
      tester,
    ) async {
      OptimisticState<List<String>, String>? optimistic;

      tester.pumpComponent(
        HookBuilder(
          builder: (context) {
            optimistic = useOptimistic<List<String>, String>(
              const <String>[],
              (state, update) => <String>[...state, update],
            );
            return const Component.empty();
          },
        ),
      );

      final success = Completer<List<String>>();
      final successFuture = optimistic!.run<List<String>>(
        'pending',
        () => success.future,
        authoritativeState: (result) => result,
      );
      expect(optimistic!.value, <String>['pending']);
      success.complete(<String>['saved']);
      expect(await successFuture, <String>['saved']);
      await tester.pump();
      expect(optimistic!.value, <String>['saved']);

      final failure = Completer<List<String>>();
      final failureFuture = optimistic!.run<List<String>>(
        'failing',
        () => failure.future,
        authoritativeState: (result) => result,
      );
      expect(optimistic!.value, <String>['saved', 'failing']);
      failure.completeError(StateError('save failed'));
      await expectLater(failureFuture, throwsA(isA<StateError>()));
      await tester.pump();
      expect(optimistic!.value, <String>['saved']);
    });

    testComponents('run tolerates mapper invalidation of its update', (tester) async {
      OptimisticState<int, int>? optimistic;

      tester.pumpComponent(
        HookBuilder(
          builder: (context) {
            optimistic = useOptimistic<int, int>(1, (state, update) => state + update);
            return const Component.empty();
          },
        ),
      );

      final result = await optimistic!.run<int>(
        2,
        () async => 5,
        authoritativeState: (value) {
          optimistic!.reset();
          return value;
        },
      );
      await tester.pump();

      expect(result, 5);
      expect(optimistic!.value, 1);
      expect(optimistic!.hasPendingUpdates, isFalse);
    });

    testComponents('reset invalidates handles', (tester) async {
      OptimisticState<int, int>? optimistic;

      tester.pumpComponent(
        HookBuilder(
          builder: (context) {
            optimistic = useOptimistic<int, int>(1, (state, update) {
              return state + update;
            });
            return const Component.empty();
          },
        ),
      );

      final handle = optimistic!.add(2);
      optimistic!.reset();
      await tester.pump();
      expect(optimistic!.value, 1);
      expect(handle.isPending, isFalse);
      expect(() => handle.commit(3), throwsA(isA<StateError>()));
    });

    testComponents(
      'renders authoritative state on the server and rejects updates',
      (tester) async {
        OptimisticState<int, int>? optimistic;
        tester.pumpComponent(
          HookBuilder(
            builder: (context) {
              optimistic = useOptimistic<int, int>(8, (state, update) {
                return state + update;
              });
              return Component.text('${optimistic!.value}');
            },
          ),
        );

        expect(optimistic!.value, 8);
        expect(() => optimistic!.add(1), throwsA(isA<StateError>()));
      },
      isClient: false,
    );
  });
}
