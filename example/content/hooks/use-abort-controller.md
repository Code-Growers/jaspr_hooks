---
title: useAbortController
description: Own and automatically abort a browser AbortController.
---

`useAbortController` creates a controller after hydration and aborts it when its keys change or the hook unmounts.

## Signature

```dart
web.AbortController? useAbortController([
  List<Object?> keys = const [],
]);
```

## Ownership

```dart
final controller = useAbortController([requestId]);
final signal = controller?.signal;
```

<HookDemo name="useAbortController"/>

Each keyed generation has exactly one owned controller and cleanup aborts pending consumers.

## Server rendering

The result is `null` during SSR and first hydration so markup remains deterministic.

## Common mistakes

Do not manually reuse a signal after its controller is aborted. Guard nullable access until attachment.

## Related APIs

Use `useFuture` to observe a Future and `useAsyncAction` for user-triggered async concurrency.
