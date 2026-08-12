---
title: useContext
description: Read the BuildContext that owns the current hook invocation.
---

## What it does

`useContext()` returns the `BuildContext` of the `HookComponent`, `StatefulHookComponent`, or `HookBuilder` whose build is currently executing.

Use it when an API needs inherited data or the Jaspr binding and passing the build context through helpers would be noisy. Calling it outside an active hook build throws `StateError`.

## Signature and return type

```dart
BuildContext useContext()
```

The hook has no parameters and returns the context for the currently executing hook host build.

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

## Ownership and lifecycle

Jaspr owns the context. The hook neither caches nor disposes it; the value is valid only according to the owning element lifecycle. Read inherited dependencies during build rather than retaining the context for later work.

## Server rendering

The context is available during both server rendering and client builds. Branch only when the underlying operation is genuinely platform-specific; keep the rendered first client frame hydration-compatible.

## Common mistakes

Do not call the hook from an event handler or outside an active build. Use `useInherited<T>` when the goal is a typed inherited dependency, and avoid storing `BuildContext` in shared application state.

## Related APIs

Use `HookBuilder` for a small hook-enabled region. The low-level `use` API also exposes the same context to `HookState.build`.
