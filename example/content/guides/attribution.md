---
title: Attribution and licensing
description: How jaspr_hooks credits and complies with the upstream flutter_hooks implementation.
---

The hook runtime and several hook implementations are substantially adapted from [`flutter_hooks`](https://github.com/rrousselGit/flutter_hooks), created by Remi Rousselet and contributors.

## Upstream license

`flutter_hooks` is distributed under the MIT License. Adapted source files retain an attribution header, and this repository includes the upstream copyright and permission notice in `THIRD_PARTY_NOTICES.md`.

```text
Portions adapted from flutter_hooks 0.21.3+1.
Copyright (c) 2018 Remi Rousselet.
Licensed under the MIT License.
```

The package's own `LICENSE` and the upstream notice should remain present in source distributions. Removing a code comment is not a substitute for preserving the required copyright and permission notice.

## What was adapted

- Ordered hook registration and state preservation by runtime type and keys.
- `Hook` / `HookState` lifecycle concepts and reverse-order disposal.
- Portable primitives such as state, memoization, effects, futures, streams, and listenables.

## What changed for Jaspr

- Integration targets Jaspr `BuildableElement`, `Component`, and `BuildContext` APIs.
- Effects and live subscriptions follow explicit server-rendering contracts.
- Flutter diagnostics, reassemble behavior, widgets, and controllers are not copied.
- Browser lifecycle hooks are Jaspr/web-specific additions.

This page is a project-maintenance summary, not legal advice. Refer to the license files in the package for the authoritative terms.
