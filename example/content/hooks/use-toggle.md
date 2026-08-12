---
title: useToggle
description: Own boolean state with stable toggle and reset operations.
---

## What it does

`useToggle` returns a stable `ToggleController` containing a boolean `value` plus `setValue`, `toggle`, and `reset` operations. Mutations rebuild the owning hook component only when the value changes.

## Signature and parameters

```dart
ToggleController useToggle([bool initialValue = false])
```

`initialValue` is captured when the hook is created. The returned controller retains its identity for the hook lifetime and exposes the current `bool` through `value`.

## Usage

```dart
final details = useToggle();

return button(
  onClick: details.toggle,
  [Component.text(details.value ? 'Hide details' : 'Show details')],
);
```

## Live demo

<HookDemo name="useToggle"/>

## Ownership and lifecycle

The controller and value are hook-owned. `reset()` restores the originally captured value. Calling a mutation method after disposal throws `StateError`.

## Server rendering

The controller initializes on both server and client. Keep `initialValue` deterministic so the first hydration markup matches; mutations should originate from browser events.

## Common mistakes

Changing `initialValue` on a later build does not reset existing state. Call `setValue` or `reset` intentionally. Use `useState<bool>` when a plain `ValueNotifier` integrates better with another API.

## Related APIs

`useCounter` provides numeric operations, while `useState` is the general-purpose primitive behind simple render state.
