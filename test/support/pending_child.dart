import 'package:jaspr/jaspr.dart';

/// Exercises unmount of a child that has not produced its initial subtree yet.
final class PendingChildController {
  _PendingChildElement? _element;

  void unmount() => _element!.unmountPendingChild();
}

final class PendingChild extends Component {
  const PendingChild({required this.controller, required this.child});

  final PendingChildController controller;
  final Component child;

  @override
  Element createElement() => _PendingChildElement(this);
}

final class _PendingChildElement extends BuildableElement {
  _PendingChildElement(PendingChild super.component);

  @override
  Component build() {
    final configuration = component as PendingChild;
    configuration.controller._element = this;
    return configuration.child;
  }

  void unmountPendingChild() {
    final pending = child!;
    forgetChild(pending);
    // This child has no rendered descendants yet. Keep its ancestors mounted
    // while exercising the public element lifecycle during its suspended build.
    pending.deactivate();
    pending.unmount();
  }
}
