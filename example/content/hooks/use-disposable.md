---
title: useDisposable
description: Create and dispose an owned resource with ordered-key identity.
---

## What it does

`useDisposable` creates a resource immediately, preserves it while its ordered keys match, and invokes its disposer when the resource is replaced or the hook is removed.

## Signature and parameters

```dart
T useDisposable<T>(
  T Function() create,
  void Function(T value) dispose, [
  List<Object?> keys = const <Object?>[],
])
```

`create` constructs the value, `dispose` releases that exact value, and `keys` define its identity. The hook returns the owned `T`.

## Usage

```dart
final client = useDisposable<ApiClient>(
  () => ApiClient(endpoint),
  (client) => client.close(),
  [endpoint],
);
```

## Live demo

<HookDemo name="useDisposable"/>

## Ownership and lifecycle

The hook exclusively owns the created resource. A key change creates the replacement and disposes the replaced state through the hook runtime; unmount disposes the final value. Cleanup failures are reported by the runtime without preventing cleanup of other hooks.

Development hot reload disposes the old resource and creates a replacement on the next build, using the updated creator and retaining the old resource's original disposer. Unmount before that build disposes only the old resource.

## Server rendering

Creation and disposal can run on both server and client trees. The initializer must therefore be deterministic and platform-safe. Do not open browser-only resources here from universal components; put those inside a client-only effect or a DOM hook.

Disposal is tied to element unmount, not response completion. Jaspr does not guarantee request-end unmounting. Manage request resources, including database connections and asynchronous cleanup, with explicit `try`/`finally` in the caller. See [Server components](guides/server-components).

## Common mistakes

Do not also close the returned object elsewhere unless its API explicitly supports repeated disposal. Include every input that changes resource identity in `keys`. Use `useMemoized` instead when no cleanup is required.

## Related APIs

`useMemoized` caches unowned values. `useEffect` owns client-only side effects, while `useStreamController` is the specialized hook for an owned broadcast controller.
