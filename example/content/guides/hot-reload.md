---
title: Hot reload
description: Understand which hook state survives Jaspr development reloads and which work is refreshed.
---

With Jaspr 0.24, press `r` during `jaspr serve` to hot reload, or use `jaspr serve --auto reload` to reload on save. Press `R` to hot restart when component or hook structure changes require fresh state.

## State that survives

When hook order and keys match, `useState`, `useGuardedState`, refs, IDs, node keys, reducer state, and local controllers keep their existing state. Initial values are not reapplied. A `HookIdScope` keeps its ID allocations while its element remains mounted.

```dart
final count = useState(0); // The current count survives hot reload.
final element = useNodeKey(); // The same key stays attached.
final latest = useRef<String>('initial'); // The same cell survives.
```

## Work that refreshes

`useMemoized` recomputes on the next build and `useCallback` receives the updated callback, even with empty keys. Put persistent mutable state in `useRef` or a state hook rather than a memoized value.

Browser effects clean up their old work and rerun with the latest configuration. Post-frame effects invalidate queued callbacks and run after the next frame. `useDisposable` disposes its old resource with its original disposer and creates a replacement on the next build. Unmount before that build only disposes the existing resource.

These rules also apply to hooks composed from effects, including timers and mount/update-effect helpers. `useUnmount` may run its cleanup during reload as its underlying effect refreshes. Server effects and browser subscriptions remain inactive. An ordinary update to server content does not by itself reset client state or invalidate every memoized value.

## Custom hooks

Override `HookState.reassemble` to mark cached work for refresh. Receive the updated hook configuration in the next `didUpdateHook` or `build` before recreating it. Reassembly also delivers `didUpdateHook` for an identical configuration instance, such as a const custom hook. The default callback preserves state. A callback failure is reported through Jaspr without preventing the remaining hooks from receiving reassembly.

```dart
bool needsRefresh = false;

@override
void reassemble() {
  needsRefresh = true;
}
```

## Changing hook order

Normal builds still reject a changed hook type at an existing position. During hot reload, a detected type mismatch preserves the matching prefix and resets the remaining hooks, disposing removed resources. Same-type insertions cannot be detected reliably. Use hot restart after adding, removing, reordering, or changing the generic types of hooks when existing state could move to a different call.
