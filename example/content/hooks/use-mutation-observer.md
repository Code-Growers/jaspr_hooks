---
title: useMutationObserver
description: Observe native DOM mutations beneath a keyed node.
---

## What it does

`useMutationObserver` attaches a browser `MutationObserver` and sends batches of immutable mutation records to the latest callback. It is intended for integration with imperative scripts or DOM outside Jaspr's normal declarative state.

## Signature and parameters

```dart
void useMutationObserver(
  GlobalNodeKey<web.Node> target,
  WebMutationCallback callback, {
  MutationObserverOptions options = const MutationObserverOptions(),
})
```

Options select child-list, attribute, character-data, subtree, old-value, and attribute-filter observation. At least one effective mutation category is required. The hook returns nothing.

## Usage

```dart
import 'package:jaspr_hooks/web.dart';
import 'package:universal_web/web.dart' as web;

final container = useNodeKey<web.Node>();
useMutationObserver(
  container,
  (records) => mutationCount.value += records.length,
  options: const MutationObserverOptions(childList: true, subtree: true),
);
```

## Live demo

<HookDemo name="useMutationObserver"/>

## Ownership and lifecycle

The hook owns and disconnects the observer. Changing the target, attached node, or options reconnects it; changing only the callback uses the latest closure. Callback failures are reported through the hook runtime.

## Server rendering

No observer is created during SSR or before browser attachment. Unsupported browsers silently leave observation inactive, so it must not be required for initial content.

## Common mistakes

Prefer Jaspr state over observing DOM that Jaspr itself owns. Avoid callbacks that immediately cause the same observed mutation, and narrow `subtree`, attributes, and filters to reduce overhead.

## Related APIs

Use `useNodeKey` for the target, `useElementSize` for geometry changes, and `useEventListener` for user or platform events.
