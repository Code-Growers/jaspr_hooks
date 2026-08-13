---
title: useFocusWithin
description: Track focus within a keyed DOM subtree.
---

`useFocusWithin` reports whether the target itself or any descendant currently owns document focus.

## Signature

```dart
bool? useFocusWithin(
  GlobalNodeKey<web.Element> target, {
  bool enabled = true,
});
```

## Lifecycle

```dart
final region = useNodeKey<web.HTMLDivElement>();
final focused = useFocusWithin(region);
return div(key: region, [input(), button([.text('Save')])]);
```

<HookDemo name="useFocusWithin"/>

The hook listens to bubbling focus transitions and cleans up automatically.

## Server rendering

The result is `null` during SSR and before post-frame attachment.

## Common mistakes

Do not confuse focus-within with hover. Disabling the hook resets its value to `null`.

## Related APIs

Use `useFocus` to request focus and `useActiveElement` to inspect the focused node.
