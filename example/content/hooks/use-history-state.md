---
title: useHistoryState
description: Observe and control same-document browser session history.
---

`useHistoryState` exposes the current URI and structured state plus push, replace, back, forward, and go operations.

## Signature

```dart
HistoryController? useHistoryState();
```

## Lifecycle

```dart
final history = useHistoryState();
history?.replace(Uri(path: '/search', queryParameters: {'q': query}));
```

<HookDemo name="useHistoryState"/>

The hook updates synchronously for its own push and replace operations and listens for browser `popstate` navigation.

## Server rendering

The controller is `null` during SSR and first hydration. Server routing remains Jaspr's responsibility.

## Common mistakes

Only pass structured-clone-compatible state. Same-document history does not replace a full application router.

## Related APIs

Use Jaspr routing for route composition and `useEventListener` for unrelated window events.
