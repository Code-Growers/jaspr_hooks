---
title: useDebounced
description: Publish an input after it remains unchanged for a duration.
---

## What it does

`useDebounced<T>(value, timeout)` returns the most recently settled value. A changed input restarts the timer.

The initial result is `null` until the timeout completes. Use it to delay search, validation, or other downstream work while still rendering the immediate input separately.

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

## Server rendering

No timer is created during SSR and the hook returns `null`. Design the server markup and first hydration frame around that deterministic placeholder.

## Related APIs

Feed the settled value into `useFuture` for browser-side requests. Use `useEffect` for more explicit cancellation behavior.

