---
title: SSR and hydration
description: Understand deterministic server output and client-only subscriptions in jaspr_hooks.
---

Jaspr creates one component tree while pre-rendering and another while hydrating in the browser. Hook state is local to each tree and is not serialized automatically.

## Client-only effects

`useEffect`, `usePostFrameEffect`, `useEffectOnce`, `useMount`, `useUnmount`, `useUpdateEffect`, `useTimeout`, `useInterval`, and `useDebounced` stay inactive during server/static rendering. Browser lifecycle hooks return an `unknown` value until their first client frame.

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

## External stores

`useExternalStore` reads `getServerSnapshot` during SSR when you supply it and falls back to `getSnapshot` otherwise, without subscribing. Supply `getServerSnapshot` in the browser as well to preserve that exact value through the first hydration build. The hook attaches the live subscription and switches to `getSnapshot` after the first frame.

```dart
final session = useExternalStore<SessionSnapshot>(
  sessionStore.subscribe,
  sessionStore.snapshot,
  getServerSnapshot: () => serializedSession,
);
```

Snapshots should be immutable. Server and client code must agree on equality and on the meaning of the serialized baseline.

## Actions and local controllers

`useAsyncAction` and `useOptimistic` expose their deterministic initial or authoritative state during SSR. `AsyncAction.dispatch` and optimistic mutation methods throw there. Dispatch, add, commit, rollback, and reset from browser event handlers rather than during build.

Convenience controllers such as `useToggle`, `useCounter`, `useList`, `useMap`, `useSet`, and `useQueue` initialize universally. Their server instance is not transferred to the browser. The same applies to references, inherited dependencies, imperative handles, reducers, and resources created by `useDisposable`.

## Browser DOM hooks

DOM integration lives in `package:jaspr_hooks/web.dart`. `useNodeKey` can create a stable key on the server, but its node is unattached. `useElementSize`, `useWindowSize`, `useIntersection`, `useHover`, `useFocusWithin`, `useActiveElement`, `useAbortController`, and `useHistoryState` return `null` until client attachment. `useFocus` returns an unattached controller, `useClipboard` returns an unsupported controller, and event, observer, and animation-frame hooks attach nothing on the server.

Keep a deterministic fallback in the initial markup:

```dart
final viewport = useWindowSize();
return text(viewport == null ? 'Viewport unavailable' : '${viewport.width}px');
```

Prefer CSS for visual-only responsive behavior. Use `useMediaQuery` when application behavior needs a query value; it returns `MediaQueryMatch.unknown` through the first hydration build.

## Deterministic initializers

Keep `useState` and `useMemoized` initial values deterministic across server and client builds. Avoid timestamps, random values, and direct browser API reads in initial render output.
