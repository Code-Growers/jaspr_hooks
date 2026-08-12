---
title: useValueChanged
description: Transform a value when it changes while retaining the prior result.
---

## What it does

`useValueChanged<T, R>(value, callback)` invokes the callback only when `value` differs from the previous build and stores its nullable result.

The callback receives both the old input and the previously stored result. The first build returns `null` because there is no previous input.

## Signature and parameters

```dart
R? useValueChanged<T, R>(
  T value,
  R? Function(T oldValue, R? oldResult) valueChange,
)
```

`value` is compared with the previous input. On a change, `valueChange` receives the old input and result; the nullable retained `R` is returned.

## Usage

```dart
class ChangeLabel extends HookComponent {
  const ChangeLabel(this.value, {super.key});
  final int value;

  @override
  Component build(BuildContext context) {
    final label = useValueChanged<int, String>(
      value,
      (oldValue, oldLabel) => 'Changed from $oldValue',
    );

    return text(label ?? 'First value: $value');
  }
}
```

## Live demo

<HookDemo name="useValueChanged"/>

## Ownership and lifecycle

The hook owns its previous input and result slots but not the supplied values. It performs the transformation during build and does not request a separate rebuild.

## Server rendering

The transformation follows the component build sequence on either platform. Ensure it is deterministic and free of browser-only side effects.

## Common mistakes

Do not perform effects inside `valueChange`; use `useEffect` for client work. A nullable result cannot by itself distinguish the first build from a callback that returned `null`.

## Related APIs

Use `usePrevious` when you only need the old input. Use `useEffect` when a change should perform client-side work rather than calculate render data.
