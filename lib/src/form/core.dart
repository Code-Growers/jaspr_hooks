import 'dart:async';

enum FormValidationCause { onChange, onBlur, onSubmit, onServer }

enum FormSubmissionStatus { idle, validating, submitting, success, invalid, error, uncertain }

/// A backend path and rule code survive localization and routing to a control.
final class FormIssue {
  const FormIssue(this.message, {this.path, this.code});
  final String message;
  final String? path;
  final String? code;
}

final class FormErrors {
  FormErrors({Map<String, List<FormIssue>> fields = const {}, List<FormIssue> form = const []})
    : fields = Map.unmodifiable(fields.map((key, value) => MapEntry(key, List<FormIssue>.unmodifiable(value)))),
      form = List.unmodifiable(form);
  factory FormErrors.messages(Map<String, String> fields, {Iterable<String> form = const []}) => FormErrors(
    fields: fields.map((key, value) => MapEntry(key, [FormIssue(value, path: key)])),
    form: form.map((message) => FormIssue(message)).toList(),
  );
  final Map<String, List<FormIssue>> fields;
  final List<FormIssue> form;
  bool get isEmpty => fields.values.every((errors) => errors.isEmpty) && form.isEmpty;
  bool get isNotEmpty => !isEmpty;
  FormErrors withoutFields(Set<String> paths) => FormErrors(
    fields: {...fields}..removeWhere((key, _) => paths.contains(key)),
    form: form,
  );
  FormErrors merge(FormErrors other) => FormErrors(
    fields: {
      for (final path in {...fields.keys, ...other.fields.keys}) path: [...?fields[path], ...?other.fields[path]],
    },
    form: [...form, ...other.form],
  );
}

/// Typed lens into an immutable draft. Paths are stable, including array indexes.
final class FormFieldKey<T, V> {
  const FormFieldKey(this.path, {required this.read, required this.write});
  final String path;
  final V Function(T values) read;
  final T Function(T values, V value) write;
}

final class FormValidationSignal {
  bool _cancelled = false;
  bool get isCancelled => _cancelled;
  final List<void Function()> _listeners = [];
  void Function() onCancel(void Function() callback) {
    if (_cancelled) {
      callback();
      return () {};
    }
    _listeners.add(callback);
    return () => _listeners.remove(callback);
  }

  void _cancel() {
    if (_cancelled) return;
    _cancelled = true;
    for (final callback in List.of(_listeners)) {
      callback();
    }
    _listeners.clear();
  }
}

final class FormValidationContext<T> {
  const FormValidationContext({required this.value, required this.cause, required this.signal});
  final T value;
  final FormValidationCause cause;
  final FormValidationSignal signal;
}

typedef FormValidator<T> = FormErrors? Function(FormValidationContext<T> context);
typedef AsyncFormValidator<T> = Future<FormErrors?> Function(FormValidationContext<T> context);

final class FormValidators<T> {
  const FormValidators({
    this.onChange,
    this.onBlur,
    this.onSubmit,
    this.onChangeAsync,
    this.onBlurAsync,
    this.onSubmitAsync,
    this.asyncDebounce = Duration.zero,
  });
  final FormValidator<T>? onChange, onBlur, onSubmit;
  final AsyncFormValidator<T>? onChangeAsync, onBlurAsync, onSubmitAsync;
  final Duration asyncDebounce;
  FormValidator<T>? sync(FormValidationCause cause) => switch (cause) {
    FormValidationCause.onChange => onChange,
    FormValidationCause.onBlur => onBlur,
    FormValidationCause.onSubmit => onSubmit,
    FormValidationCause.onServer => null,
  };
  AsyncFormValidator<T>? async(FormValidationCause cause) => switch (cause) {
    FormValidationCause.onChange => onChangeAsync,
    FormValidationCause.onBlur => onBlurAsync,
    FormValidationCause.onSubmit => onSubmitAsync,
    FormValidationCause.onServer => null,
  };
}

final class FieldValidators<T, V> {
  const FieldValidators({
    this.onChange,
    this.onBlur,
    this.onSubmit,
    this.onChangeAsync,
    this.onBlurAsync,
    this.onSubmitAsync,
    this.asyncDebounce = Duration.zero,
    this.listenTo = const [],
  });
  final List<FormIssue> Function(V value, T values)? onChange, onBlur, onSubmit;
  final Future<List<FormIssue>> Function(V value, T values, FormValidationSignal signal)? onChangeAsync,
      onBlurAsync,
      onSubmitAsync;
  final Duration asyncDebounce;
  final List<String> listenTo;
}

