---
title: useList
description: Own ordered list state through a stable mutation controller.
---

## What it does

`useList` snapshots its initial iterable and returns a stable `ListController<T>`. Its live, unmodifiable `value` view reflects additions, insertions, replacements, removals, and clears performed through the controller.

## Signature and parameters

```dart
ListController<T> useList<T>([
  Iterable<T> initialValue = const <Never>[],
])
```

The iterable is copied only during initialization. The controller provides `add`, `addAll`, `insert`, `insertAll`, `setAt`, `remove`, `removeAt`, `replaceAll`, and `clear`.

## Usage

```dart
final tags = useList<String>(['jaspr']);

return button(
  onClick: () => tags.add('hooks'),
  [Component.text(tags.value.join(', '))],
);
```

## Live demo

<HookDemo name="useList"/>

## Ownership and lifecycle

The hook owns its private list and exposes an unmodifiable live view. Effective operations rebuild; empty bulk additions, equal replacements, and unchanged `setAt` operations do not. Methods throw after disposal.

## Server rendering

The initial iterable is copied on both server and client. Its values and iteration order must be deterministic when rendered into HTML.

## Common mistakes

Do not cast or mutate `value`; call controller methods. Snapshot `List.of(controller.value)` before retaining historical contents because the view remains live. Check indexes before indexed operations.

## Related APIs

Use `useSet` for uniqueness, `useQueue` for FIFO operations, and `useReducer` when list transitions need a stricter action model.
