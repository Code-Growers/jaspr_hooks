import 'dart:async';

import 'package:jaspr_hooks/form.dart';
import 'package:test/test.dart';

typedef Draft = Map<String, String>;
final name = FormFieldKey<Draft, String>('name', read: (v) => v['name']!, write: (v, x) => {...v, 'name': x});
final email = FormFieldKey<Draft, String>('email', read: (v) => v['email']!, write: (v, x) => {...v, 'email': x});
const defaults = {'name': 'Alena', 'email': ''};
FormController<Draft> makeForm({
  FormValidators<Draft> validators = const FormValidators(),
  Future<FormSubmitResult<Draft>> Function(FormSubmitContext<Draft>)? submit,
}) => FormController(
  FormOptions(
    defaultValues: defaults,
    validators: validators,
    onSubmit: submit ?? (_) async => const FormSubmitResult.success(),
  ),
);

void main() {
  test('presentation-only model changes update values without dirtying or autosaving', () {
    final form = FormController(
      FormOptions<(String, String?)>(defaultValues: ('name', null), equals: (left, right) => left.$1 == right.$1),
    );
    form.setValues(('name', 'price-field'));
    expect(form.values.$2, 'price-field');
    expect(form.state.revision, 0);
    expect(form.state.hasUnsavedChanges, isFalse);
  });
  test('explicit nullable reset can clear a previously loaded record', () {
    final form = FormController(FormOptions<String?>(defaultValues: 'name'));
    form.resetValues(null);
    expect(form.values, isNull);
    expect(form.state.isPristine, isTrue);
  });
  test('a stale API rejection does not attach to a corrected value', () async {
    final response = Completer<FormSubmitResult<Draft>>();
    final form = makeForm(submit: (_) => response.future);
    final field = form.field(email);
    field.handleChange('invalid');
    final pending = form.handleSubmit();
    await Future<void>.delayed(Duration.zero);
    field.handleChange('eva@example.test');
    response.complete(FormSubmitResult.invalid(FormErrors.messages({'email': 'invalid'}, form: ['Check account'])));
    expect(await pending, isFalse);
    expect(form.state.fieldErrors['email'], isNull);
    expect(form.state.errors.single.message, 'Check account');
    expect(form.state.hasUnsavedChanges, isTrue);
  });
  test('identical messages keep their sources without duplicate presentation', () {
    final form = makeForm();
    form.setErrors(FormErrors.messages({'email': 'required'}));
    form.setErrors(FormErrors.messages({'email': 'required'}), cause: FormValidationCause.onSubmit);
    expect(form.state.errorMap, hasLength(2));
    expect(form.state.fieldErrors['email'], hasLength(1));
  });
  test('editing then reverting retains dirty history but removes navigation blocker', () {
    final form = makeForm();
    final field = form.field(name);
    field.handleChange('Eva');
    expect(field.meta.isTouched, isTrue);
    expect(form.state.shouldBlockNavigation, isTrue);
    field.handleChange('Alena');
    expect(form.state.isDirty, isTrue);
    expect(form.state.isDefaultValue, isTrue);
    expect(form.state.hasUnsavedChanges, isFalse);
    expect(field.meta.isPristine, isFalse);
    field.handleBlur();
    expect(field.meta.isBlurred, isTrue);
  });
  test('snapshots are stable until notifications and preserve previous error collections', () {
    final form = makeForm();
    expect(identical(form.state, form.state), isTrue);
    final previous = form.state;
    form.setErrors(FormErrors.messages({'name': 'invalid'}));
    expect(previous.fieldErrors, isEmpty);
    expect(form.state.fieldErrors.keys, ['name']);
  });
  test('nested indexed typed field updates only its addressed member', () {
    final form = FormController(FormOptions(defaultValues: ['a', 'b']));
    final key = FormFieldKey<List<String>, String>('members[1].name', read: (v) => v[1], write: (v, x) => [v[0], x]);
    final field = form.field(key);
    field.handleChange('c');
    form.setErrors(FormErrors.messages({'members[1].name': 'Invalid member'}));
    expect(form.values, ['a', 'c']);
    expect(field.meta.errors.single.path, 'members[1].name');
  });
  test('editing one field keeps unrelated server and unmapped errors', () {
    final form = makeForm();
    form.setErrors(FormErrors.messages({'name': 'name error', 'email': 'email error'}, form: ['unknown path']));
    form.field(name).handleChange('Eva');
    expect(form.state.fieldErrors.keys, ['email']);
    expect(form.state.errors.single.message, 'unknown path');
  });
  test('form validation reaches fields and prevents mutation', () async {
    var calls = 0;
    final form = makeForm(
      validators: FormValidators(onSubmit: (_) => FormErrors.messages({'email': 'Required'})),
      submit: (_) async {
        calls++;
        return const FormSubmitResult.success();
      },
    );
    expect(await form.handleSubmit(), isFalse);
    expect(calls, 0);
    expect(form.state.status, FormSubmissionStatus.invalid);
    expect(form.state.submissionAttempts, 1);
    expect(form.field(email).meta.errors.single.message, 'Required');
  });
  test('field validation and linked field changes run with the full draft', () async {
    final form = makeForm();
    final field = form.field(
      email,
      validators: FieldValidators(
        listenTo: ['name'],
        onChange: (value, values) => values['name'] == 'Eva' ? [const FormIssue('Check email')] : [],
      ),
    );
    form.field(name).handleChange('Eva');
    await Future<void>.delayed(Duration.zero);
    expect(field.meta.errors.single.message, 'Check email');
    expect(await form.handleSubmit(), isFalse);
  });
  test('duplicate submit runs one write and blocks navigation until completion', () async {
    final pending = Completer<FormSubmitResult<Draft>>();
    var calls = 0;
    final form = makeForm(
      submit: (_) {
        calls++;
        return pending.future;
      },
    );
    final first = form.handleSubmit();
    expect(await form.handleSubmit(), isFalse);
    await Future<void>.delayed(Duration.zero);
    expect(calls, 1);
    expect(form.state.shouldBlockNavigation, isTrue);
    pending.complete(const FormSubmitResult.success());
    expect(await first, isTrue);
    expect(form.state.shouldBlockNavigation, isFalse);
  });
  test('save acknowledges submitted revision without clearing newer edits', () async {
    final pending = Completer<FormSubmitResult<Draft>>();
    final form = makeForm(submit: (_) => pending.future);
    final field = form.field(name);
    field.handleChange('Eva');
    final saving = form.handleSubmit();
    await Future<void>.delayed(Duration.zero);
    field.handleChange('Hana');
    pending.complete(const FormSubmitResult.success());
    expect(await saving, isTrue);
    expect(form.values['name'], 'Hana');
    expect(form.state.hasUnsavedChanges, isTrue);
    field.handleChange('Eva');
    expect(form.state.hasUnsavedChanges, isFalse);
  });
  test('rejected write keeps values, server errors and dirty state', () async {
    final form = makeForm(submit: (_) async => FormSubmitResult.invalid(FormErrors.messages({'name': 'Rejected'})));
    form.field(name).handleChange('Eva');
    expect(await form.handleSubmit(), isFalse);
    expect(form.state.hasUnsavedChanges, isTrue);
    expect(form.state.fieldErrors['name']!.single.message, 'Rejected');
  });
  test('transport errors remain separate and are not retried', () async {
    var calls = 0;
    final form = makeForm(
      submit: (_) async {
        calls++;
        throw StateError('offline');
      },
    );
    form.field(name).handleChange('Eva');
    expect(await form.handleSubmit(), isFalse);
    expect(form.state.status, FormSubmissionStatus.error);
    expect(form.state.error, isA<StateError>());
    expect(form.state.fieldErrors, isEmpty);
    expect(calls, 1);
  });
  test('uncertain mutation prevents repeat submission until acknowledged', () async {
    var calls = 0;
    final form = makeForm(
      submit: (_) async {
        calls++;
        return const FormSubmitResult.uncertain();
      },
    );
    expect(await form.handleSubmit(), isFalse);
    expect(await form.handleSubmit(), isFalse);
    expect(form.state.shouldBlockNavigation, isTrue);
    expect(calls, 1);
    form.allowRetry();
    await form.handleSubmit();
    expect(calls, 2);
  });
  test('stale async validation does not overwrite newer results', () async {
    final pending = Completer<FormErrors?>();
    final form = makeForm(
      validators: FormValidators(
        onChangeAsync: (context) => context.value['name'] == 'Eva' ? pending.future : Future.value(null),
      ),
    );
    final field = form.field(name);
    field.handleChange('Eva');
    await Future<void>.delayed(Duration.zero);
    field.handleChange('Hana');
    await Future<void>.delayed(Duration.zero);
    pending.complete(FormErrors.messages({'name': 'Old error'}));
    await Future<void>.delayed(Duration.zero);
    expect(form.state.fieldErrors, isEmpty);
    expect(form.state.isValidating, isFalse);
  });
  test('debounce cancellation prevents old requests and cancels signals', () async {
    var calls = 0;
    final form = makeForm(
      validators: FormValidators(
        asyncDebounce: const Duration(milliseconds: 10),
        onChangeAsync: (_) async {
          calls++;
          return null;
        },
      ),
    );
    final field = form.field(name);
    field.handleChange('Eva');
    field.handleChange('Hana');
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(calls, 1);
    field.handleChange('Iva');
    form.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(calls, 1);
  });
  test('reset invalidates pending validation and restores pristine values', () async {
    final pending = Completer<FormErrors?>();
    final form = makeForm(validators: FormValidators(onChangeAsync: (_) => pending.future));
    form.field(name).handleChange('Eva');
    await Future<void>.delayed(Duration.zero);
    form.reset();
    pending.complete(FormErrors.messages({'name': 'Old error'}));
    await Future<void>.delayed(Duration.zero);
    expect(form.values, defaults);
    expect(form.state.isPristine, isTrue);
    expect(form.state.fieldErrors, isEmpty);
  });
  test('late submit cannot overwrite explicitly reset values', () async {
    final pending = Completer<FormSubmitResult<Draft>>();
    final form = makeForm(submit: (_) => pending.future);
    final saving = form.handleSubmit();
    await Future<void>.delayed(Duration.zero);
    form.reset({'name': 'New record', 'email': ''});
    pending.complete(const FormSubmitResult.success(acceptedValues: defaults));
    expect(await saving, isFalse);
    expect(form.values['name'], 'New record');
    expect(form.state.isPristine, isTrue);
  });
  test('mutable models use copies for submitted and accepted baselines', () async {
    final form = FormController(
      FormOptions<Draft>(
        defaultValues: Map.of(defaults),
        copy: Map.of,
        onSubmit: (_) async => const FormSubmitResult.success(),
      ),
    );
    final changed = Map.of(form.values)..['name'] = 'Eva';
    form.setValues(changed, changedFields: {'name'}, validate: false);
    changed['name'] = 'External mutation';
    expect(form.values['name'], 'Eva');
    expect(form.state.hasUnsavedChanges, isTrue);
    await form.handleSubmit();
    expect(form.state.hasUnsavedChanges, isFalse);
  });
  test('SSR controller starts no validation or writes', () async {
    var calls = 0;
    final form = FormController(
      FormOptions(
        defaultValues: '',
        onSubmit: (_) async {
          calls++;
          return const FormSubmitResult.success();
        },
      ),
      allowExecution: false,
    );
    expect(await form.handleSubmit(), isFalse);
    expect(calls, 0);
  });
  test('autosave serializes writes and saves a newer revision afterwards', () async {
    final pending = Completer<FormSubmitResult<Draft>>();
    var calls = 0;
    final form = makeForm(
      submit: (_) async {
        calls++;
        return calls == 1 ? pending.future : const FormSubmitResult.success();
      },
    );
    final auto = FormAutosave(form, debounce: const Duration(milliseconds: 5));
    addTearDown(auto.dispose);
    form.field(name).handleChange('Eva');
    await Future<void>.delayed(const Duration(milliseconds: 15));
    form.field(name).handleChange('Hana');
    await Future<void>.delayed(const Duration(milliseconds: 15));
    expect(calls, 1);
    pending.complete(const FormSubmitResult.success());
    await Future<void>.delayed(const Duration(milliseconds: 25));
    expect(calls, 2);
    expect(form.state.hasUnsavedChanges, isFalse);
  });
  test('autosave does not loop on failure and disposal cancels pending save', () async {
    var calls = 0;
    final form = makeForm(
      submit: (_) async {
        calls++;
        throw StateError('offline');
      },
    );
    final auto = FormAutosave(form, debounce: const Duration(milliseconds: 5));
    form.field(name).handleChange('Eva');
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(calls, 1);
    expect(auto.hasPending, isTrue);
    form.field(name).handleChange('Hana');
    auto.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 15));
    expect(calls, 1);
  });
}
