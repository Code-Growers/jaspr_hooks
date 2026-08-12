---
title: useOptimistic
description: Layer reversible optimistic updates over authoritative state.
---

## What it does

`useOptimistic(authoritativeState, reducer)` returns a stable `OptimisticState<State, Update>`. Its `value` reapplies every pending update over the latest authoritative input in call order.

`add(update)` returns an `OptimisticUpdateHandle`: call `commit(authoritativeState)` after success or `rollback()` after failure. The convenience `run` method performs those steps automatically around a Future.

## Signature and parameters

```dart
OptimisticState<StateT, UpdateT> useOptimistic<StateT, UpdateT>(
  StateT authoritativeState,
  StateT Function(StateT current, UpdateT update) reducer,
)
```

`authoritativeState` is the latest source-of-truth input. The pure `reducer` applies one pending update. The stable returned controller exposes `value`, pending status, `add`, `run`, and `reset`.

## Usage

```dart
final todos = useOptimistic<List<Todo>, Todo>(
  serverTodos,
  (current, todo) => [...current, todo],
);

Future<void> addTodo(Todo draft) async {
  await todos.run<Todo>(
    draft,
    () => api.createTodo(draft),
    authoritativeState: (saved) => [...serverTodos, saved],
  );
}
```

## Live demo

<HookDemo name="useOptimistic"/>

## Rebasing and ownership

The reducer must be deterministic and free of side effects. When the authoritative input changes, all unresolved updates are reapplied over it. Committing one handle adopts its supplied authoritative value and then reapplies the other pending updates. Rolling back removes only that update.

Handles belong to their hook instance. `reset`, disposal, commit, and rollback invalidate them. Reusing an invalid handle throws `StateError`.

## Server rendering

The hook renders its authoritative input during SSR, with no pending state. `add`, `run`, and `reset` are client mutation operations and throw if invoked during server rendering. Optimistic state is never serialized through hydration.

## Common mistakes

Do not use an impure reducer or pass an optimistic result as though it were authoritative. The value passed to `commit` should come from the successful source of truth. Keep persistence, cache invalidation, and retry policies in the application data layer.

## Related APIs

Use `useAsyncAction` for pending/error/concurrency state, `useReducer` for synchronous local updates, and `useState` for simple values.
