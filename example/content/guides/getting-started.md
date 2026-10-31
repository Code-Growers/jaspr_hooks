---
title: Getting started
description: Add jaspr_hooks and build your first native Jaspr hook component.
---

## Install

Add the package to a Jaspr application:

This preview requires Dart 3.13 or later and Jaspr `>=0.24.0-beta.0 <0.25.0`. For Jaspr 0.23 applications, keep using the 0.2 release line.

```yaml
dependencies:
  jaspr_hooks: ^0.3.0-beta.0
```

Import the public library and extend `HookComponent`:

```dart
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_hooks/jaspr_hooks.dart';

class Greeting extends HookComponent {
  const Greeting({super.key});

  @override
  Component build(BuildContext context) {
    final excited = useState(false);

    return button(
      onClick: () => excited.value = !excited.value,
      [Component.text(excited.value ? 'Hello!' : 'Hello')],
    );
  }
}
```

Use `StatefulHookComponent` when hooks need to coexist with a Jaspr `State`, `PreloadStateMixin`, or `SyncStateMixin`.
For a small hook-enabled subtree, use `HookBuilder`.

## Choose the next page

- Read the [rules of hooks](guides/rules-of-hooks) before extracting custom hooks.
- Read [SSR and hydration](guides/ssr-and-hydration) before using effects, futures, streams, or browser APIs.
- Browse the [hook catalog](hooks) for API-specific examples.
