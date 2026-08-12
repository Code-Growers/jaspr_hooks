---
title: useFuture
description: Subscribe to a client Future and expose its AsyncSnapshot.
---

## What it does

`useFuture<T>(future, initialData:, preserveState:)` tracks waiting, data, and error states in an `AsyncSnapshot<T>`.

Memoize the future so ordinary rebuilds do not restart it. When the Future identity changes, `preserveState` keeps the prior data while transitioning; set it to false to reset to the initial snapshot.

## Signature and parameters

```dart
AsyncSnapshot<T> useFuture<T>(
  Future<T>? future, {
  T? initialData,
  bool preserveState = true,
})
```

`future` may be null, `initialData` seeds the snapshot, and `preserveState` controls replacement retention. The hook returns the current `AsyncSnapshot<T>`.

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

## Ownership and lifecycle

The caller owns the Future, which Dart cannot cancel. The hook owns observation, ignores stale completions after source replacement or disposal, and rebuilds for waiting, data, or error transitions.

## Server rendering

Passing a non-null Future during server rendering throws `StateError`. Pass `null` on the server and use Jaspr preloading, synchronized state, or another server-data mechanism for real SSR data.

## Common mistakes

Do not create a new Future on every build; preserve it with `useMemoized`. Keep the hook call unconditional and select a nullable source per platform. Handle both `snapshot.error` and all connection states.

## Related APIs

Use `useStream` for multiple events. See [SSR & hydration](guides/ssr-and-hydration) for deterministic async placeholders.
