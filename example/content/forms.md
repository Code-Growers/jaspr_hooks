---
title: Forms and validation
description: Typed drafts, field errors, submission state, autosave and unsaved changes.
---

## Three modules, one package

| Import | Responsibility |
| --- | --- |
| `package:jaspr_hooks/hooks.dart` | Component lifecycle, local state, subscriptions and effects |
| `package:jaspr_hooks/query.dart` | Cached server state, mutations, retries, hydration and invalidation |
| `package:jaspr_hooks/form.dart` | Typed drafts, fields, validation, submissions, dirty state and autosave |

The existing `jaspr_hooks.dart` umbrella remains compatible and exports all three.
Forms do not import queries: submit callbacks can call `mutation.mutateAsync`, a
repository, or another asynchronous persistence API.

## Forms, inspired by TanStack Form

The headless native Dart module follows [TanStack Form](https://tanstack.com/form/latest)
concepts and naming. Typed field lenses replace TypeScript deep-key inference.
It has no JavaScript, schema-library, protobuf, router or design-system dependency.

```dart
final form = useForm(FormOptions<String>(
  defaultValues: '',
  onSubmit: (context) async {
    await repository.saveName(context.value);
    return const FormSubmitResult.success();
  },
));
final name = useField(form, FormFieldKey<String, String>(
  'name', read: (value) => value, write: (_, value) => value,
), validators: FieldValidators<String, String>(
  onChange: (value, _) => value.trim().isEmpty
      ? [const FormIssue('Enter a name.', code: 'required')]
      : [],
));
final submitting = useFormState(form, (state) => state.isSubmitting);
// Bind name.value, name.handleChange, name.handleBlur and name.meta.errors
// to existing accessible controls. Submit with form.handleSubmit().
```

- **Typed drafts and fields:** `FormController<T>`, `FormFieldKey<T, V>` and
  `FieldController<T, V>`. Keep partially entered numeric/date text in the draft;
  parse it through domain validation and request mapping.
- **Validation:** field/form `onChange`, `onBlur`, `onSubmit` and async equivalents,
  debounce, linked fields (`listenTo`), cancellation signals and stale-result
  protection. Multiple errors can retain indexed paths and backend rule codes.
- **Error ownership:** `errorMap` separates validation events and server errors.
  Editing one field retains errors on other fields. Put unknown backend paths in
  `FormErrors.form`; transport exceptions remain separate from field validation.
- **Submission:** `handleSubmit` validates, prevents duplicate writes, awaits the
  callback and records failures. Return `.invalid(errors)` for server rejection
  or `.uncertain()` when a write may have committed; `allowRetry()` acknowledges
  uncertainty. Mutations never retry automatically.
- **Baselines:** `isDirty` records edit history; `isDefaultValue` compares with
  defaults. `hasUnsavedChanges` compares against the last confirmed save. Saving
  an older revision never clears edits made in flight. `reset(newValues)` is an
  explicit replacement of the draft and baseline.
- **Subscriptions:** `useForm` owns the controller; `useField` and `useFormState`
  subscribe consumers. Use stable selectors or an equality function for allocated
  selections. Defaults changing on rebuild never replace edited values.
- **Optional autosave:** `useFormAutosave`/`FormAutosave` debounce and serialize
  writes. `canSave` can defer saving while focused; call `flush()` on blur.
  Failed revisions remain dirty and require a new edit or explicit retry.
- **Navigation:** `useFormNavigationGuard` registers a live predicate with the
  router-neutral `FormNavigationGuard`. App adapters cover routes/history,
  browser unload and dialog dismissal using `state.shouldBlockNavigation`.
- **SSR:** form hooks do not submit, validate asynchronously, start autosave or
  register blockers on the server. Subscriptions and timers dispose on unmount.

Use immutable drafts or supply `FormOptions.copy` and `equals`. Backend mapping,
localization, focus management and business validation stay in app adapters;
transport deadlines and cache updates stay in mutations. The following recipes show those boundaries.


## Map server errors without coupling the form to a transport

A submit callback receives a snapshot and revision. Convert your application API's
response to `FormErrors` at this boundary. A known path becomes a field error; an
unknown or cross-field violation belongs in the summary. Keep the original path
and rule code when translating the message.

```dart
return FormSubmitResult.invalid(FormErrors(
  fields: {
    'email': [FormIssue('This email is already used.',
        path: 'customer.email', code: 'unique')],
  },
  form: [FormIssue('Check the customer assignment.',
      path: 'customer.assignment', code: 'invalid')],
));
```

Throw transport failures from the callback; `state.error` retains the exception.
A failed or invalid write never acknowledges the draft. Return
`FormSubmitResult.uncertain()` if the server may have committed a timed-out write;
reconcile with the server before calling `allowRetry()` or `resetValues()`.

## Async validation and linked inputs

```dart
FieldValidators<CustomerDraft, String>(
  onChangeAsync: (email, values, signal) async {
    final available = await repository.isEmailAvailable(email);
    if (signal.isCancelled) return [];
    return available ? [] : [const FormIssue('Email is already used.')];
  },
  asyncDebounce: const Duration(milliseconds: 300),
  listenTo: ['customerType'],
);
```

The form ignores stale results even if the transport cannot cancel its request.
Use `signal.onCancel` when your API supports cancellation. A field's `listenTo`
paths cause its validators to run when a related input changes. Submit validation
runs without the debounce delay. Separate `onChange`, `onBlur`, `onSubmit` and
`onServer` entries remain inspectable in `errorMap`.

## Optional autosave and navigation

```dart
final autosave = useFormAutosave(form,
  debounce: const Duration(milliseconds: 600),
  canSave: () => autosaveEnabled && !editingFocusedField,
);
// Call autosave.flush() when a focus-based deferral ends.
final guard = useMemoized(FormNavigationGuard.new);
useFormNavigationGuard(guard, () => form.state.shouldBlockNavigation);
// The app/router asks guard.canLeave(confirmDiscard) before leaving.
```

Autosave serializes writes and acknowledges only their submitted snapshot.
It does not repeatedly retry a rejected revision. A subsequent edit, explicit
flush or user retry can attempt saving again. For a permanently mounted browser
adapter, register history listeners **before** route observers, which can
synchronously dispose a form and remove its blocker. Cover browser unload and
modal dismissal in the app as well; the portable hook does not install DOM events.

## Reset and field metadata

`reset()` returns to initial defaults, while `resetValues(value)` explicitly
replaces defaults, current values and the accepted baseline. Use `resetValues(null)`
when the draft type is nullable. Reset clears interaction metadata and errors.
`acceptBaseline(submitted)` acknowledges an externally managed save without
replacing newer edits or clearing sticky `isDirty` history.

Fields expose `isTouched`, `isBlurred`, `isDirty`, `isPristine`, `isDefaultValue`,
`hasUnsavedChanges`, `isValidating`, `isValid` and source-specific `errorMap`.
`useFormState` supports selectors and custom equality. `useField` subscribes its
consumer to form changes; it does not promise per-field render isolation.

Keep submit buttons available when a field is invalid so a user can request full
validation and focus feedback. Disable them during `state.isSubmitting`; rendering
an async-validation spinner should not swallow a click triggered by field blur.
