---
title: useEffect
description: Run synchronous client-side effects and clean them up safely.
---

## What it does

`useEffect(effect, [keys])` invokes a synchronous effect on the browser client. The effect may return a cleanup callback. On keyed replacement, the new synchronous effect initializes during build and the replaced state is cleaned after that build, matching the ordered hook runtime; final cleanup runs on disposal.

With no keys, the effect runs on every build. With an empty list it runs once per mount. With keys it reruns when ordered key equality changes. Do not return a `Future`; start async work inside the effect and return synchronous cancellation.

## Signature and parameters

```dart
void useEffect(
  Dispose? Function() effect, [
  List<Object?>? keys,
])
```

`effect` runs synchronously and may return synchronous cleanup. Null or omitted keys rerun every client build; ordered keys preserve the effect while equal. The hook returns nothing.

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

## Ownership and lifecycle

The hook owns only the cleanup returned by the effect. With no keys it cleans and reruns on every client build; stable keys preserve the completed effect. Cleanup errors are reported without preventing other hook disposal.

Development hot reload cleans up and reruns the effect with its latest configuration, even when keys match. Effects stay inactive on the server.

## Server rendering

Effects are skipped during server rendering. Render an SSR-safe default, and use the effect only for browser resources or post-hydration synchronization.

## Common mistakes

Never return a `Future` as cleanup. Include every value that changes the resource identity in `keys`, and make cleanup safe even if surrounding state has moved on. Use `usePostFrameEffect` when committed DOM is required.

## Related APIs

Use `usePostFrameEffect` when work must wait until Jaspr finishes the frame. Use `useMemoized` to create a keyed synchronous value without side effects.
