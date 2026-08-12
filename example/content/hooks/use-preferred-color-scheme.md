---
title: usePreferredColorScheme
description: Track the browser preference for light or dark color scheme.
---

## What it does

`usePreferredColorScheme()` returns `unknown`, `light`, or `dark` and rebuilds when the relevant media query changes.

It reads `prefers-color-scheme` only after the first client frame, avoiding a server/browser mismatch. Treat it as a preference signal rather than an application theme store.

## Usage

```dart
class SchemeBadge extends HookComponent {
  const SchemeBadge({super.key});

  @override
  Component build(BuildContext context) {
    final scheme = usePreferredColorScheme();
    return text('Preference: ${scheme.name}');
  }
}
```

## Live demo

<HookDemo name="usePreferredColorScheme"/>

## Server rendering

The result is `PreferredColorScheme.unknown` during SSR and the first hydration build, then synchronizes with the browser.

## Related APIs

Use `useOnPreferredColorSchemeChange` for imperative reactions. Persisted user theme overrides should live in application state.

