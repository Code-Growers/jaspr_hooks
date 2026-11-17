---
title: useForm
description: Own typed draft values, validation and submission state.
---

Own typed draft values, validation and submission state.

<HookDemo name="useForm"/>

## Signature and usage

```dart
import 'package:jaspr_hooks/form.dart';

final form = useForm(FormOptions<String>(defaultValues: '', onSubmit: (context) async {
  await saveName(context.value);
  return const FormSubmitResult.success();
}), keys: [recordId]);
```

## Ownership and lifecycle

The owning hook disposes subscriptions, validation signals and pending timers on unmount.
Use stable keys for a record identity; rebuilds update callbacks without resetting edits.
Explicitly reset after loading a different record. Keep request/cache operations in Query.

## State and errors

`isDirty` records whether the user changed values since reset; `hasUnsavedChanges`
compares current values with the last confirmed save. Reverting an edit clears unsaved
state while dirty remains true. Field errors retain their onChange, onBlur, onSubmit
and onServer source. Keep unknown API violations in the form summary.

## Server rendering

Initial values and selected snapshots render on the server. Effects, network
submissions, validation and autosave do not execute there. Browser navigation
listeners belong to the app adapter, not the portable form module.

## Common mistakes

Do not mutate draft objects without a copy strategy. Do not reset from every query
refresh or mark newer edits as saved when an older request completes. Handle invalid
and uncertain writes explicitly. Autosave does not automatically retry failures.
Navigation must use the unsaved baseline and pending/uncertain state, not sticky dirty.

## Related APIs

See the [form guide](forms) for full signatures, typed field lenses, asynchronous
validators, error mapping, autosave and routing responsibilities.
