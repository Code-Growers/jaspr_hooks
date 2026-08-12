---
title: useDebounced
description: Publish an input after it remains unchanged for a duration.
---

## What it does

`useDebounced<T>(value, timeout)` returns the most recently settled value. A changed input restarts the timer.

The initial result is `null` until the timeout completes. Use it to delay search, validation, or other downstream work while still rendering the immediate input separately.

## Signature and parameters

```dart
T? useDebounced<T>(T value, Duration timeout)
```

`value` is the input to settle and `timeout` is the quiet period. The nullable return is the latest settled input, or `null` before any timer completes.

## Usage

```dart
class SearchResults extends HookComponent {
  const SearchResults(this.query, {super.key});
  final String query;

  @override
  Component build(BuildContext context) {
    final settled = useDebounced(
      query,
      const Duration(milliseconds: 300),
    );

    return text(settled == null
        ? 'Waiting…'
        : 'Searching for $settled');
  }
}
```

## Live demo

<HookDemo name="useDebounced"/>

## Ownership and lifecycle

The hook owns its timer. A value or timeout change cancels pending work and starts a replacement on the client; disposal cancels the final timer. The input value remains caller-owned.

## Server rendering

No timer is created during SSR and the hook returns `null`. Design the server markup and first hydration frame around that deterministic placeholder.

## Common mistakes

Do not conditionally skip the hook while input is empty; pass a stable value and handle the nullable result. Debouncing delays a value but does not cancel downstream requests already started from an older value.

## Related APIs

Feed the settled value into `useFuture` for browser-side requests. Use `useEffect` for more explicit cancellation behavior.
