---
title: useLocation
description: Read the current document location and rebuild when it changes.
---

## What it does

`useLocation()` returns the browser's current `Uri`. It returns `null` during server rendering and the first hydration build, then synchronizes after the first client frame and rebuilds on every later change.

Changes are observed through `popstate`, `hashchange`, `pageshow`, and same-document navigation performed with `useHistoryState`, which fires no native event on its own.

## Signature and return type

```dart
Uri? useLocation()
```

The hook has no parameters. Equal locations do not rebuild.

## Usage

```dart
class ActiveTab extends HookComponent {
  const ActiveTab({super.key});

  @override
  Component build(BuildContext context) {
    final location = useLocation();
    final tab = location?.queryParameters['tab'] ?? 'overview';
    return text('Active tab: $tab');
  }
}
```

## Live demo

<HookDemo name="useLocation"/>

## Ownership and lifecycle

The hook owns its window listeners and removes them on disposal. It reads the location once after the first frame and again on every observed event.

## Server rendering

The hook returns `null` on the server and during the first hydration build so that server and client markup match. Render a deterministic fallback for that state.

## Common mistakes

Native `history.pushState` calls made outside `useHistoryState` are not observed. Route through `HistoryController.push` or `replace`, or dispatch `popstate` yourself.

## Related APIs

Use `useBrowserRoute` to combine a server-supplied route with a client resolver. Use `useHistoryState` to navigate.
