---
title: useFuture
description: Subscribe to a client Future and expose its AsyncSnapshot.
---

## What it does

`useFuture<T>(future, initialData:, preserveState:)` tracks waiting, data, and error states in an `AsyncSnapshot<T>`.

Memoize the future so ordinary rebuilds do not restart it. When the Future identity changes, `preserveState` keeps the prior data while transitioning; set it to false to reset to the initial snapshot.

## Usage

```dart
class Profile extends HookComponent {
  const Profile(this.userId, {super.key});
  final String userId;

  @override
  Component build(BuildContext context) {
    final future = useMemoized<Future<User>?>(
      () => context.binding.isClient
          ? api.loadUser(userId)
          : null,
      [userId],
    );
    final snapshot = useFuture(
      future,
      initialData: const User.loading(),
    );

    return text(snapshot.data?.name ?? 'Loading…');
  }
}
```

## Live demo

<HookDemo name="useFuture"/>

## Server rendering

Passing a non-null Future during server rendering throws `StateError`. Pass `null` on the server and use Jaspr preloading, synchronized state, or another server-data mechanism for real SSR data.

## Related APIs

Use `useStream` for multiple events. See [SSR & hydration](guides/ssr-and-hydration) for deterministic async placeholders.
