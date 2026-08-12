---
title: useOnPreferredColorSchemeChange
description: Run a callback when the preferred browser color scheme changes.
---

## What it does

`useOnPreferredColorSchemeChange(callback)` observes media-query transitions and passes `(previous, current)` preferences.

The latest callback is used without recreating the subscription. Initial browser synchronization establishes a baseline and is not reported as a user change.

## Signature and parameters

```dart
void useOnPreferredColorSchemeChange(
  PreferredColorSchemeCallback callback,
)
```

`callback(previous, current)` receives distinct typed preferences. The hook returns nothing.

## Usage

```dart
class SchemeAnalytics extends HookComponent {
  const SchemeAnalytics({super.key});

  @override
  Component build(BuildContext context) {
    useOnPreferredColorSchemeChange((previous, current) {
      analytics.record('scheme', {
        'from': previous.name,
        'to': current.name,
      });
    });

    return text('Scheme changes are observed');
  }
}
```

## Live demo

<HookDemo name="useOnPreferredColorSchemeChange"/>

## Ownership and lifecycle

The hook owns and removes the media-query listener. Callback updates use the latest closure without firing for configuration alone.

## Server rendering

No media-query listener exists during SSR. Observation starts after the first client frame, so hydration remains deterministic.

## Common mistakes

Do not treat initial browser synchronization as a change event. Use `usePreferredColorScheme` for render state, and keep persisted application theme overrides separate from the browser preference.

## Related APIs

Use `usePreferredColorScheme` when the preference should rebuild visible UI.
