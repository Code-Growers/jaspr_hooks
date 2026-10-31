---
title: useMemoized
description: Cache a computed object until an ordered key list changes.
---

## What it does

`useMemoized(valueBuilder, [keys])` evaluates the builder immediately and preserves the result while the hook state and ordered keys remain compatible.

With the default empty key list, the value is created once per mount. Include every value that changes the identity or configuration of the value. Disposal is not automatic; use `useDisposable` for an owned resource.

## Signature and parameters

```dart
T useMemoized<T>(
  T Function() valueBuilder, [
  List<Object?> keys = const <Object>[],
])
```

`valueBuilder` runs immediately when state is created. Ordered `keys` define cache identity, and the cached `T` is returned.

## Usage

```dart
class FormatterView extends HookComponent {
  const FormatterView(this.locale, {super.key});
  final String locale;

  @override
  Component build(BuildContext context) {
    final formatter = useMemoized(
      () => MessageFormatter(locale),
      [locale],
    );
    return text(formatter.format('welcome'));
  }
}
```

## Live demo

<HookDemo name="useMemoized"/>

## Ownership and lifecycle

The hook retains the value but assumes no disposal ownership. A key change drops the old reference and computes a replacement; unmount drops the final reference without cleanup.

Development hot reload also recomputes the value on the next build, using the latest builder. Use `useRef` or a state hook for mutable state that must survive reload. See [Hot reload](guides/hot-reload).

## Server rendering

The builder also runs during server rendering. Keep its result deterministic for the first client build and do not construct browser-only objects on the server.

## Common mistakes

Do not omit changing identity inputs from keys or mutate keys after passing them. Do not use memoization for side effects. Choose `useDisposable` when replacement or unmount must release the value.

## Related APIs

Use `useCallback` for a stable function, `useRef` for a mutable cell, and `useDisposable` for keyed ownership with cleanup.
