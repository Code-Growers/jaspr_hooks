---
title: useListenable
description: Rebuild when a Jaspr Listenable notifies.
---

## What it does

`useListenable(listenable)` returns the same object and subscribes the current hook component to notifications on the client.

Changing the listenable moves the listener to the new object. A nullable listenable is accepted, which is useful while a source is unavailable. Notifications always request a rebuild.

## Usage

```dart
class ModelView extends HookComponent {
  const ModelView(this.model, {super.key});
  final CounterModel model;

  @override
  Component build(BuildContext context) {
    useListenable(model);
    return text('Count: ${model.count}');
  }
}
```

## Live demo

<HookDemo name="useListenable"/>

## Server rendering

No listener is attached during server rendering, but the current model can still be read to produce markup. Ensure its initial value agrees with hydration data.

## Related APIs

Use `useListenableSelector` to skip rebuilds when an unrelated part changes. `useValueListenable` returns the current typed value directly.

