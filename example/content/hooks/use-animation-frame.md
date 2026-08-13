---
title: useAnimationFrame
description: Run the latest callback on browser animation frames.
---

`useAnimationFrame` owns a repeating `requestAnimationFrame` loop and always invokes the newest callback.

## Signature

```dart
void useAnimationFrame(
  AnimationFrameCallback callback, {
  bool enabled = true,
});
```

## Lifecycle

```dart
useAnimationFrame((timestamp) => position.value++, enabled: running);
```

<HookDemo name="useAnimationFrame"/>

Disabling or unmounting cancels the scheduled frame. Timestamps are exposed as `Duration` values.

## Server rendering

No frame is scheduled and the callback is never invoked on the server.

## Common mistakes

Do not rebuild expensive trees at display refresh rate without need. Use CSS animations for purely visual transitions.

## Related APIs

Use `useInterval` for wall-clock repetition and `usePostFrameEffect` for a single completed frame.
