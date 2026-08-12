---
title: use
description: Register a custom Hook object and participate in the Jaspr hook lifecycle.
---

## What it does

`use` is the low-level entry point behind every built-in hook. It registers an immutable `Hook<R>` at the current call position and returns the value built by its `HookState`.

Choose this API when composition cannot express a resource lifecycle. `initHook` initializes once, `didUpdateHook` receives new configuration, `setState` rebuilds the owner, and `dispose` releases resources. Most application hooks should instead compose primitives in a top-level `use...` function.

## Signature and parameters

```dart
R use<R>(Hook<R> hook)
```

`hook` is immutable configuration for one call position. Its runtime type and ordered `keys` determine whether the existing `HookState` is preserved. The return value is the `R` produced by `HookState.build`.

## Usage

```dart
class CounterHook extends Hook<int> {
  const CounterHook();

  @override
  CounterHookState createState() => CounterHookState();
}

class CounterHookState extends HookState<int, CounterHook> {
  var count = 0;

  void increment() => setState(() => count++);

  @override
  int build(BuildContext context) => count;
}

int useRawCounter() => use(const CounterHook());
```

## Live demo

<HookDemo name="use"/>

## Ownership and lifecycle

The runtime owns the created `HookState` and forwards `initHook`, `didUpdateHook`, `deactivate`, and reverse-order `dispose`. Custom state owns every resource it creates and must release it synchronously. Cleanup failures are isolated and reported through the Jaspr binding.

## Server rendering

A custom hook runs wherever its owning hook component builds. Keep server initialization deterministic and guard browser-only resources with `context.binding.isClient`.

## Common mistakes

Do not call `use` outside a hook host build or vary its position conditionally. Do not expose private element internals; `Hook` and `HookState` are the supported extension points. Prefer composition unless a resource needs a lifecycle primitive that built-in hooks cannot express.

## Related APIs

Start with [Writing custom hooks](guides/custom-hooks). See `useEffect` for disposable client work and `useMemoized` for keyed resource identity.