/// Return invalid/uncertain rather than reporting a successful transport write.
final class FormSubmitResult<T> {
  const FormSubmitResult.success({this.acceptedValues}) : errors = null, uncertain = false;
  const FormSubmitResult.invalid(this.errors) : acceptedValues = null, uncertain = false;
  const FormSubmitResult.uncertain() : acceptedValues = null, errors = null, uncertain = true;
  final T? acceptedValues;
  final FormErrors? errors;
  final bool uncertain;
}

final class FormSubmitContext<T> {
  const FormSubmitContext({required this.value, required this.revision});
  final T value;
  final int revision;
}

final class FormOptions<T> {
  const FormOptions({
    required this.defaultValues,
    this.validators = const FormValidators(),
    this.onSubmit,
    this.copy,
    this.equals,
  });
  final T defaultValues;
  final FormValidators<T> validators;
  final Future<FormSubmitResult<T>> Function(FormSubmitContext<T> context)? onSubmit;

  /// Supply for mutable domain models. Immutable drafts may use the identity copy.
  final T Function(T value)? copy;
  final bool Function(T a, T b)? equals;
}

final class FormFieldMeta {
  FormFieldMeta({
    required this.isTouched,
    required this.isBlurred,
    required this.isDirty,
    required this.isDefaultValue,
    required this.hasUnsavedChanges,
    required this.isValidating,
    required Map<FormValidationCause, List<FormIssue>> errorMap,
  }) : errorMap = Map.unmodifiable(errorMap);
  final bool isTouched, isBlurred, isDirty, isDefaultValue, hasUnsavedChanges, isValidating;
  final Map<FormValidationCause, List<FormIssue>> errorMap;
  bool get isPristine => !isDirty;
  List<FormIssue> get errors => _uniqueIssues(errorMap.values.expand((errors) => errors));
  bool get isValid => errors.isEmpty;
}

final class FormState<T> {
  FormState({
    required this.values,
    required this.revision,
    required this.status,
    required this.submissionAttempts,
    required this.isDirty,
    required this.isDefaultValue,
    required this.hasUnsavedChanges,
    required this.isValidating,
    required this.error,
    required Map<FormValidationCause, FormErrors> errorMap,
  }) : errorMap = Map.unmodifiable(errorMap);
  final T values;
  final int revision, submissionAttempts;
  final FormSubmissionStatus status;
  final bool isDirty, isDefaultValue, hasUnsavedChanges, isValidating;
  final Object? error;
  final Map<FormValidationCause, FormErrors> errorMap;
  bool get isPristine => !isDirty;
  bool get isSubmitting => status == FormSubmissionStatus.submitting || status == FormSubmissionStatus.validating;
  bool get isSubmitSuccessful => status == FormSubmissionStatus.success;
  bool get isValid => errorMap.values.every((errors) => errors.isEmpty);
  bool get canSubmit => !isSubmitting && !isValidating && status != FormSubmissionStatus.uncertain;
  bool get shouldBlockNavigation => hasUnsavedChanges || isSubmitting || status == FormSubmissionStatus.uncertain;
  Map<String, List<FormIssue>> get fieldErrors {
    final result = <String, List<FormIssue>>{};
    for (final errors in errorMap.values) {
      for (final entry in errors.fields.entries) {
        result.update(entry.key, (value) => [...value, ...entry.value], ifAbsent: () => entry.value);
      }
    }
    return Map.unmodifiable(result.map((path, issues) => MapEntry(path, _uniqueIssues(issues))));
  }

  List<FormIssue> get errors => _uniqueIssues(errorMap.values.expand((errors) => errors.form));
}

