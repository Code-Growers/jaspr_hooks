---
title: useEffect
description: Run synchronous client-side effects and clean them up safely.
---

## What it does

`useEffect(effect, [keys])` invokes a synchronous effect on the browser client. The effect may return a cleanup callback, which runs before a keyed rerun and on disposal.

With no keys, the effect runs on every build. With an empty list it runs once per mount. With keys it reruns when ordered key equality changes. Do not return a `Future`; start async work inside the effect and return synchronous cancellation.

## Usage

```dart
class TitleSync extends HookComponent {
  const TitleSync(this.title, {super.key});
  final String title;

  @override
  Component build(BuildContext context) {
    useEffect(() {
      final subscription = titleEvents.listen((_) {});
      return subscription.cancel;
    }, [titleEvents]);

    return text(title);
  }
}
```

## Live demo

<HookDemo name="useEffect"/>

## Server rendering

Effects are skipped during server rendering. Render an SSR-safe default, and use the effect only for browser resources or post-hydration synchronization.

## Related APIs

Use `usePostFrameEffect` when work must wait until Jaspr finishes the frame. Use `useMemoized` to create a keyed synchronous value without side effects.

