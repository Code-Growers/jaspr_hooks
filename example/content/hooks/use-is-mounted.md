---
title: useIsMounted
description: Obtain a stable callback that reports whether its hook is still mounted.
---

## What it does

`useIsMounted()` returns an `IsMounted` callback. It returns `true` while attached and becomes `false` after disposal.

Capture the callback before starting delayed work, then check it before touching hook-owned state. Prefer cancellation when an API supports it; the mounted check is a final safety guard.

## Usage

```dart
class DelayedSave extends HookComponent {
  const DelayedSave({super.key});

  @override
  Component build(BuildContext context) {
    final mounted = useIsMounted();
    final status = useState('idle');

    Future<void> save() async {
      await repository.save();
      if (mounted()) status.value = 'saved';
    }

    return button(onClick: save, [text(status.value)]);
  }
}
```

## Live demo

<HookDemo name="useIsMounted"/>

## Server rendering

The callback is valid during SSR but long-running server work should use Jaspr's server data facilities rather than client lifecycle state.

## Related APIs

Async snapshot hooks already guard their own lifecycle. Use `useEffect` cleanup to cancel subscriptions and timers.

