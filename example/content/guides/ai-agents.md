---
title: AI agents
description: Give a coding agent the installation prompt and machine-readable jaspr_hooks reference.
---

## Install with an AI coding agent

Copy the prompt below into an AI coding agent that can edit and test your Jaspr application. It points the agent at the canonical, plain-text reference so it can choose hooks without guessing about Flutter APIs or server behavior.

```text
Install and use jaspr_hooks in this Jaspr application.

Before changing code, read the complete AI-agent documentation at:
https://code-growers.github.io/jaspr_hooks/llms.txt
The rendered AI-agent guide is available at:
https://code-growers.github.io/jaspr_hooks/guides/ai-agents/

Follow that document's hook rules, SSR/hydration contracts, ownership rules,
and per-hook API guidance. Use package:jaspr_hooks/jaspr_hooks.dart for the
universal API, or package:jaspr_hooks/web.dart with package:universal_web/web.dart
for DOM integrations. Do not import flutter_hooks or add Flutter. Confirm the
app uses Jaspr >=0.24.0-beta.0 <0.25.0 and Dart >=3.13.0 <4.0.0, run
`dart pub add jaspr_hooks`, and validate the result with formatting, analysis,
and relevant tests. Summarize every file changed and any behavior that must
remain client-only.
```

The machine-readable reference is available at [llms.txt](https://code-growers.github.io/jaspr_hooks/llms.txt). It is plain UTF-8 text and includes installation guidance, the hook rules, server-rendering constraints, custom-hook lifecycle details, and a concise entry for every exported `use*` API.

## Guidance for agents

An agent should read `llms.txt` before proposing a migration or generating code. It should then inspect the application's existing Jaspr and Dart constraints, choose the smallest appropriate hook host, and preserve server-rendered output.

Do not ask an agent to translate Flutter widget code mechanically. `jaspr_hooks` targets Jaspr's native component tree and intentionally excludes Flutter animation, focus, scroll, text-editing, Material, and Flutter-specific controller integrations. Its Dart convenience controllers are native `jaspr_hooks` APIs.

For deeper examples, each API entry in `llms.txt` links to its rendered hook page. The [human-oriented hook catalog](hooks) contains the same public API set with runnable demonstrations.

## Choosing an entry point

Agents should use the universal import for state, lifecycle, async, action, listenable, and browser-preference hooks:

```dart
import 'package:jaspr_hooks/jaspr_hooks.dart';
```

DOM keys, native events, element observers, and viewport hooks use the web entry point instead. It re-exports the universal API, so importing both is unnecessary:

```dart
import 'package:jaspr_hooks/web.dart';
import 'package:universal_web/web.dart' as web;
```

An agent must preserve the documented `null` or `unknown` SSR fallback for every browser-facing hook. It should supply `getServerSnapshot` to `useExternalStore` when `getSnapshot` is not server-safe, keep actions in client event handlers, and use controller mutation methods instead of modifying collection views.

## Keeping agent context current

Always share the hosted `llms.txt` URL instead of pasting an old copy into project instructions. The stable URL stays the same as compatibility constraints and hook behavior evolve.

Agents that cannot access the network can use the copy committed at `example/web/llms.txt` in this repository, but should verify that their checkout matches the version being installed.

## Canonical sources

- [Package on pub.dev](https://pub.dev/packages/jaspr_hooks)
- [Source repository](https://github.com/Code-Growers/jaspr_hooks)
- [Rendered documentation](https://code-growers.github.io/jaspr_hooks/)
