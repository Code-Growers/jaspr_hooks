---
title: useEvent
description: Keep callback identity stable while invoking the latest handler.
---

`useEvent` returns a stable one-argument callable whose implementation is refreshed on every build. Use a record when the event needs multiple arguments.

## Signature

```dart
StableEventCallback<T, R> useEvent<T, R>(R Function(T value) handler);
```

## Lifecycle

```dart
final onValue = useEvent<int, void>((value) => save(value, currentUser));
```

<HookDemo name="useEvent"/>

The returned object's identity remains stable until unmount, while calls always reach the newest closure.

## Server rendering

The callable is deterministic and usable on the server. It owns no browser resources.

## Common mistakes

Do not call the handler during build when it mutates state. Use `useCallback` when dependency changes should deliberately change callback identity.

## Related APIs

Use `useLatest` for a stable mutable reference and `useEventListener` for native DOM subscriptions.
