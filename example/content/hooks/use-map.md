---
title: useMap
description: Own keyed map state through a stable mutation controller.
---

## What it does

`useMap` copies an initial map and returns a stable `MapController<K, V>`. Its unmodifiable live `value` view updates when controller operations change an entry or replace the collection.

## Signature and parameters

```dart
MapController<K, V> useMap<K, V>([
  Map<K, V> initialValue = const <Never, Never>{},
])
```

The controller exposes `setValue`, `setAll`, `remove`, `replaceAll`, and `clear`. `remove` returns the previous nullable value when the key was present.

## Usage

```dart
final votes = useMap<String, int>({'hooks': 1});

return button(
  onClick: () => votes.setValue('hooks', (votes.value['hooks'] ?? 0) + 1),
  [Component.text('Votes: ${votes.value['hooks']}')],
);
```

## Live demo

<HookDemo name="useMap"/>

## Ownership and lifecycle

The private map is hook-owned and the public view cannot be mutated. Operations that leave all relevant entries equal do not rebuild. Controller methods throw after disposal.

## Server rendering

Initialization works on both platforms. Use deterministic keys, values, and insertion order when entries are rendered sequentially.

## Common mistakes

A `null` result from `remove` cannot distinguish an absent key from a present nullable value; inspect `value.containsKey` first when that distinction matters. Do not mutate nested values in place and expect change detection.

## Related APIs

Use `useSet` for key-only membership, `useList` for ordered duplicates, and `useExternalStore` for a shared map owned outside the component.
