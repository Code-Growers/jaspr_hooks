---
title: useElementSize
description: Observe the rendered size of a keyed browser element.
---

## What it does

`useElementSize` attaches a `ResizeObserver` to a keyed element and rebuilds with its latest width and height in CSS pixels.

## Signature and parameters

```dart
ElementSize? useElementSize(
  GlobalNodeKey<web.Element> target, {
  ResizeObserverBox box = ResizeObserverBox.contentBox,
})
```

`target` comes from `useNodeKey`. `box` selects content, border, or device-pixel content measurement. The nullable return exposes `width` and `height` after observation begins.

## Usage

```dart
import 'package:jaspr_hooks/web.dart';
import 'package:universal_web/web.dart' as web;

final target = useNodeKey<web.Element>();
final size = useElementSize(target, box: ResizeObserverBox.borderBox);

return div(key: target, [
  Component.text(size == null ? 'Measuring…' : '${size.width} × ${size.height}'),
]);
```

## Live demo

<HookDemo name="useElementSize"/>

## Ownership and lifecycle

The hook owns and disconnects its observer. Changing the key, box, or attached node resets the value to `null` and observes the replacement. Unsupported observers leave the value `null`.

## Server rendering

The return value is `null` during SSR and initial hydration. Attachment occurs after a client frame, so server markup should include a stable fallback.

## Common mistakes

Do not synchronously resize the observed element from every measurement without guarding against feedback loops. Device-pixel content boxes are not supported by every browser. Prefer CSS container queries for styling-only decisions.

## Related APIs

Use `useNodeKey` to create the target, `useWindowSize` for the viewport, and `useMutationObserver` for DOM structure rather than geometry.
