import 'dart:async';

import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

final class ReportedBuildError {
  const ReportedBuildError(this.element, this.error, this.stackTrace);

  final Element element;
  final Object error;
  final StackTrace stackTrace;
}

final class CapturingTestComponentsBinding extends TestComponentsBinding {
  CapturingTestComponentsBinding({
    required bool isClient,
    this.deferInitialPostFrameCallbacks = false,
  }) : _deferringPostFrameCallbacks = deferInitialPostFrameCallbacks,
       super('/', isClient);

  final bool deferInitialPostFrameCallbacks;
  bool _deferringPostFrameCallbacks;
  final List<VoidCallback> _deferredPostFrameCallbacks = [];

  final List<ReportedBuildError> errors = <ReportedBuildError>[];
  final List<Type> reportingComponentTypes = <Type>[];

  @override
  void reportBuildError(
    Element element,
    Object error,
    StackTrace stackTrace,
  ) {
    reportingComponentTypes.add(element.component.runtimeType);
    errors.add(ReportedBuildError(element, error, stackTrace));
  }

  @override
  void addPostFrameCallback(VoidCallback callback) {
    if (_deferringPostFrameCallbacks) {
      _deferredPostFrameCallbacks.add(callback);
    } else {
      super.addPostFrameCallback(callback);
    }
  }

  @override
  void scheduleFrame(VoidCallback frameCallback) {
    super.scheduleFrame(() {
      for (final callback in _takeDeferredPostFrameCallbacks()) {
        super.addPostFrameCallback(callback);
      }
      frameCallback();
    });
  }

  void flushDeferredPostFrameCallbacks() {
    for (final callback in _takeDeferredPostFrameCallbacks()) {
      callback();
    }
  }

  List<VoidCallback> _takeDeferredPostFrameCallbacks() {
    _deferringPostFrameCallbacks = false;
    final callbacks = List<VoidCallback>.of(_deferredPostFrameCallbacks);
    _deferredPostFrameCallbacks.clear();
    return callbacks;
  }

  void reassembleHooks() {
    rootElement!.visitChildren((element) {
      // ignore: invalid_use_of_protected_member
      element.reassemble();
    });
  }

  Future<void> pump() => pumpEventQueue();
}
