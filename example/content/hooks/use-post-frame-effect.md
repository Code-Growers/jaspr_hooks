---
title: usePostFrameEffect
description: Run a client effect after Jaspr completes the next frame.
---

## What it does

`usePostFrameEffect(effect, [keys])` schedules a synchronous effect after the current client frame, with the same keyed cleanup model as `useEffect`.

It is useful when work depends on committed DOM. Stale scheduled callbacks are ignored when keys change or the hook is disposed before the frame completes. Cleanup runs before the next successful invocation and at disposal.

## Signature and parameters

```dart
void usePostFrameEffect(
  Dispose? Function() effect, [
  List<Object?>? keys,
])
```

`effect` may return synchronous cleanup. Null or omitted keys schedule after every client build; ordered keys preserve completed work while equal. The hook returns nothing.

## Usage

```dart
class FocusAfterMount extends HookComponent {
  const FocusAfterMount({super.key});

  @override
  Component build(BuildContext context) {
    usePostFrameEffect(() {
      focusSearchField();
      return null;
    }, const []);

    return input(id: 'search');
  }
}
```

## Live demo

<HookDemo name="usePostFrameEffect"/>

## Ownership and lifecycle

The hook owns scheduled-generation invalidation and completed cleanup. A key change cancels stale pending work; after a completed run, its cleanup executes before the replacement effect and again for the final run at unmount.

## Server rendering

Nothing is scheduled on the server. The initial markup should not depend on the effect having run.

## Common mistakes

Do not treat this as React's pre-paint `useLayoutEffect`; it runs after a Jaspr frame. Never return a `Future`, and prefer specialized hooks from `web.dart` for observers and native event ownership.

## Related APIs

Prefer `useEffect` when committed DOM is not required. Read [SSR & hydration](guides/ssr-and-hydration) before using browser state.
