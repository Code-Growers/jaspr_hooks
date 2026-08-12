---
title: useExternalStore
description: Read immutable snapshots from an arbitrary external store.
---

## What it does

`useExternalStore` reads a snapshot, subscribes to store notifications in the browser, and rebuilds only when the next snapshot differs. It supports state libraries and application stores that do not implement Jaspr's `Listenable` interface.

## Signature and parameters

```dart
T useExternalStore<T>(
  ExternalStoreSubscribe subscribe,
  T Function() getSnapshot, {
  T Function()? getServerSnapshot,
  ExternalStoreSnapshotEquals<T>? equals,
})
```

`subscribe(notify)` must return a synchronous unsubscribe callback. `getSnapshot` returns the current immutable value. `getServerSnapshot` supplies deterministic SSR and hydration data, while `equals` optionally controls change detection. The hook returns the latest `T`.

## Usage

```dart
final cart = useExternalStore<CartSnapshot>(
  cartStore.subscribe,
  cartStore.snapshot,
  getServerSnapshot: () => serverCart,
  equals: (a, b) => a.revision == b.revision,
);
```

## Live demo

<HookDemo name="useExternalStore"/>

## Ownership and lifecycle

The store and snapshots remain caller-owned. The hook owns only its subscription and always unsubscribes when the source changes or the component unmounts. A stable `subscribe` function avoids unnecessary reconnects.

## Server rendering

Server rendering requires `getServerSnapshot`; omitting it throws `StateError`. When it is also supplied in the browser, that snapshot is retained for the first hydration build. The hook subscribes after the first frame and then switches to `getSnapshot`.

## Common mistakes

Do not mutate and return the same snapshot object after notifying; publish immutable snapshots. The subscribe callback must not retain obsolete listeners. Equality should describe rendered meaning and remain pure.

## Related APIs

Use `useListenable` for a native Jaspr `Listenable`, `useValueListenable` for a `ValueListenable`, and `useInherited` for tree-scoped dependencies.
