---
title: useImperativeHandle
description: Publish a limited imperative API through an ObjectRef.
---

## What it does

`useImperativeHandle` creates a handle and assigns it to a parent-supplied reference. It is useful when a component intentionally exposes a small imperative operation such as focus, reset, or measurement instead of its complete internal state.

## Signature and parameters

```dart
void useImperativeHandle<T extends Object>(
  ObjectRef<T?>? target,
  T Function() createHandle, [
  List<Object?>? keys,
])
```

`target` receives the handle and may be `null`. `createHandle` builds `T`. Omitted keys recreate the handle every build; matching ordered keys preserve it. Changing the target also replaces the handle. The hook returns nothing.

## Usage

```dart
final handle = useRef<SearchHandle?>(null);

useImperativeHandle<SearchHandle>(
  handle,
  () => SearchHandle(clear: () => query.value = ''),
  [query],
);
```

## Live demo

<HookDemo name="useImperativeHandle"/>

## Ownership and lifecycle

The hook owns publication of the handle, not disposal of arbitrary resources captured by it. Replacement and unmount clear the old target only when it still contains that exact handle, so a newer assignment is not erased.

## Server rendering

Handle creation is universal and references are not serialized. Keep creation deterministic and do not expose a browser node before it is attached; pair DOM access with `useNodeKey` from the web entry point.

## Common mistakes

Do not use an imperative handle as ordinary render state. Supply keys when recreating the handle is expensive or when consumers depend on identity. Use `useDisposable` if the handle itself owns a resource requiring cleanup.

## Related APIs

Use `useRef` to create the target, `useLatest` to let a stable handle read current values, and `useNodeKey` for a rendered DOM node.
