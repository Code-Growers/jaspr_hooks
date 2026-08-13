---
title: useActiveElement
description: Track the browser document's active element.
---

`useActiveElement` returns the latest `document.activeElement` and rebuilds after focus transitions.

## Signature

```dart
web.Element? useActiveElement();
```

## Lifecycle

```dart
final active = useActiveElement();
final tag = active?.tagName.toLowerCase();
```

<HookDemo name="useActiveElement"/>

One document-level subscription is owned by the hook and removed on unmount.

## Server rendering

The result is `null` during SSR and the first hydration build.

## Common mistakes

Do not retain the returned element after a rebuild. Shadow DOM focus may surface the host rather than a deeply focused descendant.

## Related APIs

Use `useFocus` for one element and `useFocusWithin` for a subtree.
