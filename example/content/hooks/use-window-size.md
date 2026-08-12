---
title: useWindowSize
description: Track the browser viewport size with optional resize debouncing.
---

## What it does

`useWindowSize` returns the latest browser viewport width and height and rebuilds after resize events. It is intended for behavior that genuinely needs numeric viewport dimensions.

## Signature and parameters

```dart
WindowSize? useWindowSize([
  WindowSizeOptions options = const WindowSizeOptions(),
])
```

`WindowSizeOptions(debounce: duration)` optionally delays updates until resize events settle. A negative duration throws `ArgumentError`. The nullable result contains `width` and `height` in CSS pixels.

## Usage

```dart
import 'package:jaspr_hooks/web.dart';

final viewport = useWindowSize(
  const WindowSizeOptions(debounce: Duration(milliseconds: 100)),
);

return text(viewport == null ? 'Viewport unavailable' : '${viewport.width}px wide');
```

## Live demo

<HookDemo name="useWindowSize"/>

## Ownership and lifecycle

The hook owns the window listener and any pending debounce timer. Changing options resets the value and reconnects; disposal removes the listener and cancels delayed work.

## Server rendering

It returns `null` during SSR and the first hydration build, then reads the viewport after the first client frame. Browsers without an available window keep the fallback.

## Common mistakes

Prefer responsive CSS for layout and avoid producing radically different initial markup from a post-hydration size. Debounce high-frequency work, but remember that a delayed value is intentionally stale during resize.

## Related APIs

Use `useMediaQuery` for breakpoint booleans and `useElementSize` for the size of a particular element.
