---
title: useOnStreamChange
description: Invoke current callbacks for events from a client Stream.
---

## What it does

`useOnStreamChange<T>` subscribes to a stream and returns its active `StreamSubscription<T>?`.

It supports `onData`, typed `onError`, `onDone`, and `cancelOnError`. Callback changes use the latest configuration without forcing a resubscription; stream identity or `cancelOnError` changes replace the subscription.

## Signature and parameters

```dart
StreamSubscription<T>? useOnStreamChange<T>(
  Stream<T>? stream, {
  void Function(T event)? onData,
  void Function(Object error, StackTrace stackTrace)? onError,
  void Function()? onDone,
  bool? cancelOnError,
})
```

The nullable source and callbacks configure a browser subscription. The nullable return is the currently active `StreamSubscription<T>`.

## Usage

```dart
class EventLogger extends HookComponent {
  const EventLogger(this.events, {super.key});
  final Stream<String> events;

  @override
  Component build(BuildContext context) {
    final latest = useState('none');

    useOnStreamChange<String>(
      context.binding.isClient ? events : null,
      onData: (event) => latest.value = event,
      onError: (error, stack) => latest.value = 'error',
    );

    return text('Latest event: ${latest.value}');
  }
}
```

## Live demo

<HookDemo name="useOnStreamChange"/>

## Ownership and lifecycle

The caller owns the Stream; the hook owns and cancels its subscription. Source or `cancelOnError` changes replace it, callback-only changes do not, and unmount cancels the active subscription.

## Server rendering

Passing a non-null Stream during server rendering throws `StateError`. Supply `null` on the server; subscription callbacks are client lifecycle work.

## Common mistakes

Do not manually cancel the returned subscription unless intentionally taking over behavior the hook still assumes. Keep the hook call unconditional, pass a nullable server source, and handle asynchronous errors with the declared two-argument callback.

## Related APIs

Use `useStream` when `AsyncSnapshot` is the desired render model. Use `useEffect` for non-stream subscription APIs.
