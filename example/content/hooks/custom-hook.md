---
title: use
description: Register a custom Hook object and participate in the Jaspr hook lifecycle.
---

## What it does

`use` is the low-level entry point behind every built-in hook. It registers an immutable `Hook<R>` at the current call position and returns the value built by its `HookState`.

Choose this API when composition cannot express a resource lifecycle. `initHook` initializes once, `didUpdateHook` receives new configuration, `setState` rebuilds the owner, and `dispose` releases resources. Most application hooks should instead compose primitives in a top-level `use...` function.

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

int useCounter() => use(const CounterHook());
```

## Live demo

<HookDemo name="use"/>

## Server rendering

A custom hook runs wherever its owning hook component builds. Keep server initialization deterministic and guard browser-only resources with `context.binding.isClient`.

## Related APIs

Start with [Writing custom hooks](guides/custom-hooks). See `useEffect` for disposable client work and `useMemoized` for keyed resource identity.
