---
title: useCounter
description: Own integer state with stable arithmetic and reset operations.
---

## What it does

`useCounter` returns a stable controller with a current integer `value` and methods to increment, decrement, replace, or reset it. Each effective change rebuilds the hook host.

## Signature and parameters

```dart
CounterController useCounter([int initialValue = 0])
```

`initialValue` is captured once. `increment` and `decrement` accept an optional amount defaulting to one; `setValue` replaces the value and `reset` restores the initial value.

## Usage

```dart
final quantity = useCounter(1);

return button(
  onClick: () => quantity.increment(),
  [Component.text('Quantity: ${quantity.value}')],
);
```

## Live demo

<HookDemo name="useCounter"/>

## Ownership and lifecycle

The hook owns the controller and count. Adding or subtracting zero and setting the existing value are no-ops. Controller methods throw after its hook is disposed.

## Server rendering

Initialization works universally. Use a deterministic starting number; the server controller and hydrated client controller are separate instances.

## Common mistakes

Do not expect a changed `initialValue` prop to overwrite an existing count. Use `setValue` to synchronize intentionally, or keys on a containing hook component when a complete state reset is desired.

## Related APIs

Use `useToggle` for booleans, `useReducer` for constrained numeric transitions, and `useState<int>` when notifier interoperability matters.
