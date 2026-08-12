---
title: useMemoized
description: Cache a computed object until an ordered key list changes.
---

## What it does

`useMemoized(valueBuilder, [keys])` evaluates the builder immediately and preserves the result while the hook state and ordered keys remain compatible.

With the default empty key list, the value is created once per mount. Include every value that changes the identity or configuration of the resource. Disposal is not automatic; pair disposable objects with `useEffect` or write a custom hook.

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

## Server rendering

The builder also runs during server rendering. Keep its result deterministic for the first client build and do not construct browser-only objects on the server.

## Related APIs

Use `useCallback` for a stable function and `useRef` for a mutable cell. Use `useEffect` to attach cleanup to a memoized resource.

