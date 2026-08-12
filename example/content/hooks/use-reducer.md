---
title: useReducer
description: Model state transitions with a synchronous reducer and typed actions.
---

## What it does

`useReducer(reducer, initialState:, initialAction:)` returns a `Store<State, Action>` exposing `.state` and `.dispatch(action)`.

Initialization applies `initialAction` to `initialState`. Dispatch synchronously runs the latest reducer and rebuilds only when the next state differs from the current state.

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

## Server rendering

The initial reducer call occurs during SSR, so it must be deterministic and side-effect free. User actions normally dispatch after hydration.

## Related APIs

Use `useState` for direct, local values. Reducers are clearer when several action types share transition logic.

