---
title: usePrevious
description: Read the value supplied to the same hook during the preceding build.
---

## What it does

`usePrevious<T>(value)` returns `null` on the first build and the previous input after subsequent builds.

It records build-to-build history without scheduling rebuilds of its own. Nullable `T` can make the initial state ambiguous; wrap the value in a record or sentinel when that distinction matters.

## Signature and parameters

```dart
T? usePrevious<T>(T value)
```

`value` is recorded after each build. The return is the preceding input or `null` on the first build.

## Usage

```dart
class Delta extends HookComponent {
  const Delta(this.value, {super.key});
  final int value;

  @override
  Component build(BuildContext context) {
    final previous = usePrevious(value);
    final delta = previous == null ? 0 : value - previous;

    return text('Delta: $delta');
  }
}
```

## Live demo

<HookDemo name="usePrevious"/>

## Ownership and lifecycle

The hook owns one previous-value slot and does not own or dispose the value itself. Recording a new input does not request an additional rebuild.

## Server rendering

The first server build has no previous value. Do not assume the server render history will be transferred to a separately initialized client runtime.

## Common mistakes

Do not use the nullable result as an unambiguous first-build flag when `T` itself may be nullable. The value updates only when the containing component builds; it does not subscribe to mutable objects.

## Related APIs

Use `useValueChanged` to compute and retain a result only when the value changes. Use `useRef` for longer mutable history.
