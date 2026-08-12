---
title: useStreamController
description: Own a broadcast StreamController and close it automatically.
---

## What it does

`useStreamController<T>` creates a broadcast controller, supports synchronous delivery and listener callbacks, and closes it on hook disposal.

Use `keys` to replace the controller when resource identity changes. Updated `onListen` and `onCancel` callbacks are installed without recreating a preserved controller.

## Usage

```dart
class EventSource extends HookComponent {
  const EventSource({super.key});

  @override
  Component build(BuildContext context) {
    final controller = useStreamController<String>(sync: true);
    final snapshot = useStream(
      context.binding.isClient ? controller.stream : null,
      initialData: 'none',
    );

    return button(
      onClick: () => controller.add('clicked'),
      [text('Latest: ${snapshot.data}')],
    );
  }
}
```

## Live demo

<HookDemo name="useStreamController"/>

## Server rendering

The controller itself can be created on the server, but do not pass its non-null stream to `useStream` or `useOnStreamChange` during SSR.

## Related APIs

Use `useStream` to render its events or `useOnStreamChange` to invoke callbacks. Prefer an application service when the stream must outlive the component.

