---
title: useDocumentVisibility
description: Track whether the browser document is visible or hidden.
---

## What it does

`useDocumentVisibility()` returns `unknown`, `visible`, or `hidden` and rebuilds when the browser visibility state changes.

The hook waits until after the first client frame to read `document.visibilityState`, preserving deterministic hydration. Use it to pause animation, polling, or nonessential work.

## Usage

```dart
class VisibilityBadge extends HookComponent {
  const VisibilityBadge({super.key});

  @override
  Component build(BuildContext context) {
    final visibility = useDocumentVisibility();
    return text('Document: ${visibility.name}');
  }
}
```

## Live demo

<HookDemo name="useDocumentVisibility"/>

## Server rendering

The value is `DocumentVisibility.unknown` during SSR and the first hydration build. It synchronizes after that frame.

## Related APIs

Use `useOnDocumentVisibilityChange` when changes should call imperative logic rather than render a value.

