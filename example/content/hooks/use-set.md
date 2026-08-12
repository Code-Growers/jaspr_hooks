---
title: useSet
description: Own unique-value state through a stable mutation controller.
---

## What it does

`useSet` snapshots an iterable into a set and returns a stable `SetController<T>`. It exposes an unmodifiable live view and rebuilds only when membership actually changes.

## Signature and parameters

```dart
SetController<T> useSet<T>([
  Iterable<T> initialValue = const <Never>[],
])
```

The controller provides `add`, `addAll`, `remove`, `replaceAll`, and `clear`. Single-value `add` and `remove` report whether the set changed.

## Usage

```dart
final selected = useSet<String>();

void toggle(String id) {
  if (!selected.remove(id)) selected.add(id);
}
```

## Live demo

<HookDemo name="useSet"/>

## Ownership and lifecycle

The hook owns the mutable set; callers receive an unmodifiable live view. Duplicate additions, missing removals, equal replacements, and empty clears are no-ops. Methods throw after disposal.

## Server rendering

The initial iterable is evaluated independently on server and client. Membership and iteration order must be deterministic if the set directly determines markup order.

## Common mistakes

Do not mutate objects used as set keys in a way that changes equality or hash codes. Sort the values before rendering when stable output order is required across runtimes.

## Related APIs

Use `useList` when duplicates or explicit position matter, `useMap` for associated values, and `useToggle` for one boolean membership flag.
