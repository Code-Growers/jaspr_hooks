---
title: useMediaQuery
description: Track whether the browser matches an arbitrary CSS media query.
---

## What it does

`useMediaQuery` observes one media-query string and returns an explicit three-state result. It can represent browser breakpoints, input capabilities, contrast, print mode, orientation, and other `matchMedia` features.

## Signature and parameters

```dart
MediaQueryMatch useMediaQuery(String query)
```

`query` is the CSS media query to evaluate. The result is `unknown`, `matches`, or `doesNotMatch`; changing the query resets and replaces the subscription.

## Usage

```dart
final compact = useMediaQuery('(max-width: 720px)');

return text(switch (compact) {
  MediaQueryMatch.unknown => 'Loading layout preference',
  MediaQueryMatch.matches => 'Compact navigation',
  MediaQueryMatch.doesNotMatch => 'Wide navigation',
});
```

## Live demo

<HookDemo name="useMediaQuery"/>

## Ownership and lifecycle

The hook owns the browser media-query listener and removes it on query replacement or unmount. It rebuilds only when the three-state value changes.

## Server rendering

The result is `unknown` during SSR and the first hydration build. After the first client frame the hook reads and subscribes to the real query, avoiding server/client markup divergence.

## Common mistakes

Do not conditionally call the hook for different breakpoints; pass the selected query consistently at the same hook position. Prefer CSS for purely visual responsive styling and use this hook when behavior or rendered structure truly depends on the result.

## Related APIs

`useOnMediaQueryChange` observes transitions without rebuilding automatically. `usePreferredColorScheme` and `usePreferredMotion` provide typed wrappers for common preferences.
