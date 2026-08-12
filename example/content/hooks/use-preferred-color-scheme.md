---
title: usePreferredColorScheme
description: Track the browser preference for light or dark color scheme.
---

## What it does

`usePreferredColorScheme()` returns `unknown`, `light`, or `dark` and rebuilds when the relevant media query changes.

It reads `prefers-color-scheme` only after the first client frame, avoiding a server/browser mismatch. Treat it as a preference signal rather than an application theme store.

## Signature and return type

```dart
PreferredColorScheme usePreferredColorScheme()
```

The hook takes no parameters and returns `unknown`, `light`, or `dark`.

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

## Ownership and lifecycle

The hook owns its media-query listener and removes it at disposal. Post-frame synchronization and later distinct changes rebuild the host.

## Server rendering

The result is `PreferredColorScheme.unknown` during SSR and the first hydration build, then synchronizes with the browser.

## Common mistakes

Support `unknown` explicitly and do not read `matchMedia` directly during initial render. A system preference is not a persisted user-selected theme; model overrides in application state.

## Related APIs

Use `useOnPreferredColorSchemeChange` for imperative reactions. Persisted user theme overrides should live in application state.
