import 'package:jaspr/jaspr.dart';
import 'package:jaspr_hooks/jaspr_hooks.dart';
import 'package:jaspr_test/jaspr_test.dart';

import 'support/capturing_binding.dart';
import 'support/harness.dart';

void main() {
  group('scalar controllers', () {
    testComponents('initial arguments are captured before an unread controller rebuilds', (tester) async {
      final harness = TestHarnessController();
      ToggleController? toggle;
      ListController<int>? list;
      var toggleInitial = true;
      var listInitial = <int>[1];

      Component child() => HookBuilder(
        builder: (context) {
          toggle = useToggle(toggleInitial);
          list = useList<int>(listInitial);
          return const Component.empty();
        },
      );

      tester.pumpComponent(TestHarness(controller: harness, builder: child));
      toggleInitial = false;
      listInitial = <int>[2];
      harness.rebuild();
      await tester.pump();

      expect(toggle!.value, isTrue);
      expect(list!.value, <int>[1]);
    });

    testComponents('useToggle preserves identity and skips equal assignments', (tester) async {
      final harness = TestHarnessController();
      ToggleController? controller;
      var initialValue = true;
      var builds = 0;

      Component child() => HookBuilder(
        builder: (context) {
          builds++;
          controller = useToggle(initialValue);
          return Component.text('${controller!.value}');
        },
      );

      tester.pumpComponent(TestHarness(controller: harness, builder: child));
      final original = controller;

      controller!.setValue(true);
      await tester.pump();
      expect(builds, 1);

      controller!.toggle();
      await tester.pump();
      expect(controller!.value, isFalse);
      expect(builds, 2);

      initialValue = false;
      harness.rebuild();
      await tester.pump();
      expect(controller, same(original));

      controller!.reset();
      await tester.pump();
      expect(controller!.value, isTrue, reason: 'reset uses the initial mount value');

      harness.unmountChild();
      await tester.pump();
      expect(controller!.toggle, throwsStateError);
    });

    testComponents('useCounter preserves identity and skips no-op mutations', (tester) async {
      final harness = TestHarnessController();
      CounterController? controller;
      var initialValue = 2;
      var builds = 0;

      Component child() => HookBuilder(
        builder: (context) {
          builds++;
          controller = useCounter(initialValue);
          return Component.text('${controller!.value}');
        },
      );

      tester.pumpComponent(TestHarness(controller: harness, builder: child));
      final original = controller;

      controller!.increment(0);
      controller!.decrement(0);
      controller!.setValue(2);
      await tester.pump();
      expect(builds, 1);

      controller!.increment(3);
      await tester.pump();
      expect(controller!.value, 5);

      controller!.decrement(2);
      await tester.pump();
      expect(controller!.value, 3);

      initialValue = 20;
      harness.rebuild();
      await tester.pump();
      expect(controller, same(original));

      controller!.reset();
      await tester.pump();
      expect(controller!.value, 2, reason: 'reset uses the initial mount value');
    });
  });

  group('collection controllers', () {
    testComponents('useList exposes a live immutable view and skips no-op mutations', (tester) async {
      ListController<int>? controller;
      var builds = 0;

      tester.pumpComponent(
        HookBuilder(
          builder: (context) {
            builds++;
            controller = useList<int>(<int>[1, 2]);
            return Component.text('${controller!.value}');
          },
        ),
      );
      final original = controller;
      final view = controller!.value;

      controller!.addAll(const <int>[]);
      controller!.insertAll(1, const <int>[]);
      controller!.setAt(0, 1);
      expect(controller!.remove(9), isFalse);
      controller!.replaceAll(<int>[1, 2]);
      await tester.pump();
      expect(builds, 1);

      controller!
        ..add(3)
        ..insert(1, 4);
      await tester.pump();
      expect(view, <int>[1, 4, 2, 3]);
      expect(controller, same(original));
      expect(() => view.add(5), throwsUnsupportedError);

      controller!.setAt(2, 6);
      expect(controller!.remove(4), isTrue);
      expect(controller!.removeAt(0), 1);
      await tester.pump();
      expect(view, <int>[6, 3]);

      controller!.clear();
      await tester.pump();
      final afterClearBuilds = builds;
      controller!.clear();
      await tester.pump();
      expect(builds, afterClearBuilds);
    });

    testComponents('useMap exposes a live immutable view and skips equal entries', (tester) async {
      MapController<String, int?>? controller;
      var builds = 0;

      tester.pumpComponent(
        HookBuilder(
          builder: (context) {
            builds++;
            controller = useMap<String, int?>(<String, int?>{'a': 1, 'nullable': null});
            return Component.text('${controller!.value}');
          },
        ),
      );
      final original = controller;
      final view = controller!.value;

      controller!.setValue('a', 1);
      controller!.setValue('nullable', null);
      controller!.setAll(<String, int?>{'a': 1});
      expect(controller!.remove('missing'), isNull);
      controller!.replaceAll(<String, int?>{'nullable': null, 'a': 1});
      await tester.pump();
      expect(builds, 1);

      controller!.setAll(<String, int?>{'b': 2, 'c': 3});
      await tester.pump();
      expect(view, <String, int?>{'a': 1, 'nullable': null, 'b': 2, 'c': 3});
      expect(controller, same(original));
      expect(() => view['d'] = 4, throwsUnsupportedError);

      expect(controller!.remove('nullable'), isNull, reason: 'a nullable entry is still removed');
      await tester.pump();
      expect(view.containsKey('nullable'), isFalse);

      controller!.clear();
      await tester.pump();
      final afterClearBuilds = builds;
      controller!.clear();
      await tester.pump();
      expect(builds, afterClearBuilds);
    });

    testComponents('useSet preserves uniqueness and skips no-op mutations', (tester) async {
      SetController<int>? controller;
      var builds = 0;

      tester.pumpComponent(
        HookBuilder(
          builder: (context) {
            builds++;
            controller = useSet<int>(<int>[1, 2, 2]);
            return Component.text('${controller!.value}');
          },
        ),
      );
      final original = controller;
      final view = controller!.value;

      expect(controller!.add(2), isFalse);
      controller!.addAll(<int>[1, 2]);
      expect(controller!.remove(9), isFalse);
      controller!.replaceAll(<int>[2, 1]);
      await tester.pump();
      expect(builds, 1);

      expect(controller!.add(3), isTrue);
      controller!.addAll(<int>[3, 4]);
      expect(controller!.remove(1), isTrue);
      await tester.pump();
      expect(view, <int>{2, 3, 4});
      expect(controller, same(original));
      expect(() => view.add(5), throwsUnsupportedError);

      controller!.clear();
      await tester.pump();
      final afterClearBuilds = builds;
      controller!.clear();
      await tester.pump();
      expect(builds, afterClearBuilds);
    });

    testComponents('useQueue preserves FIFO order and skips no-op mutations', (tester) async {
      QueueController<int>? controller;
      var builds = 0;

      tester.pumpComponent(
        HookBuilder(
          builder: (context) {
            builds++;
            controller = useQueue<int>(<int>[1, 2]);
            return Component.text('${controller!.value}');
          },
        ),
      );
      final original = controller;
      final view = controller!.value;

      controller!.enqueueAll(const <int>[]);
      controller!.replaceAll(<int>[1, 2]);
      await tester.pump();
      expect(builds, 1);

      controller!
        ..enqueue(3)
        ..enqueueAll(<int>[4, 5]);
      await tester.pump();
      expect(view, <int>[1, 2, 3, 4, 5]);
      expect(controller!.length, 5);
      expect(controller!.isNotEmpty, isTrue);
      expect(controller, same(original));
      expect(() => view.add(6), throwsUnsupportedError);

      expect(controller!.dequeue(), 1);
      expect(controller!.dequeue(), 2);
      await tester.pump();
      expect(view, <int>[3, 4, 5]);

      controller!.clear();
      await tester.pump();
      expect(controller!.isEmpty, isTrue);
      final afterClearBuilds = builds;
      controller!.clear();
      await tester.pump();
      expect(builds, afterClearBuilds);
      expect(controller!.dequeue, throwsStateError);
    });
  });

  group('lifecycle aliases', () {
    testComponents('mount, unmount, and effect-once use client lifecycle timing', (tester) async {
      final harness = TestHarnessController();
      final events = <String>[];
      var callbackVersion = 0;

      Component child() => HookBuilder(
        builder: (context) {
          final currentVersion = callbackVersion;
          useMount(() => events.add('mount'));
          useEffectOnce(() {
            events.add('once');
            return () => events.add('cleanup:once');
          });
          useUnmount(() => events.add('unmount:$currentVersion'));
          return const Component.empty();
        },
      );

      tester.pumpComponent(TestHarness(controller: harness, builder: child));
      expect(events, <String>['mount', 'once']);

      callbackVersion = 1;
      harness.rebuild();
      await tester.pump();
      expect(events, <String>['mount', 'once']);

      harness.unmountChild();
      await tester.pump();
      expect(events, <String>['mount', 'once', 'unmount:1', 'cleanup:once']);
    });

    testComponents('useUpdateEffect skips mount and manages unkeyed cleanup', (tester) async {
      final harness = TestHarnessController();
      final events = <String>[];
      var version = 0;

      Component child() => HookBuilder(
        builder: (context) {
          final currentVersion = version;
          useUpdateEffect(() {
            events.add('effect:$currentVersion');
            return () => events.add('cleanup:$currentVersion');
          });
          return const Component.empty();
        },
      );

      tester.pumpComponent(TestHarness(controller: harness, builder: child));
      expect(events, isEmpty);

      version = 1;
      harness.rebuild();
      await tester.pump();
      expect(events, <String>['effect:1']);

      version = 2;
      harness.rebuild();
      await tester.pump();
      expect(events, <String>['effect:1', 'cleanup:1', 'effect:2']);

      harness.unmountChild();
      await tester.pump();
      expect(events.last, 'cleanup:2');
    });

    testComponents('useUpdateEffect honors keys after skipping mount', (tester) async {
      final harness = TestHarnessController();
      final events = <String>[];
      var key = 0;

      Component child() => HookBuilder(
        builder: (context) {
          final currentKey = key;
          useUpdateEffect(() {
            events.add('effect:$currentKey');
            return () => events.add('cleanup:$currentKey');
          }, <Object?>[key]);
          return const Component.empty();
        },
      );

      tester.pumpComponent(TestHarness(controller: harness, builder: child));
      harness.rebuild();
      await tester.pump();
      expect(events, isEmpty);

      key = 1;
      harness.rebuild();
      await tester.pump();
      expect(events, <String>['effect:1']);

      key = 2;
      harness.rebuild();
      await tester.pump();
      expect(events, <String>['effect:1', 'effect:2', 'cleanup:1']);
    });

    testComponents('usePostFrameUpdateEffect skips the mount frame and honors keys', (tester) async {
      final harness = TestHarnessController();
      final events = <String>[];
      var key = 0;

      Component child() => HookBuilder(
        builder: (context) {
          final currentKey = key;
          usePostFrameUpdateEffect(() {
            events.add('effect:$currentKey');
            return () => events.add('cleanup:$currentKey');
          }, <Object?>[key]);
          events.add('build:$currentKey');
          return const Component.empty();
        },
      );

      tester.pumpComponent(TestHarness(controller: harness, builder: child));
      await tester.pump();
      harness.rebuild();
      await tester.pump();
      expect(events, <String>['build:0', 'build:0']);

      key = 1;
      harness.rebuild();
      await tester.pump();
      expect(events, <String>['build:0', 'build:0', 'build:1', 'effect:1']);

      harness.unmountChild();
      await tester.pump();
      expect(events.last, 'cleanup:1');
    });

    test('all lifecycle aliases stay inactive during server rendering', () {
      final binding = CapturingTestComponentsBinding(isClient: false);
      addTearDown(binding.detachRootComponent);
      final events = <String>[];

      binding.attachRootComponent(
        HookBuilder(
          builder: (context) {
            useMount(() => events.add('mount'));
            useUnmount(() => events.add('unmount'));
            usePostFrameUpdateEffect(() {
              events.add('post-frame-update');
              return null;
            });
            useEffectOnce(() {
              events.add('once');
              return () => events.add('cleanup:once');
            });
            useUpdateEffect(() {
              events.add('update');
              return () => events.add('cleanup:update');
            });
            return const Component.empty();
          },
        ),
      );
      binding.detachRootComponent();

      expect(events, isEmpty);
    });
  });
}
