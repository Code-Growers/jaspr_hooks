---
title: useReducer
description: Model state transitions with a synchronous reducer and typed actions.
---

## What it does

`useReducer(reducer, initialState:, initialAction:)` returns a `Store<State, Action>` exposing `.state` and `.dispatch(action)`.

Initialization applies `initialAction` to `initialState`. Dispatch synchronously runs the latest reducer and rebuilds only when the next state differs from the current state.

## Signature and parameters

```dart
Store<StateT, ActionT> useReducer<StateT, ActionT>(
  Reducer<StateT, ActionT> reducer, {
  required StateT initialState,
  required ActionT initialAction,
})
```

The reducer computes each transition. Initialization calls it once with `initialState` and `initialAction`; the stable returned store exposes `state` and `dispatch`.

## Usage

```dart
enum CounterAction { increment, reset }

class Counter extends HookComponent {
  const Counter({super.key});

  @override
  Component build(BuildContext context) {
    final store = useReducer<int, CounterAction>(
      (state, action) => switch (action) {
        CounterAction.increment => state + 1,
        CounterAction.reset => 0,
      },
      initialState: 0,
      initialAction: CounterAction.reset,
    );

    return button(
      onClick: () => store.dispatch(CounterAction.increment),
      [text('Count: ${store.state}')],
    );
  }
}
```

## Live demo

<HookDemo name="useReducer"/>

## Ownership and lifecycle

The hook owns the store state and stable dispatch method but not objects embedded in the state. It uses the latest reducer after rebuilds and requests a rebuild only when the next state differs by `!=`.

## Server rendering

The initial reducer call occurs during SSR, so it must be deterministic and side-effect free. User actions normally dispatch after hydration.

## Common mistakes

Reducers must not perform effects or mutate existing state in place. Do not expect later `initialState` or `initialAction` changes to reinitialize a preserved store; dispatch an explicit reset action instead.

## Related APIs

Use `useState` for direct, local values. Reducers are clearer when several action types share transition logic.
