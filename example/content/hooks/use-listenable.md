---
title: useListenable
description: Rebuild when a Jaspr Listenable notifies.
---

## What it does

`useListenable(listenable)` returns the same object and subscribes the current hook component to notifications on the client.

Changing the listenable moves the listener to the new object. A nullable listenable is accepted, which is useful while a source is unavailable. Notifications always request a rebuild.

## Signature and parameters

```dart
T useListenable<T extends Listenable?>(T listenable)
```

The nullable `listenable` is both the subscribed source and the unchanged return value.

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

## Ownership and lifecycle

The caller owns the source. The hook owns only its browser listener, moves it on source replacement, and removes it on disposal. It does not dispose the `Listenable`.

## Server rendering

No listener is attached during server rendering, but the current model can still be read to produce markup. Ensure its initial value agrees with hydration data.

## Common mistakes

Do not expect this hook to expose a value; read the model after subscribing or use `useValueListenable`. Avoid disposing a caller-owned source from the component unless ownership was explicitly transferred.

## Related APIs

Use `useListenableSelector` to skip rebuilds when an unrelated part changes. `useValueListenable` returns the current typed value directly.
