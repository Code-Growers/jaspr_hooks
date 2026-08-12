import 'package:jaspr/jaspr.dart';

typedef TestHarnessBuilder = Component Function();

/// Drives rebuilds without coupling tests to a hook under test.
final class TestHarnessController {
  _TestHarnessState? _state;

  bool get mounted => _state?.mounted ?? false;

  void rebuild([TestHarnessBuilder? builder]) {
    final state = _state;
    if (state == null) {
      throw StateError('The test harness is not mounted.');
    }
    state.rebuild(builder);
  }

  void unmountChild() => rebuild(() => const Component.empty());
}

final class TestHarness extends StatefulComponent {
  const TestHarness({
    required this.controller,
    required this.builder,
    super.key,
  });

  final TestHarnessController controller;
  final TestHarnessBuilder builder;

  @override
  State<TestHarness> createState() => _TestHarnessState();
}

final class _TestHarnessState extends State<TestHarness> {
  late TestHarnessBuilder _builder;

  @override
  void initState() {
    super.initState();
    _builder = component.builder;
    component.controller._state = this;
  }

  void rebuild(TestHarnessBuilder? builder) {
    setState(() {
      if (builder != null) {
        _builder = builder;
      }
    });
  }

  @override
  Component build(BuildContext context) => _builder();

  @override
  void dispose() {
    if (identical(component.controller._state, this)) {
      component.controller._state = null;
    }
    super.dispose();
  }
}
