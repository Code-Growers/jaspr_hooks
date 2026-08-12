---
title: useOnClickOutside
description: Run a callback for pointer presses outside keyed elements.
---

## What it does

`useOnClickOutside` listens for captured `pointerdown` events and invokes a callback when the event's composed path contains none of the supplied keyed elements. It handles shadow-DOM event paths and optional related regions.

## Signature and parameters

```dart
void useOnClickOutside(
  GlobalNodeKey<web.Element> target,
  void Function(web.PointerEvent event) listener, {
  List<GlobalNodeKey<web.Element>> additionalTargets = const [],
  bool enabled = true,
})
```

`target` is the primary inside region. `additionalTargets` treats other keyed elements as inside, and `enabled` controls registration. The hook returns nothing.

## Usage

```dart
import 'package:jaspr_hooks/web.dart';
import 'package:universal_web/web.dart' as web;

final panel = useNodeKey<web.Element>();
useOnClickOutside(panel, (_) => open.value = false, enabled: open.value);

return div(key: panel, [Component.text('Menu')]);
```

## Live demo

<HookDemo name="useOnClickOutside"/>

## Ownership and lifecycle

The hook delegates to an owned window event listener in capture mode. It uses current keyed nodes and the latest callback. If no target node is attached, outside events are ignored rather than treating the whole page as outside.

## Server rendering

No pointer listener is attached during SSR or before the first client frame. Keep visibility and open state deterministic for hydration.

## Common mistakes

Include portals, popovers, or trigger buttons in `additionalTargets` when clicks there should remain inside. Preserve keyboard accessibility—outside pointer handling does not replace Escape handling or focus management.

## Related APIs

Use `useNodeKey` for every region, `useEventListener` for keyboard dismissal, and `useHover` for non-committing pointer presence.
