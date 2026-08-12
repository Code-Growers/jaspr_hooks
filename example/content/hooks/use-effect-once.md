---
title: useEffectOnce
description: Run one browser-client effect with optional unmount cleanup.
---

## What it does

`useEffectOnce` is a convenience wrapper around `useEffect` with an empty key list. It runs on the first browser-client build and preserves its cleanup until the hook is removed.

## Signature and parameters

```dart
void useEffectOnce(Dispose? Function() effect)
```

`effect` runs synchronously and may return a synchronous `Dispose` callback. The hook returns nothing.

## Usage

```dart
useEffectOnce(() {
  analytics.openPage();
  return analytics.closePage;
});
```

## Live demo

<HookDemo name="useEffectOnce"/>

## Ownership and lifecycle

The hook owns the returned cleanup and invokes it at client unmount. The callback instance from the initial run remains captured; later builds do not replace the effect.

## Server rendering

The effect and cleanup are skipped during server and static rendering. They start independently when the browser hook tree builds.

## Common mistakes

Do not use this hook merely to avoid thinking about dependencies. If the operation depends on changing values, use keyed `useEffect`. Never return a `Future`; return synchronous cleanup and launch asynchronous work separately.

## Related APIs

`useMount` omits cleanup, `useUnmount` runs only cleanup, and `useUpdateEffect` skips the first client build.
