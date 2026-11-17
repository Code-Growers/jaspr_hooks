import 'package:jaspr/jaspr.dart';
import 'package:jaspr_hooks/form.dart';
import 'package:jaspr_hooks/hooks.dart';
import 'package:jaspr_test/server_test.dart';

import 'support/harness.dart';

void main() {
  testComponents('useForm and useField rebuild field and selector consumers without replacing drafts', (tester) async {
    final harness = TestHarnessController();
    late FormController<String> form;
    late FieldController<String, String> field;
    var defaults = 'Alena';
    final guard = FormNavigationGuard();
    tester.pumpComponent(
      TestHarness(
        controller: harness,
        builder: () => HookBuilder(
          builder: (_) {
            form = useForm(FormOptions(defaultValues: defaults));
            field = useField(form, FormFieldKey('name', read: (v) => v, write: (_, v) => v));
            final dirty = useFormState(form, (state) => state.hasUnsavedChanges);
            useFormNavigationGuard(guard, () => form.state.shouldBlockNavigation);
            return Component.text('${field.value}:$dirty');
          },
        ),
      ),
    );
    await tester.pump();
    field.handleChange('Eva');
    await tester.pump();
    expect(find.text('Eva:true'), findsOneComponent);
    expect(guard.isBlocked, isTrue);
    defaults = 'Server refresh';
    harness.rebuild();
    await tester.pump();
    expect(form.values, 'Eva');
    form.reset('Accepted');
    await tester.pump();
    expect(find.text('Accepted:false'), findsOneComponent);
    harness.unmountChild();
    await tester.pump();
    expect(form.disposed, isTrue);
    expect(guard.isBlocked, isFalse);
  });
  testComponents('useFormAutosave and navigation are inert during SSR', (tester) async {
    var calls = 0;
    final guard = FormNavigationGuard();
    tester.pumpComponent(
      HookBuilder(
        builder: (_) {
          final form = useForm(
            FormOptions(
              defaultValues: '',
              onSubmit: (_) async {
                calls++;
                return const FormSubmitResult.success();
              },
            ),
          );
          useFormAutosave(form);
          useFormNavigationGuard(guard, () => true);
          final value = useFormState(form, (state) => state.values);
          return Component.text('SSR:$value');
        },
      ),
    );
    await tester.pump();
    expect(calls, 0);
    expect(guard.isBlocked, isFalse);
    expect(find.text('SSR:'), findsOneComponent);
  }, isClient: false);
}
