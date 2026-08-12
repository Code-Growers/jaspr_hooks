---
title: useUnmount
description: Run the latest callback when a browser-client hook is removed.
---

## What it does

`useUnmount` registers teardown-only behavior. The callback does not run during build; the latest callback supplied by the most recent build runs when the client hook is disposed.

## Signature and parameters

```dart
void useUnmount(VoidCallback effect)
```

`effect` is kept in a stable reference and invoked synchronously at disposal. The hook returns nothing.

## Usage

```dart
useUnmount(() {
  draftStore.release(documentId);
});
```

## Live demo

<HookDemo name="useUnmount"/>

## Ownership and lifecycle

The callback registration belongs to the hook. It runs exactly when the client effect cleanup runs, using current captured data. Other hook cleanup continues if it throws because the runtime isolates cleanup failures.

## Server rendering

The callback is not registered or invoked during server/static rendering. Do not rely on it for server request cleanup; use the server framework's lifecycle instead.

## Common mistakes

Prefer an effect that creates and cleans up a resource in one place when possible. Avoid triggering ordinary UI state changes during teardown, and make cleanup tolerant of partially released resources.

## Related APIs

`useEffectOnce` colocates setup and cleanup, `useMount` is setup-only, and `useDisposable` owns universal resource cleanup.
