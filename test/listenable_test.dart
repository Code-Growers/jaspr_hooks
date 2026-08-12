import 'package:jaspr/jaspr.dart';
import 'package:jaspr_hooks/jaspr_hooks.dart';
import 'package:jaspr_test/jaspr_test.dart';

import 'support/harness.dart';

void main() {
  group('useListenable', () {
    testComponents('subscribes, rebuilds, switches, and unsubscribes', (
      tester,
    ) async {
      final harness = TestHarnessController();
      final first = CountingNotifier();
      final second = CountingNotifier();
      var current = first;
      var builds = 0;

      Component child() => HookBuilder(
        builder: (context) {
          builds++;
          expect(useListenable(current), same(current));
          return Component.text('builds:$builds');
        },
      );

      tester.pumpComponent(TestHarness(controller: harness, builder: child));
      expect(first.activeListeners, 1);

      first.ping();
      await tester.pump();
      expect(builds, 2);

      current = second;
      harness.rebuild();
      await tester.pump();
      expect(first.activeListeners, 0);
      expect(second.activeListeners, 1);

      first.ping();
      await tester.pump();
      expect(builds, 3);
      second.ping();
      await tester.pump();
      expect(builds, 4);

      harness.unmountChild();
      await tester.pump();
      expect(second.activeListeners, 0);
    });
  });

  group('value listenables', () {
    testComponents('useValueListenable returns current values and rebuilds', (
      tester,
    ) async {
      final notifier = CountingValueNotifier<int>(1);
      var builds = 0;
      int? value;

      tester.pumpComponent(
        HookBuilder(
          builder: (context) {
            builds++;
            value = useValueListenable(notifier);
            return Component.text('value:$value');
          },
        ),
      );

      expect(value, 1);
      expect(notifier.activeListeners, 1);
      notifier.value = 2;
      await tester.pump();
      expect(value, 2);
      expect(builds, 2);
      expect(find.text('value:2'), findsOneComponent);
    });

    testComponents('useValueNotifier replaces on keys and owns disposal', (
      tester,
    ) async {
      final harness = TestHarnessController();
      var key = 0;
      ValueNotifier<int>? notifier;

      Component child() => HookBuilder(
        builder: (context) {
          notifier = useValueNotifier(10 + key, <Object?>[key]);
          return const Component.empty();
        },
      );

      tester.pumpComponent(TestHarness(controller: harness, builder: child));
      final first = notifier!;
      key = 1;
      harness.rebuild();
      await tester.pump();

      expect(notifier, isNot(same(first)));
      expect(notifier!.value, 11);
      expect(() => first.value = 12, throwsA(anything));

      harness.unmountChild();
      await tester.pump();
      expect(() => notifier!.value = 13, throwsA(anything));
    });
  });

  group('selectors and callbacks', () {
    testComponents('useListenableSelector filters irrelevant changes', (
      tester,
    ) async {
      final model = SelectableNotifier();
      var builds = 0;
      int? selected;

      tester.pumpComponent(
        HookBuilder(
          builder: (context) {
            builds++;
            selected = useListenableSelector(model, () => model.selected);
            return Component.text('selected:$selected');
          },
        ),
      );

      model.changeUnselected();
      await tester.pump();
      expect(builds, 1);
      expect(selected, 0);

      model.changeSelected(1);
      await tester.pump();
      expect(builds, 2);
      expect(selected, 1);
      expect(find.text('selected:1'), findsOneComponent);
    });

    testComponents('useOnListenableChange uses the latest callback', (
      tester,
    ) async {
      final harness = TestHarnessController();
      final notifier = CountingNotifier();
      final calls = <String>[];
      var callbackVersion = 'first';

      Component child() => HookBuilder(
        builder: (context) {
          final versionForBuild = callbackVersion;
          useOnListenableChange(
            notifier,
            () => calls.add(versionForBuild),
          );
          return const Component.empty();
        },
      );

      tester.pumpComponent(TestHarness(controller: harness, builder: child));
      notifier.ping();
      expect(calls, <String>['first']);

      callbackVersion = 'second';
      harness.rebuild();
      await tester.pump();
      expect(
        notifier.addCalls,
        1,
        reason: 'callback changes do not require resubscription',
      );

      notifier.ping();
      expect(calls, <String>['first', 'second']);

      harness.unmountChild();
      await tester.pump();
      expect(notifier.activeListeners, 0);
    });

    testComponents('useOnListenableChange moves to a new listenable', (
      tester,
    ) async {
      final harness = TestHarnessController();
      final first = CountingNotifier();
      final second = CountingNotifier();
      var current = first;
      var calls = 0;

      Component child() => HookBuilder(
        builder: (context) {
          useOnListenableChange(current, () => calls++);
          return const Component.empty();
        },
      );

      tester.pumpComponent(TestHarness(controller: harness, builder: child));
      current = second;
      harness.rebuild();
      await tester.pump();

      expect(first.activeListeners, 0);
      expect(second.activeListeners, 1);
      first.ping();
      second.ping();
      expect(calls, 1);
    });
  });
}

class CountingNotifier extends ChangeNotifier {
  int addCalls = 0;
  int removeCalls = 0;
  int activeListeners = 0;

  @override
  void addListener(VoidCallback listener) {
    addCalls++;
    activeListeners++;
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    removeCalls++;
    activeListeners--;
    super.removeListener(listener);
  }

  void ping() => notifyListeners();
}

final class CountingValueNotifier<T> extends ChangeNotifier implements ValueListenable<T> {
  CountingValueNotifier(this._value);

  int addCalls = 0;
  int removeCalls = 0;
  int activeListeners = 0;
  T _value;

  @override
  T get value => _value;

  set value(T value) {
    if (_value == value) return;
    _value = value;
    notifyListeners();
  }

  @override
  void addListener(VoidCallback listener) {
    addCalls++;
    activeListeners++;
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    removeCalls++;
    activeListeners--;
    super.removeListener(listener);
  }
}

final class SelectableNotifier extends ChangeNotifier {
  int selected = 0;
  int unselected = 0;

  void changeSelected(int value) {
    selected = value;
    notifyListeners();
  }

  void changeUnselected() {
    unselected++;
    notifyListeners();
  }
}
