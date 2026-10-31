# 0.3.0-beta.0

- Require Dart 3.13 and Jaspr 0.24.0-beta.0 or later in the 0.24 release line.
  Jaspr 0.23 applications can continue using jaspr_hooks 0.2.0.
- Added `HookIdScope` for stable HTML IDs across server rendering and client
  island hydration. Pass a unique, serialized seed into each client boundary.
- Preserve hook state, references, and node keys during hot reload while
  refreshing memoized values, callbacks, effects, and disposable resources.
  Custom hooks can respond through `HookState.reassemble()`.
- Added generated-client coverage and an interactive example for hook-based
  client wrappers containing async server components and nested client islands.
- Documented synchronous server hook composition, async preloading, hydration
  boundaries, and the distinction between unmount cleanup and request lifetime.
- Updated the test harness to use public scheduler APIs and aligned the
  example, CLI, builder, lint, and test dependencies with the Jaspr beta.
- Constrained `http` to 0.13.2 or later because Jaspr's beta server imports
  `retry.dart`, which is absent from older versions allowed by its dependency.

# 0.2.0

- Added `useGuardedState`, whose `GuardedValueNotifier` drops assignments made
  after the owning component unmounts instead of failing Jaspr's
  disposed-notifier assertion.
- Added `usePostFrameUpdateEffect`, a post-frame effect that skips the mount
  frame.
- Added `useLocation`, `useBrowserRoute`, and `useOnWindowFocus` to the browser
  lifecycle hooks. `HistoryController.push` and `replace` now announce
  same-document navigation to `useLocation`.
- Hook state assigned while a hook component is building, such as inside
  `useEffect`, now rebuilds after the frame instead of being dropped by Jaspr's
  dirty flag or rejected as a build-time `setState`.
- `useExternalStore` no longer requires `getServerSnapshot` on the server; it
  falls back to `getSnapshot` without subscribing.

# 0.1.2

- Fixed signed-zero change detection in `useOptimistic` and `useExternalStore`
  while continuing to treat `NaN` snapshots as equal.
- Updated the Jaspr test, builder, example, and documentation toolchain to
  0.23.4 and raised the compatible web compiler baseline to 4.8.0.
- Changed pub.dev releases from tag-triggered GitHub publishing to a fully
  manual release process.

# 0.1.1

- Fixed the project mascot image on pub.dev by using an absolute Markdown URL.

# 0.1.0

- Added deterministic `useId` and stable latest-handler `useEvent` hooks.
- Added focus, active-element, abort-controller, animation-frame, history, and
  clipboard hooks to the browser entry point.
- Expanded the interactive catalog, SSR coverage, lifecycle tests, and
  production-browser validation to all 66 exported hooks.

# 0.1.0-dev.3

- Added foundation hooks for latest values, owned resources, external stores,
  inherited components, imperative handles, timeouts, and intervals.
- Added async actions with configurable concurrency and explicit optimistic
  state transactions.
- Added toggle, counter, collection, queue, mount, unmount, and update-effect
  convenience hooks.
- Added hydration-safe media query and preferred-motion hooks.
- Added the optional `package:jaspr_hooks/web.dart` entry point with node keys,
  element and viewport sizing, intersection and mutation observers, event
  listeners, click-outside detection, and hover state.
- Expanded the interactive catalog, AI-agent reference, semantic tests, and
  production-browser coverage to all 57 exported hooks.
- Removed the legacy pub.dev screenshot assets and excluded future local
  screenshots from source and package archives.
- Updated the Playwright, TypeScript, Node.js type, and GitHub Actions Node.js
  toolchains.

# 0.1.0-dev.2

- Improved documentation layout spacing at the end of every page.
- Added a repository agent skill for consistent version bumps and release
  validation.
- Removed redundant internal comments without changing runtime behavior.

# 0.1.0-dev.1

- Initial preview of the native Jaspr hook runtime.
- Added stateless, stateful, and callback-based hook component hosts.
- Added state, effect, memoization, async, stream, listenable, reducer,
  debounce, and browser-lifecycle hooks.
- Added SSR-safe effect and subscription behavior, including
  `usePostFrameEffect`.
- Added the interactive Jaspr Content documentation application and browser
  test suite.
- Added an AI-agent installation prompt, rendered agent guide, and a stable
  `llms.txt` reference covering every exported hook.
