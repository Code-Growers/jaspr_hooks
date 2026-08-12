---
title: useInherited
description: Read and subscribe to a typed Jaspr inherited component.
---

## What it does

`useInherited` finds the nearest `InheritedComponent` of type `T` and registers the current hook host as a dependent. Jaspr rebuilds the host when that inherited component reports a relevant change.

## Signature and parameters

```dart
T? useInherited<T extends InheritedComponent>({Object? aspect})
```

`T` selects the inherited component type. The optional `aspect` is forwarded to Jaspr for implementations that support selective dependencies. The return value is the nearest matching component or `null`.

## Usage

```dart
final theme = useInherited<AppTheme>();

return text(theme?.mode.name ?? 'No app theme');
```

## Live demo

<HookDemo name="useInherited"/>

## Ownership and lifecycle

The inherited component owns its value. This hook only registers a dependency during build and does not dispose or mutate the ancestor. The dependency follows the normal Jaspr element lifecycle when the component moves or unmounts.

## Server rendering

Inherited lookup works during server and client builds. Ensure the same ancestor structure and deterministic value are available to the first hydration build when they affect HTML.

## Common mistakes

Do not force-unwrap the nullable result unless an ancestor is guaranteed. Use the aspect vocabulary defined by the inherited component; arbitrary aspect objects cannot make a component selective by themselves.

## Related APIs

`useContext` exposes the complete `BuildContext`. `useExternalStore` subscribes to dependencies outside the component tree, and `jaspr_riverpod` is better suited to larger provider graphs.