class FormController<T> {
  FormController(this.options, {this.allowExecution = true}) {
    _values = _copy(options.defaultValues);
    _defaults = _copy(_values);
    _accepted = _copy(_values);
  }
  FormOptions<T> options;
  final bool allowExecution;
  late T _values, _defaults, _accepted;
  final _listeners = <void Function()>[];
  final _errors = <FormValidationCause, FormErrors>{};
  final _touched = <String>{}, _blurred = <String>{}, _dirtyFields = <String>{};
  final _fields = <String, _RegisteredField<T>>{};
  final _signals = <FormValidationSignal>{};
  int _revision = 0, _generation = 0, _attempts = 0;
  final _changedAt = <String, int>{};
  bool _dirty = false, _disposed = false, _validating = false;
  FormSubmissionStatus _status = FormSubmissionStatus.idle;
  Object? _error;
  FormState<T>? _snapshot;
  int _version = 0;
  int get version => _version;
  T _copy(T value) => options.copy?.call(value) ?? value;
  bool _equals(T a, T b) => options.equals?.call(a, b) ?? formValueEquals(a, b);
  T get values => _values;
  bool get disposed => _disposed;
  FormState<T> get state => _snapshot ??= FormState(
    values: _values,
    revision: _revision,
    status: _status,
    submissionAttempts: _attempts,
    isDirty: _dirty,
    isDefaultValue: _equals(_values, _defaults),
    hasUnsavedChanges: !_equals(_values, _accepted),
    isValidating: _validating,
    error: _error,
    errorMap: _errors,
  );
  void Function() subscribe(void Function() listener) {
    if (_disposed) return () {};
    _listeners.add(listener);
    return () => _listeners.remove(listener);
  }

  void _notify() {
    _snapshot = null;
    _version++;
    if (_disposed) return;
    for (final listener in List.of(_listeners)) {
      listener();
    }
  }

  void _cancelValidation() {
    for (final signal in List.of(_signals)) {
      signal._cancel();
    }
    _signals.clear();
    _validating = false;
  }

  void setValues(T value, {Set<String> changedFields = const {}, bool validate = true}) {
    if (_disposed) return;
    if (_equals(_values, value)) {
      // Domain equality can exclude presentation metadata (selected address
      // suggestions or validation focus). Preserve it without dirtying data.
      if (!identical(_values, value)) {
        _values = _copy(value);
        _notify();
      }
      return;
    }
    _cancelValidation();
    final changed = {...changedFields};
    for (final entry in _fields.entries) {
      if (!formValueEquals(entry.value.read(_values), entry.value.read(value))) changed.add(entry.key);
    }
    _values = _copy(value);
    _revision++;
    for (final path in changed) {
      _changedAt[path] = _revision;
    }
    _dirty = true;
    _touched.addAll(changed);
    _dirtyFields.addAll(changed);
    // Errors for other inputs, and unmapped form errors, remain visible.
    _errors.updateAll((cause, errors) => errors.withoutFields(changed));
    _error = null;
    _notify();
    if (validate && allowExecution) unawaited(this.validate(FormValidationCause.onChange, fields: changed));
  }

  FieldController<T, V> field<V>(FormFieldKey<T, V> key, {FieldValidators<T, V> validators = const FieldValidators()}) {
    _fields[key.path] = _RegisteredField<T>(
      read: key.read,
      listenTo: validators.listenTo,
      debounce: validators.asyncDebounce,
      sync: (value, cause) =>
          (switch (cause) {
            FormValidationCause.onChange => validators.onChange,
            FormValidationCause.onBlur => validators.onBlur,
            FormValidationCause.onSubmit => validators.onSubmit ?? validators.onChange ?? validators.onBlur,
            FormValidationCause.onServer => null,
          })?.call(key.read(value), value) ??
          const [],
      async: (value, cause, signal) => (switch (cause) {
        FormValidationCause.onChange => validators.onChangeAsync,
        FormValidationCause.onBlur => validators.onBlurAsync,
        FormValidationCause.onSubmit => validators.onSubmitAsync ?? validators.onChangeAsync ?? validators.onBlurAsync,
        FormValidationCause.onServer => null,
      })?.call(key.read(value), value, signal),
    );
    return FieldController._(this, key);
  }

  void unregisterField(String path) => _fields.remove(path);
  void handleBlur(String path) {
    if (_disposed) return;
    _touched.add(path);
    _blurred.add(path);
    _notify();
    if (allowExecution) unawaited(validate(FormValidationCause.onBlur, fields: {path}));
  }

  FormFieldMeta fieldMeta<V>(FormFieldKey<T, V> key) => FormFieldMeta(
    isTouched: _touched.contains(key.path),
    isBlurred: _blurred.contains(key.path),
    isDirty: _dirtyFields.contains(key.path),
    isDefaultValue: formValueEquals(key.read(_values), key.read(_defaults)),
    hasUnsavedChanges: !formValueEquals(key.read(_values), key.read(_accepted)),
    isValidating: _validating,
    errorMap: {
      for (final entry in _errors.entries)
        if (entry.value.fields[key.path]?.isNotEmpty ?? false) entry.key: entry.value.fields[key.path]!,
    },
  );
  void setErrors(FormErrors errors, {FormValidationCause cause = FormValidationCause.onServer}) {
    if (_disposed) return;
    _errors[cause] = errors;
    _notify();
  }

