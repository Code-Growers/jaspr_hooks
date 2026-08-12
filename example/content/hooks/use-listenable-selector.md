---
title: useListenableSelector
description: Rebuild only when a selected Listenable value changes.
---

## What it does

`useListenableSelector<R>(listenable, selector)` evaluates a selection and subscribes to the source on the client.

On notification, the component rebuilds only when the new selection differs by `!=`. Keep selectors fast and side-effect free. Replacing either the source or selector updates the stored selection.

## Usage

```dart
class UserName extends HookComponent {
  const UserName(this.model, {super.key});
  final UserModel model;

  @override
  Component build(BuildContext context) {
    final name = useListenableSelector(
      model,
      () => model.displayName,
    );

    return text(name);
  }
}
```

## Live demo

<HookDemo name="useListenableSelector"/>

## Server rendering

The selector runs during SSR, but live listening starts only on the client. The selected initial value must be hydration-compatible.

## Related APIs

Use `useListenable` when every notification matters. Use immutable selected values or equality-aware value objects for predictable filtering.

