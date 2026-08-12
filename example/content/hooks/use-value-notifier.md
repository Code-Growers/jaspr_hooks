---
title: useValueNotifier
description: Own and dispose a ValueNotifier without automatically subscribing.
---

## What it does

`useValueNotifier<T>(initialData, [keys])` creates a stable notifier and disposes it when the hook is removed or its keys replace the state.

Unlike `useState`, assigning `.value` does not rebuild the owner unless another hook subscribes. This is useful when the notifier is passed to a child or observed selectively.

## Signature and parameters

```dart
ValueNotifier<T> useValueNotifier<T>(
  T initialData, [
  List<Object?>? keys,
])
```

`initialData` seeds each created notifier and nullable ordered `keys` control replacement. The return is an owned `ValueNotifier<T>` without an automatic owner subscription.

## Usage

```dart
class SharedCounter extends HookComponent {
  const SharedCounter({super.key});

  @override
  Component build(BuildContext context) {
    final counter = useValueNotifier(0);
    final value = useValueListenable(counter);

    return button(
      onClick: () => counter.value++,
      [text('Count: $value')],
    );
  }
}
```

## Live demo

<HookDemo name="useValueNotifier"/>

## Ownership and lifecycle

The hook owns and disposes the notifier on keyed replacement or unmount. Consumers must not dispose it. With preserved keys, later `initialData` changes do not overwrite its value.

## Server rendering

The notifier exists during SSR and can provide an initial value. Live notifications are client-side once observed by a listenable hook.

## Common mistakes

Changing `.value` alone does not rebuild the owner; pair it with `useValueListenable` or a selector when needed. Do not manually dispose the returned notifier.

## Related APIs

Use `useState` for the common owned-and-subscribed case. Pair with `useValueListenable` or `useListenableSelector` when selective observation is needed.
