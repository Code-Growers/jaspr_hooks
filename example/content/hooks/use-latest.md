---
title: useLatest
description: Keep the newest value in a stable reference without rebuilding.
---

## What it does

`useLatest` returns one stable `ObjectRef<T>` whose `value` is refreshed during every build. Updating the cell does not schedule another build, so it is useful when a long-lived callback must read current props or state without being recreated.

## Signature and parameters

```dart
ObjectRef<T> useLatest<T>(T value)
```

`value` is copied into the reference on every build. The return type is the hook-owned `ObjectRef<T>`; its identity remains stable at the same hook position.

## Usage

```dart
final latestQuery = useLatest(query);

useTimeout(() {
  analytics.recordSearch(latestQuery.value);
}, const Duration(seconds: 1));
```

## Live demo

<HookDemo name="useLatest"/>

## Ownership and lifecycle

The hook owns only the reference, not the supplied value. The cell is updated synchronously during build and discarded with the hook state. Mutating `latest.value` manually is allowed but will be overwritten by the next build.

## Server rendering

`useLatest` works during server and client builds. Use deterministic values when the reference influences rendered output; the server reference is independent from the client reference.

## Common mistakes

Do not use it for values that should redraw the UI because changing the reference does not rebuild. Prefer `useState` for render state. Do not capture `latest.value` before an asynchronous boundary; read it when the callback actually runs.

## Related APIs

Use `useRef` when the application, rather than the hook, should mutate the cell. `useCallback`, `useTimeout`, `useInterval`, and subscription hooks commonly pair with `useLatest`.
