---
title: SSR and hydration
description: Understand deterministic server output and client-only subscriptions in jaspr_hooks.
---

Jaspr creates one component tree while pre-rendering and another while hydrating in the browser. Hook state is local to each tree and is not serialized automatically.

## Client-only effects

`useEffect`, `usePostFrameEffect`, and `useDebounced` stay inactive during server/static rendering. Browser lifecycle hooks return an `unknown` value until their first client frame.

```dart
final visibility = useDocumentVisibility();

useEffect(() {
  // Runs only in the browser.
  analytics.pageVisible(visibility == DocumentVisibility.visible);
  return null;
}, [visibility]);
```

## Async sources must be null on the server

A non-null source passed to `useFuture`, `useStream`, or `useOnStreamChange` during server rendering throws a `StateError` instead of silently creating a server-side subscription.

```dart
final future = useMemoized<Future<User>?>(() {
  return context.binding.isClient ? loadUserInBrowser() : null;
}, const []);

final snapshot = useFuture(future, initialData: serverUser);
```

Use Jaspr preloading, synchronized state, serialized `@client` properties, or `jaspr_riverpod` for data that must appear in server HTML.

## Deterministic initializers

Keep `useState` and `useMemoized` initial values deterministic across server and client builds. Avoid timestamps, random values, and direct browser API reads in initial render output.
