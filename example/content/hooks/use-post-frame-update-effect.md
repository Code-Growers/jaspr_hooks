---
title: usePostFrameUpdateEffect
description: Run a post-frame effect for updates while skipping the frame that mounted the hook.
---

## What it does

`usePostFrameUpdateEffect(effect, [keys])` combines `usePostFrameEffect` and `useUpdateEffect`. The effect runs after a completed browser frame, but never for the frame that mounted the hook. It replaces the pattern of storing previous property values in refs to detect a change from `didUpdateComponent`.

With no keys it runs after every later client frame. With keys it runs after the frame in which their ordered contents changed.

## Signature and parameters

```dart
void usePostFrameUpdateEffect(
  Dispose? Function() effect, [
  List<Object?>? keys,
])
```

`effect` may return a synchronous cleanup. The hook returns nothing.

## Usage

```dart
class OfferPage extends HookComponent {
  const OfferPage(this.token, {super.key});
  final String token;

  @override
  Component build(BuildContext context) {
    final controller = useOfferController();
    usePostFrameUpdateEffect(() {
      controller.reloadFor(token);
      return null;
    }, [token]);

    return controller.render();
  }
}
```

## Ownership and lifecycle

The hook owns the cleanup returned by a completed run. Cleanup runs before the replacement effect and on disposal. A key change before the mount frame completes counts as the mount and is skipped.

## Live demo

<HookDemo name="usePostFrameUpdateEffect"/>

## Server rendering

Effects and cleanups are skipped during server and static rendering.

## Common mistakes

Passing an empty key list means the effect never runs, because no update can change the keys. Capture the values you need inside the effect closure; the hook does not pass previous values.

## Related APIs

Use `usePostFrameEffect` when the mount frame should run the effect too. Use `useUpdateEffect` when the effect can run synchronously during build. Use `usePrevious` when the effect needs the preceding value.
