![A teal dog holding a fishing rod whose line ends in a hook](https://raw.githubusercontent.com/Code-Growers/jaspr_hooks/main/assets/brand/jaspr_hooks_mascot_512.png)

# jaspr_hooks

Ordered lifecycle and state hooks for native
[Jaspr](https://pub.dev/packages/jaspr) components.

`jaspr_hooks` brings the composability of `flutter_hooks` to Jaspr's own
component and element tree. It does not embed Flutter and produces normal Jaspr
HTML on the server and in the browser.

> `0.3.0-beta.0` is a preview. The API is intentionally being validated in real
> Jaspr applications before `0.3.0`.

## Install

```yaml
dependencies:
  jaspr: ^0.24.0-beta.0
  jaspr_hooks: ^0.3.0-beta.0
```

This preview supports Dart `>=3.13.0 <4.0.0` and Jaspr
`>=0.24.0-beta.0 <0.25.0`. Jaspr 0.23 applications can keep using
`jaspr_hooks: ^0.2.0` with Dart 3.8 or later.

## A counter without a State class

```dart
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_hooks/jaspr_hooks.dart';

class Counter extends HookComponent {
  const Counter({super.key});

  @override
  Component build(BuildContext context) {
    final count = useState(0);

    return button(
      onClick: () => count.value++,
      [Component.text('Count: ${count.value}')],
    );
  }
}
```

Hooks must be called unconditionally and in the same order on every build.
Reusable custom hooks are ordinary functions whose names begin with `use`:

```dart
ValueNotifier<int> useTrackedCount([int initialValue = 0]) {
  return useState(initialValue);
}
```

For lower-level lifecycle objects, extend `Hook<R>` and
`HookState<R, YourHook>` and register them with `use`.

## Included hooks

| Category | Hooks |
| --- | --- |
| Framework | `use`, `useContext`, `useId`, `useEvent` |
| Foundation | `useLatest`, `useDisposable`, `useExternalStore`, `useInherited`, `useImperativeHandle`, `useTimeout`, `useInterval` |
| Primitives | `useState`, `useGuardedState`, `useEffect`, `usePostFrameEffect`, `useMemoized`, `useCallback`, `useRef`, `useValueChanged` |
| Lifecycle/state | `usePrevious`, `useReducer`, `useIsMounted`, `useDebounced` |
| Convenience state | `useToggle`, `useCounter`, `useList`, `useMap`, `useSet`, `useQueue`, `useEffectOnce`, `useMount`, `useUnmount`, `useUpdateEffect`, `usePostFrameUpdateEffect` |
| Async | `useFuture`, `useStream`, `useStreamController`, `useOnStreamChange` |
| Actions | `useAsyncAction`, `useOptimistic` |
| Listenables | `useListenable`, `useListenableSelector`, `useValueNotifier`, `useValueListenable`, `useOnListenableChange` |
| Browser lifecycle | `useDocumentVisibility`, `useOnDocumentVisibilityChange`, `usePreferredColorScheme`, `useOnPreferredColorSchemeChange`, `useMediaQuery`, `useOnMediaQueryChange`, `usePreferredMotion`, `useOnPreferredMotionChange`, `useLocation`, `useBrowserRoute`, `useOnWindowFocus` |
| Browser DOM | `useNodeKey`, `useFocus`, `useFocusWithin`, `useActiveElement`, `useAbortController`, `useAnimationFrame`, `useHistoryState`, `useClipboard`, `useElementSize`, `useWindowSize`, `useIntersection`, `useEventListener`, `useOnClickOutside`, `useHover`, `useMutationObserver` |

The universal entry point contains every hook except direct DOM integrations:

```dart
import 'package:jaspr_hooks/jaspr_hooks.dart';
```

When a component needs DOM node, observer, or native-event types, import the
web entry point instead. It re-exports the universal API:

```dart
import 'package:jaspr_hooks/web.dart';
import 'package:universal_web/web.dart' as web;
```

Use `HookComponent` in place of `StatelessComponent`,
`StatefulHookComponent` when a Jaspr `State` is still useful, or `HookBuilder`
for a small hook-enabled subtree.

## Server rendering and hydration

Jaspr renders a new component tree on the server and hydrates with a separate
tree in the browser. Hook state is therefore not serialized automatically.

For IDs inside a hydrated `@client` boundary, put a `HookIdScope` above the
hook host and pass its document-unique seed as a serialized property:

```dart
return HookIdScope(
  seed: idScope,
  child: HookBuilder(builder: (_) {
    final id = useId();
    return Component.element(tag: 'input', id: id);
  }),
);
```

Nested client islands need their own scopes. Unscoped `useId` values require
matching complete element trees to match across server and client.

Await server data in `AsyncStatelessComponent` or `AsyncBuilder`, then return a
synchronous hook host. `StatefulHookComponent` also works with Jaspr's
`PreloadStateMixin`. Direct hook calls in async builds are unsupported. Keep
server children mounted in the initial HTML and toggle their visibility from
the client wrapper. See the [server components guide](https://code-growers.github.io/jaspr_hooks/guides/server-components/).

`useDisposable` cleanup follows replacement and element unmounting. Server
response completion does not guarantee unmount; manage request resources
explicitly with `try`/`finally` in their caller.

Development hot reload preserves matching state, refs, IDs and node keys.
Memoized values, callbacks, effects and disposable resources refresh on the
next build; custom hooks can override `HookState.reassemble`. Use hot restart
for structural hook changes. See the [hot reload guide](https://code-growers.github.io/jaspr_hooks/guides/hot-reload/).

| API | Server/static rendering | Browser |
| --- | --- | --- |
| `useEffect` | Effect is skipped | Runs synchronously during build; state it assigns renders after the frame |
| `usePostFrameEffect`, `usePostFrameUpdateEffect` | Effect is skipped | Runs after the frame |
| `useFuture`, `useStream`, `useOnStreamChange` | Source must be `null` | Subscribes normally |
| Listenable hooks | Read initial value, attach no listener | Attach listeners |
| `useDebounced`, `useTimeout`, `useInterval` | Create no timer | Run timers normally |
| `useExternalStore` | Reads `getServerSnapshot`, or `getSnapshot` without one | Hydrates from the server snapshot, then subscribes |
| Async and optimistic actions | Read deterministic initial state; do not mutate | Dispatch and mutate from event handlers |
| Browser lifecycle value hooks | Return `unknown` | Synchronize after the first frame |
| `useLocation`, `useBrowserRoute` | Return `null` or the server route | Synchronize after the first frame |
| Browser DOM value hooks | Return inert state, `null`, or an unattached key | Attach after the first frame |

Pass async sources conditionally:

```dart
final future = useMemoized(
  () => kIsWeb ? loadFromBrowser() : null,
  const [],
);
final snapshot = useFuture(future);
```

Use Jaspr's `PreloadStateMixin`, `AsyncStatelessComponent`, serialized
`@client` properties, or `jaspr_riverpod` for server-loaded data. Keep initial
state and memoized values deterministic so the server and first client build
produce compatible markup.

Use `usePostFrameEffect` for DOM reads or writes. `useEffect` intentionally
matches `flutter_hooks` synchronous client timing.

## Differences from flutter_hooks

`flutter_hooks` cannot be imported by native Jaspr components because its
runtime is coupled to Flutter widgets and elements. This package adapts its
ordered-hook design to public Jaspr element APIs.

- Jaspr `Component`, `BuildContext`, `ValueNotifier`, `AsyncSnapshot`, and
  `ConnectionState` replace Flutter types.
- Effects and live subscriptions are SSR-aware.
- Document visibility and preferred color scheme replace Flutter application
  lifecycle and platform brightness hooks.
- Flutter animation, ticker, scroll, focus, text editing, overlay, Material,
  Cupertino, keep-alive, controller, and `reassemble` hooks are intentionally
  absent.
- The internal element mixin is not public; `Hook` and `HookState` are the
  supported custom-hook extension points.

## Documentation and example

The `example/` directory is a static Jaspr Content application with
one guide and interactive demo for every hook. It is also the source deployed
to GitHub Pages and displayed in pub.dev's Example tab.

## AI coding agents

The documentation home page includes an **AI install prompt** button that
copies compatibility, installation, hook-rule, and SSR instructions for a
coding agent.

- [AI-agent guide](https://code-growers.github.io/jaspr_hooks/guides/ai-agents/)
- [Machine-oriented hook reference](https://code-growers.github.io/jaspr_hooks/llms.txt)

The machine reference documents every exported hook and is checked against the
canonical hook catalog and package version constraints in CI.

## Status and releases

pub.dev releases are prepared by the repository's release checks and published
manually from a clean local checkout.

## Credits and license

`jaspr_hooks` is inspired by and partially adapted from
[`flutter_hooks`](https://github.com/rrousselGit/flutter_hooks), copyright
Remi Rousselet, under the MIT License. The exact source baseline and full
license are recorded in `THIRD_PARTY_NOTICES.md`.

This is an independent project. It is not maintained, sponsored, or endorsed
by the Jaspr or `flutter_hooks` projects. The fishing-dog artwork is an original
project mascot and is not derived from Jaspr's mascot.

The package itself is available under the MIT License in `LICENSE`.
