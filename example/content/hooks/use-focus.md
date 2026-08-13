---
title: useFocus
description: Track and control focus for a keyed HTML element.
---

`useFocus` returns a stable controller for a `useNodeKey` target. It exposes focus state plus imperative `focus` and `blur` operations.

## Signature

```dart
FocusController useFocus(
  GlobalNodeKey<web.HTMLElement> target, {
  bool enabled = true,
});
```

## Lifecycle

```dart
final target = useNodeKey<web.HTMLInputElement>();
final focus = useFocus(target);
return input(key: target, onClick: () => focus.focus());
```

<HookDemo name="useFocus"/>

Listeners attach after the node renders and detach when disabled, replaced, or unmounted.

## Server rendering

`hasFocus` is `null` during SSR and before browser attachment. Imperative methods require an attached target.

## Common mistakes

Do not call `focus()` during build or before attachment. Prefer native focusable elements and preserve visible focus indicators.

## Related APIs

Use `useFocusWithin` for composite regions and `useActiveElement` for document-wide focus.
