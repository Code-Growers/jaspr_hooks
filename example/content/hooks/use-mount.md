---
title: useMount
description: Run a cleanup-free callback on the first browser-client build.
---

## What it does

`useMount` runs a synchronous callback once when its hook first builds in the browser. It is the cleanup-free convenience form of `useEffectOnce`.

## Signature and parameters

```dart
void useMount(VoidCallback effect)
```

`effect` takes no arguments and cannot return cleanup. The hook itself returns nothing.

## Usage

```dart
useMount(() {
  analytics.record('dashboard-mounted');
});
```

## Live demo

<HookDemo name="useMount"/>

## Ownership and lifecycle

There is no owned resource or cleanup. The callback is the one supplied on the initial client build; later callback changes do not cause another invocation.

## Server rendering

`useMount` is skipped completely during server and static rendering. It must not be required to produce initial HTML.

## Common mistakes

Do not start a subscription or allocate a resource without cleanup; use `useEffectOnce` instead. Do not use mount as a substitute for deterministic initialization that belongs in `useMemoized` or `useState`.

## Related APIs

Use `useEffectOnce` when cleanup is needed, `useUnmount` for teardown-only behavior, and `usePostFrameEffect` for committed DOM work.
