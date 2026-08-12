---
title: useDocumentVisibility
description: Track whether the browser document is visible or hidden.
---

## What it does

`useDocumentVisibility()` returns `unknown`, `visible`, or `hidden` and rebuilds when the browser visibility state changes.

The hook waits until after the first client frame to read `document.visibilityState`, preserving deterministic hydration. Use it to pause animation, polling, or nonessential work.

## Signature and return type

```dart
DocumentVisibility useDocumentVisibility()
```

The hook takes no parameters and returns `unknown`, `visible`, or `hidden`.

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

## Ownership and lifecycle

The hook owns its browser visibility listener and removes it on disposal. Initial synchronization and later distinct changes update the returned enum and rebuild the host.

## Server rendering

The value is `DocumentVisibility.unknown` during SSR and the first hydration build. It synchronizes after that frame.

## Common mistakes

Treat `unknown` as a supported state and do not read `document` directly during initial render to bypass it. Visibility is a scheduling hint, not proof that the page is onscreen or actively used.

## Related APIs

Use `useOnDocumentVisibilityChange` when changes should call imperative logic rather than render a value.
