---
title: Migrating from flutter_hooks
description: Map Flutter hook components and portable hooks to native Jaspr equivalents.
---

`jaspr_hooks` preserves the ordered hook model and familiar names, but it targets Jaspr's `Component` / `Element` tree rather than Flutter's `Widget` / `Element` tree.

## Component mapping

| Flutter | Jaspr |
| --- | --- |
| `HookWidget` | `HookComponent` |
| `StatefulHookWidget` | `StatefulHookComponent` |
| `HookBuilder` | `HookBuilder` |
| `Widget build(BuildContext)` | `Component build(BuildContext)` |
| Flutter `ValueNotifier` | Jaspr `ValueNotifier` |

```dart
// Before: Flutter
class Counter extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final count = useState(0);
    return TextButton(onPressed: () => count.value++, child: Text('${count.value}'));
  }
}

// After: Jaspr
class Counter extends HookComponent {
  @override
  Component build(BuildContext context) {
    final count = useState(0);
    return button(onClick: () => count.value++, [Component.text('${count.value}')]);
  }
}
```

## Portable hooks

State, memoization, reducers, futures, streams, and listenables have close counterparts. Keep the same unconditional ordering rules and review each API page for small signature differences.

## Hooks that intentionally do not migrate

Flutter-only controllers and lifecycle concepts are outside this package: animation/ticker hooks, scroll/page/tab controllers, focus and text-editing controllers, overlays, Material/Cupertino controllers, and Flutter app lifecycle hooks.

Use native HTML events and browser APIs in Jaspr. This package provides document visibility and preferred color-scheme hooks as web-focused replacements for two common lifecycle needs.

## Review SSR semantics

Unlike a typical Flutter app, a Jaspr component may build on the server before hydrating in the browser. Effects are client-only, live async sources must be `null` on the server, and hook state is recreated during hydration. Read [SSR and hydration](guides/ssr-and-hydration) before migrating side effects or data subscriptions.
