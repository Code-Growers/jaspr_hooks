import 'dart:async';

import 'package:jaspr/jaspr.dart';
import 'package:jaspr_hooks/jaspr_hooks.dart';
import 'package:jaspr_test/jaspr_test.dart';

import 'support/harness.dart';

void main() {
  group('useFuture', () {
    testComponents('reports waiting, data, and errors', (tester) async {
      final harness = TestHarnessController();
      var completer = Completer<int>();
      Future<int>? future = completer.future;
      AsyncSnapshot<int>? snapshot;

      Component child() => HookBuilder(
        builder: (context) {
          snapshot = useFuture(future, initialData: -1);
          return Component.text(
            '${snapshot!.connectionState}:${snapshot!.data}:${snapshot!.error}',
          );
        },
      );

      tester.pumpComponent(TestHarness(controller: harness, builder: child));
      expect(snapshot!.connectionState, ConnectionState.waiting);
      expect(snapshot!.data, -1);

      completer.complete(42);
      await tester.pump();
      expect(snapshot!.connectionState, ConnectionState.done);
      expect(snapshot!.data, 42);
      expect(snapshot!.hasError, isFalse);

      completer = Completer<int>();
      future = completer.future;
      harness.rebuild();
      await tester.pump();
      completer.completeError(StateError('future failed'));
      await tester.pump();
      expect(snapshot!.connectionState, ConnectionState.done);
      expect(snapshot!.error, isA<StateError>());
      expect(snapshot!.stackTrace, isNotNull);
    });

    testComponents('ignores callbacks from a replaced future', (tester) async {
      final harness = TestHarnessController();
      final first = Completer<int>();
      final second = Completer<int>();
      Future<int>? current = first.future;
      AsyncSnapshot<int>? snapshot;

      Component child() => HookBuilder(
        builder: (context) {
          snapshot = useFuture(current);
          return const Component.empty();
        },
      );

      tester.pumpComponent(TestHarness(controller: harness, builder: child));
      current = second.future;
      harness.rebuild();
      await tester.pump();

      first.complete(1);
      await tester.pump();
      expect(snapshot!.connectionState, ConnectionState.waiting);
      expect(snapshot!.data, isNull);

      second.complete(2);
      await tester.pump();
      expect(snapshot!.connectionState, ConnectionState.done);
      expect(snapshot!.data, 2);
    });

    testComponents('preserveState controls data while changing futures', (
      tester,
    ) async {
      final harness = TestHarnessController();
      var completer = Completer<int>();
      Future<int>? current = completer.future;
      var preserveState = true;
      AsyncSnapshot<int>? snapshot;

      Component child() => HookBuilder(
        builder: (context) {
          snapshot = useFuture(
            current,
            initialData: -1,
            preserveState: preserveState,
          );
          return const Component.empty();
        },
      );

      tester.pumpComponent(TestHarness(controller: harness, builder: child));
      completer.complete(7);
      await tester.pump();

      completer = Completer<int>();
      current = completer.future;
      harness.rebuild();
      await tester.pump();
      expect(snapshot!.connectionState, ConnectionState.waiting);
      expect(snapshot!.data, 7);

      preserveState = false;
      completer = Completer<int>();
      current = completer.future;
      harness.rebuild();
      await tester.pump();
      expect(snapshot!.connectionState, ConnectionState.waiting);
      expect(snapshot!.data, -1);
    });
  });

  group('useStream', () {
    testComponents('reports active data, errors, and done', (tester) async {
      final controller = StreamController<int>();
      addTearDown(controller.close);
      AsyncSnapshot<int>? snapshot;

      tester.pumpComponent(
        HookBuilder(
          builder: (context) {
            snapshot = useStream(controller.stream, initialData: -1);
            return Component.text('${snapshot!.connectionState}');
          },
        ),
      );

      expect(snapshot!.connectionState, ConnectionState.waiting);
      expect(snapshot!.data, -1);

      controller.add(1);
      await tester.pump();
      expect(snapshot!.connectionState, ConnectionState.active);
      expect(snapshot!.data, 1);

      controller.addError(StateError('stream failed'), StackTrace.current);
      await tester.pump();
      expect(snapshot!.connectionState, ConnectionState.active);
      expect(snapshot!.error, isA<StateError>());

      await controller.close();
      await tester.pump();
      expect(snapshot!.connectionState, ConnectionState.done);
      expect(snapshot!.hasError, isTrue);
    });

    testComponents('switches streams, cancels old, and preserves state', (
      tester,
    ) async {
      final harness = TestHarnessController();
      var firstCancels = 0;
      final first = StreamController<int>(onCancel: () => firstCancels++);
      final second = StreamController<int>();
      addTearDown(first.close);
      addTearDown(second.close);
      Stream<int>? current = first.stream;
      AsyncSnapshot<int>? snapshot;

      Component child() => HookBuilder(
        builder: (context) {
          snapshot = useStream(current);
          return const Component.empty();
        },
      );

      tester.pumpComponent(TestHarness(controller: harness, builder: child));
      first.add(3);
      await tester.pump();
      expect(snapshot!.data, 3);

      current = second.stream;
      harness.rebuild();
      await tester.pump();
      expect(firstCancels, 1);
      expect(snapshot!.connectionState, ConnectionState.waiting);
      expect(snapshot!.data, 3);

      first.add(4);
      second.add(5);
      await tester.pump();
      expect(snapshot!.data, 5);
    });
  });

  group('useStreamController', () {
    testComponents('creates a broadcast controller and closes on unmount', (
      tester,
    ) async {
      final harness = TestHarnessController();
      StreamController<int>? controller;
      var listens = 0;
      var cancels = 0;

      Component child() => HookBuilder(
        builder: (context) {
          controller = useStreamController<int>(
            sync: true,
            onListen: () => listens++,
            onCancel: () => cancels++,
          );
          return const Component.empty();
        },
      );

      tester.pumpComponent(TestHarness(controller: harness, builder: child));
      final valuesA = <int>[];
      final valuesB = <int>[];
      final subscriptionA = controller!.stream.listen(valuesA.add);
      final subscriptionB = controller!.stream.listen(valuesB.add);
      controller!.add(1);

      expect(controller!.stream.isBroadcast, isTrue);
      expect(valuesA, <int>[1]);
      expect(valuesB, <int>[1]);
      expect(listens, 1);

      await subscriptionA.cancel();
      await subscriptionB.cancel();
      expect(cancels, 1);

      final done = controller!.done;
      harness.unmountChild();
      await tester.pump();
      await done;
      expect(controller!.isClosed, isTrue);
    });

    testComponents('updates onListen and onCancel without replacement', (
      tester,
    ) async {
      final harness = TestHarnessController();
      StreamController<int>? controller;
      var version = 'first';
      final calls = <String>[];

      Component child() => HookBuilder(
        builder: (context) {
          final callbackVersion = version;
          controller = useStreamController<int>(
            onListen: () => calls.add('listen:$callbackVersion'),
            onCancel: () => calls.add('cancel:$callbackVersion'),
          );
          return const Component.empty();
        },
      );

      tester.pumpComponent(TestHarness(controller: harness, builder: child));
      final original = controller;
      version = 'second';
      harness.rebuild();
      await tester.pump();
      expect(controller, same(original));

      final subscription = controller!.stream.listen((_) {});
      await subscription.cancel();
      expect(calls, <String>['listen:second', 'cancel:second']);
    });
  });

  group('useOnStreamChange', () {
    testComponents('uses current callbacks without resubscribing', (tester) async {
      final harness = TestHarnessController();
      final controller = StreamController<int>.broadcast(sync: true);
      addTearDown(controller.close);
      final calls = <String>[];
      var version = 'first';
      StreamSubscription<int>? subscription;

      Component child() => HookBuilder(
        builder: (context) {
          final callbackVersion = version;
          subscription = useOnStreamChange(
            controller.stream,
            onData: (value) => calls.add('$callbackVersion:$value'),
          );
          return const Component.empty();
        },
      );

      tester.pumpComponent(TestHarness(controller: harness, builder: child));
      final original = subscription;
      controller.add(1);
      expect(calls, <String>['first:1']);

      version = 'second';
      harness.rebuild();
      await tester.pump();
      expect(subscription, same(original));
      controller.add(2);
      expect(calls, <String>['first:1', 'second:2']);
    });

    testComponents('forwards errors/done and cancels on unmount', (tester) async {
      final harness = TestHarnessController();
      var cancels = 0;
      final controller = StreamController<int>(onCancel: () => cancels++);
      final events = <String>[];

      Component child() => HookBuilder(
        builder: (context) {
          useOnStreamChange(
            controller.stream,
            onError: (error, stackTrace) => events.add('error:$error'),
            onDone: () => events.add('done'),
          );
          return const Component.empty();
        },
      );

      tester.pumpComponent(TestHarness(controller: harness, builder: child));
      controller.addError('bad', StackTrace.current);
      await tester.pump();
      expect(events.single, 'error:bad');

      harness.unmountChild();
      await tester.pump();
      expect(cancels, 1);
      await controller.close();
    });
  });
}
