---
title: useGuardedState
description: Own rebuild-triggering state that ignores writes after the component unmounts.
---

## What it does

`useGuardedState(initialData)` returns a `GuardedValueNotifier`. Assigning a different `.value` rebuilds the owning component, exactly like `useState`. Once the component unmounts, the notifier is disposed and every later assignment is silently dropped instead of failing Jaspr's disposed-notifier assertion.

Use it for state that is written after an `await`, a timer, or a browser callback. It removes the `IsMounted` check that every such write otherwise needs.

## Signature and parameters

```dart
GuardedValueNotifier<T> useGuardedState<T>(T initialData)
```

`initialData` is used only when the hook state is first created. The returned notifier exposes `isDisposed` for callers that want to skip follow-up work after the owner is gone.

## Usage

```dart
class SaveButton extends HookComponent {
  const SaveButton({super.key});

  @override
  Component build(BuildContext context) {
    final status = useGuardedState('idle');

    Future<void> save() async {
      status.value = 'saving';
      await repository.save();
      status.value = 'saved';
    }

    return button(onClick: save, [text(status.value)]);
  }
}
```

## Live demo

<HookDemo name="useGuardedState"/>

## Ownership and lifecycle

The hook owns the notifier and disposes it when the hook is removed. Assignments made while mounted rebuild the owner, including assignments made during a build, which are rendered after the frame. Assignments after disposal change nothing and notify nobody.

## Server rendering

The initializer runs on both platforms and must be deterministic. The notifier can be read during server rendering; nothing subscribes there.

## Common mistakes

Do not rely on a dropped write to cancel work. Cancel timers, subscriptions, and requests in an effect cleanup, and use the guard only for the final state assignment. Prefer `useState` when a late write would indicate a bug you want surfaced.

## Related APIs

`useState` keeps strict disposal semantics. `useIsMounted` remains useful for skipping non-state follow-up work such as navigation or focus after an asynchronous boundary.
