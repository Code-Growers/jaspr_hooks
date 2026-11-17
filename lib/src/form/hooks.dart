import '../foundation_hooks.dart';
import '../framework.dart';
import '../primitives.dart';
import 'autosave.dart';
import 'core.dart';
import 'navigation.dart';

void useFormNavigationGuard(FormNavigationGuard guard, bool Function() blocked) {
  final latest = useLatest(blocked);
  useEffect(() => guard.register(() => latest.value()), [guard]);
}

/// Owns a draft for the component lifetime. New defaultValues do not replace
/// edits on a rebuild; call reset explicitly after loading another record.
FormController<T> useForm<T>(FormOptions<T> options, {List<Object?> keys = const []}) {
  final isClient = useContext().binding.isClient;
  final form = useDisposable(() => FormController(options, allowExecution: isClient), (form) => form.dispose(), keys);
  form.options = options;
  return form;
}

/// Subscribe at the smallest component that renders the selected state.
S useFormState<T, S>(FormController<T> form, S Function(FormState<T>) selector, {bool Function(S, S)? equals}) =>
    useExternalStore(
      form.subscribe,
      () => selector(form.state),
      getServerSnapshot: () => selector(form.state),
      equals: equals,
    );

FieldController<T, V> useField<T, V>(
  FormController<T> form,
  FormFieldKey<T, V> key, {
  FieldValidators<T, V> validators = const FieldValidators(),
}) {
  final field = form.field(key, validators: validators);
  useExternalStore(form.subscribe, () => form.version, getServerSnapshot: () => form.version);
  useEffect(
    () =>
        () => form.unregisterField(key.path),
    [form, key.path],
  );
  return field;
}

FormAutosave<T> useFormAutosave<T>(
  FormController<T> form, {
  Duration debounce = const Duration(milliseconds: 600),
  bool Function()? canSave,
  Future<bool> Function()? save,
}) {
  final enabled = useContext().binding.isClient;
  final latestCanSave = useLatest(canSave);
  final latestSave = useLatest(save);
  return useDisposable(
    () => FormAutosave(
      form,
      debounce: debounce,
      enabled: enabled,
      canSave: () => latestCanSave.value?.call() ?? true,
      save: () => latestSave.value?.call() ?? form.handleSubmit(),
    ),
    (autosave) => autosave.dispose(),
    [form, debounce, enabled],
  );
}
