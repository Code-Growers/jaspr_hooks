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
  }) : super('/', isClient);

  final bool deferInitialPostFrameCallbacks;

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
  void completeInitialFrame() {
    if (!deferInitialPostFrameCallbacks) {
      super.completeInitialFrame();
    }
  }

  void flushDeferredPostFrameCallbacks() {
    super.completeInitialFrame();
  }

  Future<void> pump() => pumpEventQueue();
}
