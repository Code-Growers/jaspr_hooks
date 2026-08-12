---
title: useOnDocumentVisibilityChange
description: Run a callback when document visibility changes after browser synchronization.
---

## What it does

`useOnDocumentVisibilityChange(callback)` observes visibility transitions and passes `(previous, current)` states to the latest callback.

Initial synchronization establishes the baseline and does not invoke the callback. Later distinct changes invoke it, making the hook suitable for pausing and resuming client services.

## Signature and parameters

```dart
void useOnDocumentVisibilityChange(
  DocumentVisibilityCallback callback,
)
```

`callback(previous, current)` receives distinct visibility states. The hook returns nothing.

## Usage

```dart
class PollingLifecycle extends HookComponent {
  const PollingLifecycle({super.key});

  @override
  Component build(BuildContext context) {
    useOnDocumentVisibilityChange((previous, current) {
      if (current == DocumentVisibility.hidden) {
        poller.pause();
      } else if (current == DocumentVisibility.visible) {
        poller.resume();
      }
    });

    return text('Polling follows tab visibility');
  }
}
```

## Live demo

<HookDemo name="useOnDocumentVisibilityChange"/>

## Ownership and lifecycle

The hook owns and cleans the visibility listener. Updating the callback uses the latest closure without reconnecting solely for callback identity.

## Server rendering

No browser subscription exists during SSR or the initial hydration frame. The callback starts receiving transitions only after client synchronization.

## Common mistakes

Do not expect initial synchronization to invoke the callback. Use `useDocumentVisibility` when visibility belongs in rendered state, and keep pause/resume operations safe across rapid transitions.

## Related APIs

Use `useDocumentVisibility` when the current state belongs in rendered output.
