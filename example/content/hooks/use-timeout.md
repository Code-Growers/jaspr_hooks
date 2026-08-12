---
title: useTimeout
description: Invoke the latest callback once after a browser-client delay.
---

## What it does

`useTimeout` schedules one callback after the supplied duration. Updating the callback does not restart the timer; the eventual invocation always calls the latest callback supplied by the most recent build.

## Signature and parameters

```dart
void useTimeout(VoidCallback callback, Duration? delay)
```

`callback` runs once. `delay` controls timer identity; passing `null` disables or cancels it. The hook returns nothing.

## Usage

```dart
useTimeout(
  () => bannerVisible.value = false,
  bannerVisible.value ? const Duration(seconds: 4) : null,
);
```

## Live demo

<HookDemo name="useTimeout"/>

## Ownership and lifecycle

The hook owns and cancels its `Timer`. Changing `delay` replaces the timer, `null` cancels it, and unmount cancels pending work. A callback-only change is read through a stable latest-value reference.

## Server rendering

The timer is implemented through `useEffect`, so it is never created during server or static rendering. The first browser build schedules it normally.

## Common mistakes

Do not call the hook conditionally when a timeout is disabled; pass `null`. Avoid using a timeout as a substitute for an operation's completion signal. A negative or zero duration may run on the next event-loop turn.

## Related APIs

Use `useInterval` for repeated work, `useDebounced` to delay publishing changing values, and `useEffect` when scheduling needs custom cleanup.
