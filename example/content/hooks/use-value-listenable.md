---
title: useValueListenable
description: Subscribe to a ValueListenable and return its current value.
---

## What it does

`useValueListenable<T>(valueListenable)` rebuilds on client notifications and returns `.value` for concise render code.

The source can be owned by `useValueNotifier`, supplied by a parent, or managed by an application service. Replacing it moves the subscription.

## Usage

```dart
class StatusText extends HookComponent {
  const StatusText(this.status, {super.key});
  final ValueListenable<String> status;

  @override
  Component build(BuildContext context) {
    final value = useValueListenable(status);
    return text(value);
  }
}
```

## Live demo

<HookDemo name="useValueListenable"/>

## Server rendering

The current `.value` is read during SSR, but no listener is attached until the client. Synchronize external state so server and hydration values match.

## Related APIs

Use `useListenableSelector` to derive and compare a subset. `useValueNotifier` provides automatic ownership and disposal.