  void clearErrors({FormValidationCause? cause}) {
    if (cause == null) {
      _errors.clear();
    } else {
      _errors.remove(cause);
    }
    _notify();
  }

  Future<bool> validate(FormValidationCause cause, {Set<String>? fields}) async {
    if (_disposed || !allowExecution) return false;
    _cancelValidation();
    final signal = FormValidationSignal();
    _signals.add(signal);
    final revision = _revision, generation = _generation;
    final value = _copy(_values);
    final context = FormValidationContext(value: value, cause: cause, signal: signal);
    final validators = options.validators;
    final selected = _fields.entries
        .where((entry) => fields == null || fields.contains(entry.key) || entry.value.listenTo.any(fields.contains))
        .toList();
    var errors = FormErrors();
    _validating = true;
    _notify();
    bool current() => !_disposed && !signal.isCancelled && revision == _revision && generation == _generation;
    try {
      final sync =
          validators.sync(cause) ??
          (cause == FormValidationCause.onSubmit ? validators.onChange ?? validators.onBlur : null);
      errors = sync?.call(context) ?? FormErrors();
      for (final entry in selected) {
        final issues = entry.value.sync(value, cause);
        if (issues.isNotEmpty) errors = errors.merge(FormErrors(fields: {entry.key: issues}));
      }
      if (current()) {
        _errors[cause] = _mergeValidation(cause, errors, fields, selected);
        _notify();
      }
      final async =
          validators.async(cause) ??
          (cause == FormValidationCause.onSubmit ? validators.onChangeAsync ?? validators.onBlurAsync : null);
      if (errors.isEmpty) {
        if (async != null &&
            await _delay(cause == FormValidationCause.onSubmit ? Duration.zero : validators.asyncDebounce, signal)) {
          errors = errors.merge(await async(context) ?? FormErrors());
        }
        for (final entry in selected) {
          if (!current()) return false;
          if (!await _delay(cause == FormValidationCause.onSubmit ? Duration.zero : entry.value.debounce, signal)) {
            return false;
          }
          final pending = entry.value.async(value, cause, signal);
          if (pending != null) {
            final issues = await pending;
            if (issues.isNotEmpty) errors = errors.merge(FormErrors(fields: {entry.key: issues}));
          }
        }
      }
      if (!current()) return false;
      _errors[cause] = _mergeValidation(cause, errors, fields, selected);
      return errors.isEmpty;
    } catch (error) {
      if (current()) {
        _error = error;
        _errors[cause] = FormErrors(
          form: const [FormIssue('Validation could not be completed.', code: 'validation_failed')],
        );
      }
      return false;
    } finally {
      _signals.remove(signal);
      if (current()) {
        _validating = false;
        _notify();
      }
    }
  }

  FormErrors _mergeValidation(
    FormValidationCause cause,
    FormErrors errors,
    Set<String>? fields,
    List<MapEntry<String, _RegisteredField<T>>> selected,
  ) {
    if (fields == null || options.validators.sync(cause) != null || options.validators.async(cause) != null) {
      return errors;
    }
    return (_errors[cause] ?? FormErrors()).withoutFields(selected.map((entry) => entry.key).toSet()).merge(errors);
  }

