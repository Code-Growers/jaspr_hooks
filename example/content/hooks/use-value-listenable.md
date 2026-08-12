---
title: useValueListenable
description: Subscribe to a ValueListenable and return its current value.
---

## What it does

`useValueListenable<T>(valueListenable)` rebuilds on client notifications and returns `.value` for concise render code.

The source can be owned by `useValueNotifier`, supplied by a parent, or managed by an application service. Replacing it moves the subscription.

## Signature and parameters

```dart
T useValueListenable<T>(ValueListenable<T> valueListenable)
```

`valueListenable` remains caller-owned. The hook returns its current typed `.value`.

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

## Ownership and lifecycle

The hook owns only its browser listener, moves it when the source changes, and removes it on disposal. It never disposes the supplied `ValueListenable`.

## Server rendering

The current `.value` is read during SSR, but no listener is attached until the client. Synchronize external state so server and hydration values match.

## Common mistakes

Do not dispose a parent- or service-owned source from this component. If only part of a larger model matters, use `useListenableSelector` to filter unrelated notifications.

## Related APIs

Use `useListenableSelector` to derive and compare a subset. `useValueNotifier` provides automatic ownership and disposal.
