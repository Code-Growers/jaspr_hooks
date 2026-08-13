---
title: useClipboard
description: Read and write plain text with observable Clipboard API state.
---

`useClipboard` returns a stable controller with support detection, operation status, latest text, and error state.

## Signature

```dart
ClipboardController useClipboard();
```

## Lifecycle

```dart
final clipboard = useClipboard();
await clipboard.writeText('Copied from Jaspr');
```

<HookDemo name="useClipboard"/>

Overlapping operations use latest-operation-wins state updates. Completed Futures still return their own result.

## Server rendering

The controller is deterministic with `isSupported == false` and `status == idle`; mutations reject until browser activation.

## Common mistakes

Clipboard access usually requires HTTPS, permission, and a user gesture. Always handle rejected Futures and provide visible feedback.

## Related APIs

Use `useAsyncAction` for richer async workflows and `useEvent` for stable gesture handlers.