  Future<bool> handleSubmit({Future<FormSubmitResult<T>> Function(FormSubmitContext<T>)? onSubmit}) async {
    if (_disposed || !allowExecution || state.isSubmitting || _status == FormSubmissionStatus.uncertain) return false;
    final submit = onSubmit ?? options.onSubmit;
    if (submit == null) throw StateError('FormOptions.onSubmit is required');
    final generation = _generation, revision = _revision;
    _attempts++;
    _status = FormSubmissionStatus.validating;
    _error = null;
    _touched.addAll(_fields.keys);
    _notify();
    if (!await validate(FormValidationCause.onSubmit) ||
        _disposed ||
        generation != _generation ||
        revision != _revision) {
      if (!_disposed && generation == _generation) {
        _status = FormSubmissionStatus.invalid;
        _notify();
      }
      return false;
    }
    final submitted = _copy(_values);
    _status = FormSubmissionStatus.submitting;
    _notify();
    try {
      final result = await submit(FormSubmitContext(value: submitted, revision: revision));
      if (_disposed || generation != _generation) return false;
      if (result.uncertain) {
        _status = FormSubmissionStatus.uncertain;
        return false;
      }
      if (result.errors != null) {
        // A rejection describes the submitted snapshot, not newer edits.
        final changedSinceSubmit = _changedAt.entries
            .where((entry) => entry.value > revision)
            .map((entry) => entry.key)
            .toSet();
        _errors[FormValidationCause.onServer] = result.errors!.withoutFields(changedSinceSubmit);
        _status = FormSubmissionStatus.invalid;
        return false;
      }
      _accepted = _copy(result.acceptedValues ?? submitted);
      if (revision == _revision && result.acceptedValues != null) _values = _copy(result.acceptedValues as T);
      _errors.remove(FormValidationCause.onServer);
      _status = FormSubmissionStatus.success;
      return true;
    } catch (error) {
      if (!_disposed && generation == _generation) {
        _error = error;
        _status = FormSubmissionStatus.error;
      }
      return false;
    } finally {
      if (!_disposed && generation == _generation) _notify();
    }
  }

  /// Acknowledge exactly the snapshot sent by an externally managed workflow.
  void acceptBaseline(T submitted) {
    if (_disposed) return;
    _accepted = _copy(submitted);
    _notify();
  }

  void allowRetry() {
    if (_status == FormSubmissionStatus.uncertain) {
      _status = FormSubmissionStatus.idle;
      _notify();
    }
  }

  void reset([T? values]) => resetValues(values ?? _defaults);

  /// Explicit-value reset, including null when T is nullable.
  void resetValues(T values) {
    if (_disposed) return;
    _generation++;
    _cancelValidation();
    _values = _copy(values);
    _defaults = _copy(_values);
    _accepted = _copy(_values);
    _revision++;
    _attempts = 0;
    _dirty = false;
    _touched.clear();
    _blurred.clear();
    _dirtyFields.clear();
    _changedAt.clear();
    _errors.clear();
    _error = null;
    _status = FormSubmissionStatus.idle;
    _notify();
  }

  void dispose() {
    _disposed = true;
    _generation++;
    _cancelValidation();
    _listeners.clear();
  }
}

final class FieldController<T, V> {
  const FieldController._(this.form, this.key);
  final FormController<T> form;
  final FormFieldKey<T, V> key;
  V get value => key.read(form.values);
  FormFieldMeta get meta => form.fieldMeta(key);
  void handleChange(V value) => form.setValues(key.write(form.values, value), changedFields: {key.path});
  void handleBlur() => form.handleBlur(key.path);
}

final class _RegisteredField<T> {
  const _RegisteredField({
    required this.read,
    required this.sync,
    required this.async,
    required this.listenTo,
    required this.debounce,
  });
  final Object? Function(T) read;
  final List<FormIssue> Function(T, FormValidationCause) sync;
  final Future<List<FormIssue>>? Function(T, FormValidationCause, FormValidationSignal) async;
  final List<String> listenTo;
  final Duration debounce;
}

Future<bool> _delay(Duration delay, FormValidationSignal signal) async {
  if (signal.isCancelled) return false;
  if (delay == Duration.zero) return true;
  final done = Completer<bool>();
  final timer = Timer(delay, () => done.complete(true));
  final remove = signal.onCancel(() {
    timer.cancel();
    if (!done.isCompleted) done.complete(false);
  });
  try {
    return await done.future;
  } finally {
    remove();
  }
}

/// Structural comparison for immutable collections; models may provide equals.
bool formValueEquals(Object? a, Object? b) {
  if (identical(a, b)) return true;
  if (a is List && b is List) {
    return a.length == b.length && List.generate(a.length, (i) => i).every((i) => formValueEquals(a[i], b[i]));
  }
  if (a is Map && b is Map) {
    return a.length == b.length && a.keys.every((key) => b.containsKey(key) && formValueEquals(a[key], b[key]));
  }
  if (a is Set && b is Set) return a.length == b.length && a.containsAll(b);
  return a == b;
}

List<FormIssue> _uniqueIssues(Iterable<FormIssue> issues) {
  final seen = <(String, String?, String?)>{};
  return List.unmodifiable(issues.where((issue) => seen.add((issue.message, issue.path, issue.code))));
}
