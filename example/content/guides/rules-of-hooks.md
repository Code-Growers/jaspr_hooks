---
title: Rules of hooks
description: Keep hook identity stable by calling hooks unconditionally and in the same order.
---

Hook state is associated with call position. The same component must therefore call the same hook types in the same order on every build.

## Call hooks at build time

Hooks belong directly in `HookComponent.build`, a `StatefulHookComponent` state build, a `HookBuilder`, or another custom `use...` function called synchronously from one of those locations.

```dart
Component build(BuildContext context) {
  final count = useState(0);
  final previous = usePrevious(count.value);
  return Component.text('$previous → ${count.value}');
}
```

## Never call hooks conditionally

```dart
// Incorrect: the hook index changes when enabled changes.
if (enabled) {
  useEffect(connect, const []);
}

// Correct: call the hook every time and branch inside it.
useEffect(() {
  if (!enabled) return null;
  return connect();
}, [enabled]);
```

Loops have the same problem when their length may change. Extract a child `HookComponent` for each repeated item instead.

## Keys control resource identity

Hooks such as `useMemoized`, `useEffect`, and `useValueNotifier` accept ordered keys. Keep the state when keys match; replace and dispose it when they differ.
