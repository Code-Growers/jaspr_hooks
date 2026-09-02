---
title: useBrowserRoute
description: Resolve a typed route from the browser location with a server-rendered fallback.
---

## What it does

`useBrowserRoute(serverRoute, resolve)` returns `serverRoute` during server rendering and the first hydration build, then `resolve(location)` after the first client frame and after every location change. The optional `onLocationChange` callback runs for each change after that initial synchronization, outside of a build, which makes it a safe place for session reconciliation or analytics.

## Signature and parameters

```dart
T useBrowserRoute<T>(
  T serverRoute,
  T Function(Uri location) resolve, {
  void Function(Uri location)? onLocationChange,
})
```

`resolve` runs during build and should be cheap and pure. Give `T` value equality when the caller compares routes.

## Usage

```dart
class AppShell extends HookComponent {
  const AppShell({required this.serverPath, super.key});
  final String serverPath;

  @override
  Component build(BuildContext context) {
    final route = useBrowserRoute<AppRoute>(
      AppRoute(path: serverPath),
      (location) => AppRoute(
        path: location.path,
        created: location.queryParameters['created'] == '1',
      ),
      onLocationChange: (_) => session.reconcile(),
    );

    return Router(route: route);
  }
}
```

## Live demo

<HookDemo name="useBrowserRoute"/>

## Ownership and lifecycle

The hook owns one location subscription and removes it on disposal. The latest `onLocationChange` handler is always used, and a thrown handler is reported without breaking the subscription.

## Server rendering

`serverRoute` is returned unchanged on the server and for the first hydration build. Build it from the request so that server and client markup match.

## Common mistakes

Do not put side effects in `resolve`; use `onLocationChange`. Do not expect `onLocationChange` for the initial synchronization, which is not a change.

## Related APIs

Use `useLocation` when the raw `Uri` is enough. Use `useHistoryState` to navigate.
