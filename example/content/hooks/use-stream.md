---
title: useStream
description: Subscribe to a client Stream and expose its AsyncSnapshot.
---

## What it does

`useStream<T>(stream, initialData:, preserveState:)` reports connection state, latest data, and errors from a client stream.

Keep the stream identity stable, commonly with `useMemoized` or `useStreamController`. Changing streams cancels the old subscription; `preserveState` controls whether the old snapshot data is retained.

## Signature and parameters

```dart
AsyncSnapshot<T> useStream<T>(
  Stream<T>? stream, {
  T? initialData,
  bool preserveState = true,
})
```

The nullable `stream` is the source, `initialData` seeds the snapshot, and `preserveState` controls source-replacement retention. The hook returns the current `AsyncSnapshot<T>`.

## Usage

```dart
class Notifications extends HookComponent {
  const Notifications({super.key});

  @override
  Component build(BuildContext context) {
    final stream = useMemoized<Stream<int>?>(
      () => context.binding.isClient
          ? notificationService.counts
          : null,
      const [],
    );
    final snapshot = useStream(stream, initialData: 0);

    return text('Unread: ${snapshot.data ?? 0}');
  }
}
```

## Live demo

<HookDemo name="useStream"/>

## Ownership and lifecycle

The caller owns the Stream. The hook owns its subscription, cancels it on source replacement or unmount, ignores stale events, and rebuilds for waiting, active, error, and done snapshots.

## Server rendering

Passing a non-null Stream on the server throws `StateError`. Pass `null` during SSR and provide deterministic `initialData` when the rendered output needs a placeholder.

## Common mistakes

Do not create a new Stream on every build. Keep the hook call unconditional and pass a nullable server source. Handle errors and `ConnectionState.done` rather than assuming every event carries data.

## Related APIs

Use `useOnStreamChange` when events trigger callbacks instead of rendering snapshot state. `useStreamController` owns a broadcast source.
