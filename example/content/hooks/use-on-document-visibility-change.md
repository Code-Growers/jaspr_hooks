---
title: useOnDocumentVisibilityChange
description: Run a callback when document visibility changes after browser synchronization.
---

## What it does

`useOnDocumentVisibilityChange(callback)` observes visibility transitions and passes `(previous, current)` states to the latest callback.

Initial synchronization establishes the baseline and does not invoke the callback. Later distinct changes invoke it, making the hook suitable for pausing and resuming client services.

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

## Server rendering

No browser subscription exists during SSR or the initial hydration frame. The callback starts receiving transitions only after client synchronization.

## Related APIs

Use `useDocumentVisibility` when the current state belongs in rendered output.

