---
title: useValueChanged
description: Transform a value when it changes while retaining the prior result.
---

## What it does

`useValueChanged<T, R>(value, callback)` invokes the callback only when `value` differs from the previous build and stores its nullable result.

The callback receives both the old input and the previously stored result. The first build returns `null` because there is no previous input.

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

## Server rendering

The transformation follows the component build sequence on either platform. Ensure it is deterministic and free of browser-only side effects.

## Related APIs

Use `usePrevious` when you only need the old input. Use `useEffect` when a change should perform client-side work rather than calculate render data.

