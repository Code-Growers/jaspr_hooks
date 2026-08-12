---
title: usePostFrameEffect
description: Run a client effect after Jaspr completes the next frame.
---

## What it does

`usePostFrameEffect(effect, [keys])` schedules a synchronous effect after the current client frame, with the same keyed cleanup model as `useEffect`.

It is useful when work depends on committed DOM. Stale scheduled callbacks are ignored when keys change or the hook is disposed before the frame completes. Cleanup runs before the next successful invocation and at disposal.

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

## Server rendering

Nothing is scheduled on the server. The initial markup should not depend on the effect having run.

## Related APIs

Prefer `useEffect` when committed DOM is not required. Read [SSR & hydration](guides/ssr-and-hydration) before using browser state.
