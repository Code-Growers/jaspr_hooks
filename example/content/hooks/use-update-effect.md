---
title: useUpdateEffect
description: Run an effect for client updates while skipping the first build.
---

## What it does

`useUpdateEffect` behaves like `useEffect` after the initial browser build. It is useful when a side effect should react to later prop or state changes but not to initial attachment.

## Signature and parameters

```dart
void useUpdateEffect(
  Dispose? Function() effect, [
  List<Object?>? keys,
])
```

`effect` may return synchronous cleanup. With omitted or null keys it runs on every update; with keys it runs when their ordered contents change. The hook returns nothing.

## Usage

```dart
useUpdateEffect(() {
  analytics.recordFilter(filter);
  return null;
}, [filter]);
```

## Live demo

<HookDemo name="useUpdateEffect"/>

## Ownership and lifecycle

After the initial skip, effect replacement and cleanup follow `useEffect` semantics. The final completed effect is cleaned at unmount. The hook retains its initial-build flag for its call position.

## Server rendering

Effects and cleanups are skipped during server/static rendering. The first browser build establishes the skipped baseline, including during hydration.

## Common mistakes

Do not use this to conceal an incorrectly modeled initial side effect. Include all changing dependencies in keys. An empty key list means the effect never runs because there is no later key change.

## Related APIs

Use `useEffect` when the initial client run is required, `useEffectOnce` for mount plus cleanup, and `useValueChanged` for a synchronous render-time transformation.
