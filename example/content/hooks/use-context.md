---
title: useContext
description: Read the BuildContext that owns the current hook invocation.
---

## What it does

`useContext()` returns the `BuildContext` of the `HookComponent`, `StatefulHookComponent`, or `HookBuilder` whose build is currently executing.

Use it when an API needs inherited data or the Jaspr binding and passing the build context through helpers would be noisy. Calling it outside an active hook build throws `StateError`.

## Usage

```dart
class EnvironmentBadge extends HookComponent {
  const EnvironmentBadge({super.key});

  @override
  Component build(BuildContext context) {
    final hookContext = useContext();
    final environment =
        hookContext.binding.isClient ? 'browser' : 'server';

    return span([text(environment)]);
  }
}
```

## Live demo

<HookDemo name="useContext"/>

## Server rendering

The context is available during both server rendering and client builds. Branch only when the underlying operation is genuinely platform-specific; keep the rendered first client frame hydration-compatible.

## Related APIs

Use `HookBuilder` for a small hook-enabled region. The low-level `use` API also exposes the same context to `HookState.build`.

