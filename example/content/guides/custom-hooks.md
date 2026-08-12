---
title: Writing custom hooks
description: Compose existing hooks or implement Hook and HookState for reusable lifecycle objects.
---

Most custom hooks should be plain `use...` functions composed from existing hooks.

```dart
({int value, VoidCallback increment}) useCounter() {
  final count = useState(0);
  final increment = useCallback(() => count.value++);
  return (value: count.value, increment: increment);
}
```

Use the low-level API when a reusable object needs its own initialization, updates, optional rebuild logic, deactivation, or disposal.

```dart
class ClockHook extends Hook<DateTime> {
  const ClockHook();

  @override
  ClockHookState createState() => ClockHookState();
}

class ClockHookState extends HookState<DateTime, ClockHook> {
  DateTime now = DateTime.now();
  Timer? timer;

  @override
  void initHook() {
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => now = DateTime.now());
    });
  }

  @override
  DateTime build(BuildContext context) => now;

  @override
  void dispose() => timer?.cancel();
}

DateTime useClock() => use(const ClockHook());
```

Custom low-level hooks must follow the same unconditional ordering rule as built-in hooks.
