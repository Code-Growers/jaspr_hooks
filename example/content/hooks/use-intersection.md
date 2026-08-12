---
title: useIntersection
description: Observe whether a keyed element intersects the viewport or a root.
---

## What it does

`useIntersection` wraps `IntersectionObserver` and returns whether the target intersects plus its visible ratio. It supports lazy work, visibility analytics, and incremental reveal behavior.

## Signature and parameters

```dart
IntersectionSnapshot? useIntersection(
  GlobalNodeKey<web.Element> target, [
  IntersectionOptions options = const IntersectionOptions(),
])
```

Options include an optional keyed `root`, CSS `rootMargin`, thresholds from zero to one, and `freezeOnceVisible`. Invalid or empty thresholds throw `ArgumentError`. The result is `null` until an observation arrives.

## Usage

```dart
import 'package:jaspr_hooks/web.dart';
import 'package:universal_web/web.dart' as web;

final target = useNodeKey<web.Element>();
final visibility = useIntersection(
  target,
  const IntersectionOptions(thresholds: [0, 0.5, 1]),
);

return div(key: target, [
  Component.text('Visible ratio: ${visibility?.ratio ?? 0}'),
]);
```

## Live demo

<HookDemo name="useIntersection"/>

## Ownership and lifecycle

The hook owns and disconnects the observer. Target, root, option, or attached-node changes reset the snapshot. `freezeOnceVisible` disconnects after the first intersecting result while retaining it.

## Server rendering

The value is `null` during SSR and initial hydration. Unsupported browsers also leave it `null`, so essential content must not depend on observer availability.

## Common mistakes

Do not use intersection as an authorization or exact visibility signal; occlusion is not fully represented. Keep thresholds immutable in practice so option equality remains meaningful, and attach both target and optional root keys.

## Related APIs

Use `useNodeKey` for targets, `useElementSize` for geometry, and `useDocumentVisibility` for whole-document visibility.
