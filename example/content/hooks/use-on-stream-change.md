---
title: useOnStreamChange
description: Invoke current callbacks for events from a client Stream.
---

## What it does

`useOnStreamChange<T>` subscribes to a stream and returns its active `StreamSubscription<T>?`.

It supports `onData`, typed `onError`, `onDone`, and `cancelOnError`. Callback changes use the latest configuration without forcing a resubscription; stream identity or `cancelOnError` changes replace the subscription.

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

## Server rendering

Passing a non-null Stream during server rendering throws `StateError`. Supply `null` on the server; subscription callbacks are client lifecycle work.

## Related APIs

Use `useStream` when `AsyncSnapshot` is the desired render model. Use `useEffect` for non-stream subscription APIs.

