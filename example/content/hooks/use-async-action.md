---
title: useAsyncAction
description: Coordinate user-initiated asynchronous state changes with explicit concurrency.
---

## What it does

`useAsyncAction` returns a stable `AsyncAction<State, Input>` controller. It exposes the committed `state`, `isPending`, the latest `error` and `stackTrace`, `dispatch(input)`, and `reset()`.

Choose `ActionConcurrency.sequential` to queue work, `latest` to suppress stale results, `drop` to reject overlaps, or `concurrent` to apply results in completion order. The action receives the state that is current when its operation starts.

## Signature and parameters

```dart
AsyncAction<StateT, InputT> useAsyncAction<StateT, InputT>({
  required StateT initialState,
  required AsyncActionHandler<StateT, InputT> action,
  ActionConcurrency concurrency = ActionConcurrency.sequential,
})
```

`initialState` is captured when the controller is created. `action(previousState, input)` may return a value or `Future`, and `concurrency` controls overlaps. The stable controller returns the latest committed state, pending/error information, `dispatch`, and `reset`.

## Usage

```dart
final save = useAsyncAction<Profile, ProfileDraft>(
  initialState: initialProfile,
  concurrency: ActionConcurrency.latest,
  action: (current, draft) => api.saveProfile(draft),
);

return button(
  disabled: save.isPending,
  onClick: () => save.dispatch(draft.value),
  [Component.text(save.isPending ? 'Saving…' : 'Save')],
);
```

## Live demo

<HookDemo name="useAsyncAction"/>

## Lifecycle and errors

The controller identity is preserved while the hook remains in the same call position. `reset()` restores the original state, clears errors, cancels queued work, and prevents already-running results from changing UI state. Dart Futures cannot be physically cancelled, so callers still receive the eventual result of work that already started.

Dropped operations complete with `ActionDroppedException`. Sequential operations invalidated before starting complete with `ActionCancelledException`. Action failures are both exposed on the controller and forwarded through the `Future` returned by `dispatch`.

## Server rendering

The deterministic `initialState` is available during server rendering. Calling `dispatch` on the server throws `StateError`; start actions from browser event handlers. Pending work and hook state are not serialized between the server and client.

## Common mistakes

Do not dispatch during build or create a second request cache inside the hook. Use a dedicated data layer when you need cross-component caching, deduplication, or server-data synchronization. Select concurrency based on the operation rather than treating `latest` as universal.

## Related APIs

Use `useOptimistic` to display an immediate speculative result, `useFuture` for observing a Future created elsewhere, and `useReducer` for synchronous state transitions.
