---
title: useOnMediaQueryChange
description: Run a callback after an arbitrary media-query result changes.
---

## What it does

`useOnMediaQueryChange` watches a CSS media query and invokes the latest callback with its previous and current result after a genuine browser-side transition.

## Signature and parameters

```dart
void useOnMediaQueryChange(
  String query,
  MediaQueryCallback callback,
)
```

`query` is passed to the browser media-query API. `callback` receives `(MediaQueryMatch previous, MediaQueryMatch current)`. The hook returns nothing and changing the query establishes a new baseline.

## Usage

```dart
useOnMediaQueryChange('(pointer: coarse)', (previous, current) {
  analytics.record('pointer', current.name);
});
```

## Live demo

<HookDemo name="useOnMediaQueryChange"/>

## Ownership and lifecycle

The hook owns and cleans its media-query listener. Updating only the callback keeps the subscription and uses the latest closure. Updating the query replaces the listener without reporting the new query's initial value as a change.

## Server rendering

No browser listener is attached on the server. The first post-frame client read creates a baseline and does not invoke the callback.

## Common mistakes

Use `useMediaQuery` when the value belongs in rendered output; callbacks do not automatically rebuild. Avoid performing expensive work on every transition without throttling or cancellation.

## Related APIs

`useMediaQuery` returns the renderable value. `useOnPreferredMotionChange` and `useOnPreferredColorSchemeChange` provide typed preference callbacks.
