---
title: useOnPreferredMotionChange
description: Run a callback when the user's reduced-motion preference changes.
---

## What it does

`useOnPreferredMotionChange` observes the browser's `prefers-reduced-motion` setting and invokes the latest callback for later transitions between reduced motion and no preference.

## Signature and parameters

```dart
void useOnPreferredMotionChange(
  PreferredMotionCallback callback,
)
```

The callback receives `(PreferredMotion previous, PreferredMotion current)`. The hook takes no other parameters and returns nothing.

## Usage

```dart
useOnPreferredMotionChange((previous, current) {
  animationEngine.setReducedMotion(current == PreferredMotion.reduce);
});
```

## Live demo

<HookDemo name="useOnPreferredMotionChange"/>

## Ownership and lifecycle

The hook owns its media-query listener and removes it at unmount. It reads the latest callback from the preserved hook configuration without reconnecting solely because the closure changed.

## Server rendering

No listener or callback runs on the server. Initial post-frame synchronization only establishes the baseline, so the callback does not fire with `unknown` during hydration.

## Common mistakes

Use `usePreferredMotion` when render output should respond to the setting. A callback mutation does not itself rebuild. Apply the preference consistently across all animation systems rather than updating one isolated effect.

## Related APIs

`usePreferredMotion` returns the current typed value. `useOnMediaQueryChange` handles arbitrary queries and `useOnPreferredColorSchemeChange` handles appearance transitions.
