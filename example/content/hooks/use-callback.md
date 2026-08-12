---
title: useCallback
description: Preserve a callback identity until its ordered keys change.
---

## What it does

`useCallback(callback, [keys])` returns the supplied function and keeps the same function instance while the key list remains equal.

Stable identity helps when callbacks are dependencies or are passed to APIs that compare listeners by identity. Capture values deliberately and list them as keys so the callback does not retain stale state.

## Usage

```dart
class SaveButton extends HookComponent {
  const SaveButton(this.documentId, {super.key});
  final String documentId;

  @override
  Component build(BuildContext context) {
    final save = useCallback<VoidCallback>(
      () => saveDocument(documentId),
      [documentId],
    );

    return button(onClick: save, [text('Save')]);
  }
}
```

## Live demo

<HookDemo name="useCallback"/>

## Server rendering

Creating the function is safe during SSR, but its body should run only in the environment intended by the event or caller.

## Related APIs

`useCallback(fn, keys)` is the function-oriented form of `useMemoized(() => fn, keys)`. Use `useEffect` for subscriptions.

