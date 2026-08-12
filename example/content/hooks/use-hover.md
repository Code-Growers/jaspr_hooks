---
title: useHover
description: Track whether a pointer hovers a keyed browser element.
---

## What it does

`useHover` reads an element's initial `:hover` state after attachment and rebuilds for pointer enter and leave events.

## Signature and parameters

```dart
bool? useHover(
  GlobalNodeKey<web.Element> target, {
  bool enabled = true,
})
```

`target` comes from `useNodeKey`. Passing `enabled: false` detaches observation and resets the return value to `null`. Otherwise the result becomes `true` or `false` after attachment when supported.

## Usage

```dart
import 'package:jaspr_hooks/web.dart';
import 'package:universal_web/web.dart' as web;

final card = useNodeKey<web.Element>();
final hovered = useHover(card);

return div(key: card, [Component.text(hovered == true ? 'Hovered' : 'Card')]);
```

## Live demo

<HookDemo name="useHover"/>

## Ownership and lifecycle

The hook owns pointer-enter and pointer-leave listeners. A target, enabled-state, or attached-node change clears the value and reconnects. Unmount removes both listeners.

## Server rendering

The result is `null` during SSR and before browser attachment. Touch-only or unsupported environments may not produce a meaningful hover state, so render a functional fallback.

## Common mistakes

Do not hide essential controls or information behind hover alone. CSS `:hover` is preferable for styling-only behavior. Pass `enabled` rather than conditionally changing hook order.

## Related APIs

Use `useNodeKey` for the element, `useEventListener` for other pointer events, and `useOnClickOutside` for dismissal behavior.
