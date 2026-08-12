---
title: usePreferredMotion
description: Track whether the user prefers reduced motion.
---

## What it does

`usePreferredMotion` is a typed accessibility hook over `prefers-reduced-motion`. It lets applications reduce or remove non-essential animation when the browser reports that preference.

## Signature and parameters

```dart
PreferredMotion usePreferredMotion()
```

The hook takes no parameters and returns `PreferredMotion.unknown`, `.reduce`, or `.noPreference`.

## Usage

```dart
final motion = usePreferredMotion();
final animationDuration = motion == PreferredMotion.reduce
    ? Duration.zero
    : const Duration(milliseconds: 240);
```

## Live demo

<HookDemo name="usePreferredMotion"/>

## Ownership and lifecycle

The underlying media-query subscription is hook-owned and removed at unmount. A preference transition rebuilds the component with the new enum value.

## Server rendering

The value is `unknown` during SSR and the first hydration build, then synchronizes after the first client frame. Treat `unknown` as a deterministic safe default; do not infer a user preference on the server.

## Common mistakes

Reduced motion does not always mean removing all motion. Preserve essential feedback while avoiding large or decorative animation. Do not read browser APIs directly during initial render to bypass the hydration-safe `unknown` state.

## Related APIs

Use `useOnPreferredMotionChange` for transition side effects, `useMediaQuery` for other preferences, and `usePreferredColorScheme` for light/dark appearance.
