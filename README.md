<p align="center">
  <img src="assets/brand/jaspr_hooks_mascot_512.png" width="260" alt="A teal dog holding a fishing rod whose line ends in a hook">
</p>

# jaspr_hooks

Ordered lifecycle and state hooks for native
[Jaspr](https://pub.dev/packages/jaspr) components.

`jaspr_hooks` brings the composability of `flutter_hooks` to Jaspr's own
component and element tree. It does not embed Flutter and produces normal Jaspr
HTML on the server and in the browser.

> `0.1.0-dev.1` is a preview. The API is intentionally being validated in real
> Jaspr applications before `0.1.0`.

## Install

```yaml
dependencies:
  jaspr: ^0.23.3
  jaspr_hooks: ^0.1.0-dev.1
```

The package supports Dart `>=3.8.0 <4.0.0` and Jaspr 0.23.x.

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
ValueNotifier<int> useCounter([int initialValue = 0]) {
  final counter = useState(initialValue);

  useEffect(() {
    // Subscribe or perform another client-side effect here.
    return null;
  }, const []);

  return counter;
}
```

For lower-level lifecycle objects, extend `Hook<R>` and
`HookState<R, YourHook>` and register them with `use`.

## Included hooks

| Category | Hooks |
| --- | --- |
| Framework | `use`, `useContext` |
| Primitives | `useState`, `useEffect`, `usePostFrameEffect`, `useMemoized`, `useCallback`, `useRef`, `useValueChanged` |
| Lifecycle/state | `usePrevious`, `useReducer`, `useIsMounted`, `useDebounced` |
| Async | `useFuture`, `useStream`, `useStreamController`, `useOnStreamChange` |
| Listenables | `useListenable`, `useListenableSelector`, `useValueNotifier`, `useValueListenable`, `useOnListenableChange` |
| Browser lifecycle | `useDocumentVisibility`, `useOnDocumentVisibilityChange`, `usePreferredColorScheme`, `useOnPreferredColorSchemeChange` |

Use `HookComponent` in place of `StatelessComponent`,
`StatefulHookComponent` when a Jaspr `State` is still useful, or `HookBuilder`
for a small hook-enabled subtree.

## Server rendering and hydration

Jaspr renders a new component tree on the server and hydrates with a separate
tree in the browser. Hook state is therefore not serialized automatically.

| API | Server/static rendering | Browser |
| --- | --- | --- |
| `useEffect` | Effect is skipped | Runs synchronously during build |
| `usePostFrameEffect` | Effect is skipped | Runs after the frame |
| `useFuture`, `useStream`, `useOnStreamChange` | Source must be `null` | Subscribes normally |
| Listenable hooks | Read initial value, attach no listener | Attach listeners |
| `useDebounced` | Returns `null`, creates no timer | Debounces normally |
| Browser lifecycle hooks | Return `unknown` | Synchronize after the first frame |

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

## Status and releases

Before the first pub.dev release, confirm that the package name remains
available and configure the verified publisher. The first publication is
manual; subsequent tag releases use pub.dev's GitHub OIDC flow.

## Credits and license

`jaspr_hooks` is inspired by and partially adapted from
[`flutter_hooks`](https://github.com/rrousselGit/flutter_hooks), copyright
Remi Rousselet, under the MIT License. The exact source baseline and full
license are recorded in `THIRD_PARTY_NOTICES.md`.

This is an independent project. It is not maintained, sponsored, or endorsed
by the Jaspr or `flutter_hooks` projects. The fishing-dog artwork is an original
project mascot and is not derived from Jaspr's mascot.

The package itself is available under the MIT License in `LICENSE`.
