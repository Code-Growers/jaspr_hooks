---
title: useOnListenableChange
description: Invoke the latest callback whenever a Listenable notifies.
---

## What it does

`useOnListenableChange(listenable, listener)` attaches a client listener without rebuilding automatically.

The subscription follows a changed listenable. The current callback is invoked, so updating captured inputs does not require removing and adding the listener.

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

## Server rendering

No listener is attached on the server. Keep the server-rendered component independent of callbacks that only begin after hydration.

## Related APIs

Use `useListenable` when notifications should rebuild UI. Use `useEffect` for listener APIs that do not implement Jaspr `Listenable`.

