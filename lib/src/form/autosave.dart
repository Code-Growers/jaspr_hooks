import 'dart:async';

import 'core.dart';

/// Optional serialized autosave. A rejected revision is never automatically
/// retried; a subsequent edit, explicit flush, or explicit retry is required.
class FormAutosave<T> {
  FormAutosave(
    this.form, {
    this.debounce = const Duration(milliseconds: 600),
    this.canSave,
    this.save,
    bool enabled = true,
  }) {
    _lastRevision = form.state.revision;
    _unsubscribe = enabled ? form.subscribe(_changed) : () {};
  }
  final FormController<T> form;
  final Duration debounce;
  final bool Function()? canSave;
  final Future<bool> Function()? save;
  late final void Function() _unsubscribe;
  late int _lastRevision;
  Timer? _timer;
  bool _disposed = false, _saving = false;
  bool get isSaving => _saving;
  bool get hasPending => form.state.hasUnsavedChanges || _saving;
  void _changed() {
    if (_disposed || form.state.revision == _lastRevision) return;
    _lastRevision = form.state.revision;
    _timer?.cancel();
    if (form.state.hasUnsavedChanges) _timer = Timer(debounce, () => unawaited(flush()));
  }

  /// Call on blur when canSave delays saving while a field is focused.
  Future<bool> flush() async {
    _timer?.cancel();
    _timer = null;
    if (_disposed ||
        _saving ||
        form.state.isSubmitting ||
        form.state.status == FormSubmissionStatus.uncertain ||
        !(canSave?.call() ?? true)) {
      return false;
    }
    if (!form.state.hasUnsavedChanges) return true;
    final revision = form.state.revision;
    _saving = true;
    try {
      return await (save?.call() ?? form.handleSubmit());
    } finally {
      _saving = false;
      if (!_disposed && form.state.revision != revision && form.state.hasUnsavedChanges) {
        _timer?.cancel();
        _timer = Timer(debounce, () => unawaited(flush()));
      }
    }
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _unsubscribe();
  }
}
