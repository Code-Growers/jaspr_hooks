---
title: useNodeKey
description: Create a stable GlobalNodeKey for browser DOM hooks.
---

## What it does

`useNodeKey` creates the stable Jaspr key used by DOM-facing hooks to find a rendered browser node. Apply the returned key to exactly the component whose node should be observed.

## Signature and parameters

```dart
GlobalNodeKey<T> useNodeKey<T extends web.Node>({
  String? debugLabel,
})
```

`T` describes the expected DOM node type and `debugLabel` aids diagnostics. The key identity and original label are preserved for the hook lifetime.

## Usage

```dart
import 'package:jaspr_hooks/web.dart';
import 'package:universal_web/web.dart' as web;

final target = useNodeKey<web.Element>(debugLabel: 'profile-card');
return div(key: target, [Component.text('Profile')]);
```

## Live demo

<HookDemo name="useNodeKey"/>

## Ownership and lifecycle

The hook owns the key object, while Jaspr owns the rendered node. `currentNode` is populated only while the keyed component is attached. DOM hooks reconcile after frames because the node can change without the key identity changing.

## Server rendering

The key can be created universally, but no browser node is available during SSR or the first pre-attachment build. Do not render output from `currentNode` directly.

## Common mistakes

Import `package:jaspr_hooks/web.dart` for DOM hooks. Match `T` to the rendered node and do not reuse one key on multiple simultaneous components. Changing `debugLabel` later does not create a new key.

## Related APIs

The key is accepted by `useElementSize`, `useIntersection`, `useHover`, `useOnClickOutside`, and `useMutationObserver`.
