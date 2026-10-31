---
title: useId
description: Create deterministic HTML ids across SSR and hydration.
---

`useId` creates an opaque id from the component position and ordered hook slot. It is intended for `id`, `for`, `aria-labelledby`, and `aria-describedby` relationships. Use `HookIdScope` for IDs inside hydrated client islands.

## Signature

```dart
String useId({String prefix = 'jh'});

const HookIdScope({
  required String seed,
  required Component child,
  Key? key,
});
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

The value stays stable across rebuilds and hot reload. Changing the prefix or scope seed replaces the hook state and produces a new id. Scoped IDs remain unique when keyed children move and a new child occupies an old position. Treat the generated string as opaque.

## Server rendering

Put `HookIdScope` inside each independently hydrated `@client` component, above the hook host. Pass a non-empty, document-unique seed as a serialized constructor property. Identical scope seeds, descendant structure, and hook order produce matching server and first-client IDs even when their outer ancestors differ.

```dart
return HookIdScope(
  seed: idScope, // A serialized property, unique for this client boundary.
  child: HookBuilder(builder: (_) {
    final id = useId(prefix: 'email');
    return input(id: id);
  }),
);
```

Nested client islands need their own scopes. Without a scope, matching IDs require the complete server and client element trees to match; island hydration does not guarantee that.

## Common mistakes

Do not use the id as a database identifier, call the hook conditionally, or reuse a scope seed for independent scopes in the same document. Keep stable keys for reorderable children. A scope returned from a hook host's own build does not scope hooks already called in that build.

## Related APIs

Use `useNodeKey` for DOM node access and `useRef` for values that do not appear in markup.
