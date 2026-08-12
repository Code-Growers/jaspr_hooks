---
title: useQueue
description: Own first-in, first-out state through a stable controller.
---

## What it does

`useQueue` snapshots an initial iterable and returns a stable FIFO `QueueController<T>`. Its unmodifiable live list is ordered from the next value to dequeue through the newest value.

## Signature and parameters

```dart
QueueController<T> useQueue<T>([
  Iterable<T> initialValue = const <Never>[],
])
```

The controller exposes `value`, `length`, `isEmpty`, `isNotEmpty`, `enqueue`, `enqueueAll`, `dequeue`, `replaceAll`, and `clear`. `dequeue` removes and returns the front value.

## Usage

```dart
final jobs = useQueue<String>();

jobs.enqueue('build');
if (jobs.isNotEmpty) {
  final next = jobs.dequeue();
  runJob(next);
}
```

## Live demo

<HookDemo name="useQueue"/>

## Ownership and lifecycle

The queue and controller are hook-owned. Mutations rebuild unless the bulk input is empty or a replacement is equal. Calls after disposal throw `StateError`.

## Server rendering

Queue initialization is universal, but enqueueing and dequeueing during build is still state mutation. Keep the initial sequence deterministic and mutate from events or effects.

## Common mistakes

Calling `dequeue` on an empty queue throws `StateError`; check `isNotEmpty`. Do not retain `value` as a historical snapshot because it is a live view—copy it when history is required.

## Related APIs

Use `useList` for indexed editing, `useAsyncAction` for asynchronous operation sequencing, and `useReducer` for domain-specific queue actions.
