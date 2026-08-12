---
title: useEventListener
description: Own a typed native DOM event listener.
---

## What it does

`useEventListener` attaches one native event listener after rendering and invokes the latest supplied callback. It defaults to the browser window but can resolve any `EventTarget`, including a node from `useNodeKey`.

## Signature and parameters

```dart
void useEventListener<E extends web.Event>(
  String type,
  void Function(E event) listener, {
  WebEventTargetResolver? target,
  bool enabled = true,
  WebEventListenerOptions options = const WebEventListenerOptions(),
})
```

`type` must be non-empty. `target` is resolved after a frame; options provide `capture`, `passive`, and `once`. The generic `E` controls the callback cast. The hook returns nothing.

## Usage

```dart
import 'package:jaspr_hooks/web.dart';
import 'package:universal_web/web.dart' as web;

useEventListener<web.KeyboardEvent>('keydown', (event) {
  if (event.key == 'Escape') closeDialog();
});
```

## Live demo

<HookDemo name="useEventListener"/>

## Ownership and lifecycle

The hook owns listener registration and removes it when type, resolved target, enabled state, options, or the hook lifetime changes. Callback-only updates do not reconnect. Listener and resolver errors are reported through the hook runtime.

## Server rendering

No target is resolved and no listener is attached during SSR. Registration starts after the first browser frame.

## Common mistakes

Ensure `E` matches the actual event type or the runtime cast can fail. A passive listener must not call `preventDefault`. Pass `enabled: false` instead of conditionally skipping the hook.

## Related APIs

`useOnClickOutside` specializes pointer capture, `useHover` owns pointer enter/leave state, and `useNodeKey` supplies element targets.
