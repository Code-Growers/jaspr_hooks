---
title: useOnWindowFocus
description: React when the user returns to the window or the document becomes visible again.
---

## What it does

`useOnWindowFocus(callback)` invokes the latest callback when the window fires `focus`. By default it also fires when the document becomes visible again, which covers returning to a background tab where browsers fire no `focus` event. Use it to refresh data the user may have changed elsewhere.

## Signature and parameters

```dart
void useOnWindowFocus(
  void Function() callback, {
  bool includeVisibilityChange = true,
})
```

Pass `includeVisibilityChange: false` to listen to `focus` only.

## Usage

```dart
class OfferList extends HookComponent {
  const OfferList({super.key});

  @override
  Component build(BuildContext context) {
    final offers = useOffers();
    useOnWindowFocus(() {
      if (!offers.isLoading) offers.reload();
    });

    return ul([for (final offer in offers.value) li([text(offer.title)])]);
  }
}
```

## Live demo

<HookDemo name="useOnWindowFocus"/>

## Ownership and lifecycle

The hook attaches its listeners after the first client frame and removes them on disposal. Changing `includeVisibilityChange` replaces the listeners. One user action can fire both underlying events, so keep the callback idempotent.

## Server rendering

Nothing attaches on the server.

## Common mistakes

Do not start unguarded work from the callback. Check loading state first, because a tab switch can fire the callback twice in quick succession.

## Related APIs

Use `useOnDocumentVisibilityChange` for the visibility transition alone, including becoming hidden. Use `useDocumentVisibility` when the rendered output depends on visibility.
