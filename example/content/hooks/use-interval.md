---
title: useInterval
description: Invoke the latest callback repeatedly on a browser-client interval.
---

## What it does

`useInterval` owns a periodic timer while an interval is supplied. Callback changes do not restart it, and each tick calls the latest callback from the most recent build.

## Signature and parameters

```dart
void useInterval(
  VoidCallback callback,
  Duration? interval, {
  bool immediate = false,
})
```

`interval` controls the period and may be `null` to pause. With `immediate`, one invocation is queued without waiting for the first period. The hook returns nothing.

## Usage

```dart
useInterval(
  () => elapsed.value++,
  running.value ? const Duration(seconds: 1) : null,
  immediate: true,
);
```

## Live demo

<HookDemo name="useInterval"/>

## Ownership and lifecycle

The hook owns both the optional immediate timer and periodic timer. Changing `interval` or `immediate` replaces them, while changing only the callback does not. All timers are cancelled on unmount.

## Server rendering

No timer is created during server or static rendering because the implementation uses `useEffect`. Initial server markup should not depend on interval ticks.

## Common mistakes

Pause by passing `null` instead of conditionally skipping the hook. Avoid zero-duration periodic timers, which can monopolize the event queue. Interval callbacks can drift; use an absolute clock when exact elapsed time matters.

## Related APIs

Use `useTimeout` for one invocation, `useLatest` for current callback data, and `useOnDocumentVisibilityChange` when polling should react to background tabs.
