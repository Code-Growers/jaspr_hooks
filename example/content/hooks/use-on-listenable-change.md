---
title: useOnListenableChange
description: Invoke the latest callback whenever a Listenable notifies.
---

## What it does

`useOnListenableChange(listenable, listener)` attaches a client listener without rebuilding automatically.

The subscription follows a changed listenable. The current callback is invoked, so updating captured inputs does not require removing and adding the listener.

## Signature and parameters

```dart
void useOnListenableChange(
  Listenable? listenable,
  VoidCallback listener,
)
```

`listenable` may be null and remains caller-owned. `listener` runs for notifications; the hook returns nothing.

## Usage

```dart
class AnalyticsBridge extends HookComponent {
  const AnalyticsBridge(this.model, {super.key});
  final CartModel model;

  @override
  Component build(BuildContext context) {
    useOnListenableChange(
      model,
      () => analytics.recordCartSize(model.items.length),
    );

    return text('Cart analytics active');
  }
}
```

## Live demo

<HookDemo name="useOnListenableChange"/>

## Ownership and lifecycle

The hook owns only the client subscription. It moves the listener when the source changes, reads the latest callback from preserved configuration, and never disposes the source.

## Server rendering

No listener is attached on the server. Keep the server-rendered component independent of callbacks that only begin after hydration.

## Common mistakes

The callback does not automatically rebuild the component; update reactive state explicitly if UI must change. Avoid mutating the source in a way that synchronously creates a notification loop.

## Related APIs

Use `useListenable` when notifications should rebuild UI. Use `useEffect` for listener APIs that do not implement Jaspr `Listenable`.
