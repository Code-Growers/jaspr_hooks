---
title: Hooks for Jaspr
description: Compose local state, effects, async work, listenables, and browser lifecycle logic in native Jaspr components.
image: images/jaspr_hooks_mascot_512.png
imageAlt: Original fishing-dog mascot for jaspr_hooks
---

`jaspr_hooks` brings the ordered hook model popularized by `flutter_hooks` to Jaspr's native HTML component tree.
It does not embed Flutter, and it keeps server rendering and hydration behavior explicit.

<Info>
New here? Start with [Getting started](guides/getting-started), then read the [rules of hooks](guides/rules-of-hooks).
</Info>

## A familiar component

```dart
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_hooks/jaspr_hooks.dart';

class Counter extends HookComponent {
  const Counter({super.key});

  @override
  Component build(BuildContext context) {
    final count = useState(0);

    return button(
      onClick: () => count.value++,
      [Component.text('Count: ${count.value}')],
    );
  }
}
```

## What the package covers

- Ordered state and lifecycle primitives.
- Futures, streams, and Jaspr listenables with explicit SSR contracts.
- Browser document visibility and preferred color-scheme hooks.
- `HookComponent`, `StatefulHookComponent`, and `HookBuilder` integration points.
- A low-level `Hook` / `HookState` API for reusable custom hooks.

Browse the complete [hook catalog](hooks). Every hook page includes an interactive client island and a focused example.
