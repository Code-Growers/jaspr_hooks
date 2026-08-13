---
title: useId
description: Create deterministic HTML ids across SSR and hydration.
---

`useId` creates an id from the component tree position and ordered hook slot. It is intended for `id`, `for`, `aria-labelledby`, and `aria-describedby` relationships.

## Signature

```dart
String useId({String prefix = 'jh'});
```

## Lifecycle

```dart
final id = useId(prefix: 'email');
return div([
  label(attributes: {'for': id}, [.text('Email')]),
  input(id: id),
]);
```

<HookDemo name="useId"/>

The value stays stable across rebuilds. Changing the prefix replaces the hook state and produces a new id.

## Server rendering

Server and first-client builds produce the same value when their component tree and hook order match.

## Common mistakes

Do not use the id as a database identifier or call the hook conditionally. Do not reorder hydrated sibling components without stable keys.

## Related APIs

Use `useNodeKey` for DOM node access and `useRef` for values that do not appear in markup.
