---
title: useCallback
description: Preserve a callback identity until its ordered keys change.
---

## What it does

`useCallback(callback, [keys])` returns the supplied function and keeps the same function instance while the key list remains equal.

Stable identity helps when callbacks are dependencies or are passed to APIs that compare listeners by identity. Capture values deliberately and list them as keys so the callback does not retain stale state.

## Signature and parameters

```dart
T useCallback<T extends Function>(
  T callback, [
  List<Object?> keys = const <Object>[],
])
```

`callback` is the function to retain and ordered `keys` define its identity. The return type is the same function type `T`.

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

## Ownership and lifecycle

The hook preserves the function reference but does not own resources used by its body. Default empty keys retain the initial callback for the mount; changed keys replace it without cleanup.

## Server rendering

Creating the function is safe during SSR, but its body should run only in the environment intended by the event or caller.

## Common mistakes

List every captured value whose change must produce a new closure. Stable identity does not make a callback safe after unmount and does not run it automatically. Use `useLatest` when a long-lived callback should read current values without changing identity.

## Related APIs

`useCallback(fn, keys)` is the function-oriented form of `useMemoized(() => fn, keys)`. Use `useEffect` for subscriptions.
