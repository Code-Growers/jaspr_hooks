---
title: Async server hooks
description: Use experimental server-only hook hosts across sequential awaits with explicit lifecycle rules.
---

`AsyncHookComponent` and `AsyncHookBuilder` let server builds call hooks before and after `await`. They are experimental APIs from `package:jaspr_hooks/server.dart`. Keep this import in server scope; client components use the universal or web entry point.

## Build a server subtree

```dart
import 'package:jaspr/server.dart';
import 'package:jaspr_hooks/server.dart';

class UserDetails extends AsyncHookComponent {
  const UserDetails({required this.userId, super.key});
  final String userId;

  @override
  Future<Component> build(BuildContext context) async {
    final requestedId = useRef(userId);
    final user = await loadUser(requestedId.value);
    final label = useMemoized(() => formatUser(user), [user]);
    return Component.text(label);
  }
}
```

Use `AsyncHookBuilder(builder: (context) async { ... })` for a small async hook region. Both hosts integrate with Jaspr's server build owner, so the page waits for their returned futures. Their results can include synchronous hook hosts, nested async hook hosts, and `@client` wrappers receiving server-rendered content. The [server components demo](guides/server-components) uses both APIs with a server file and nested client counters.

Ordinary `AsyncStatelessComponent` and `AsyncBuilder` do not establish a hook session. Continue returning a synchronous hook host from them, or explicitly switch to an async hook host. Do not annotate an async hook component with `@client`.

## Keep one sequential hook call chain

Call hooks in a stable order, directly in the async build or in helpers that the build awaits sequentially. `useContext` continues to return the owning element after each await. Concurrent requests and sibling components have independent sessions and hook state.

Parallel I/O is fine when its branches do not call hooks:

```dart
final (user, settings) = await (loadUser(), loadSettings()).wait;
final label = useMemoized(() => format(user, settings), [user, settings]);
```

Do not call hooks from parallel branches, unawaited helpers, timers, stream listeners, event handlers, or detached `.then` callbacks. The runtime cannot infer every fork in arbitrary async code; ordered calls in one awaited chain remain a rule the caller must follow. A callback registered in a build does not gain permanent hook access: its captured session closes when that build completes or fails, and late hook calls throw `StateError` even if the element is still mounted.

## Server hook behavior

| Category | Async server host |
| --- | --- |
| Refs and memoization | Local values available across sequential awaits |
| Context and inherited reads | Read from the owning server element |
| `useState`, `useGuardedState` | Read-only initial snapshots; assigning while mounted throws |
| Reducers and local controllers | Initial values work; reactive mutations throw |
| Effects, timers, browser subscriptions | Stay inactive under the existing SSR contract |
| `useFuture`, `useStream`, `useOnStreamChange` | Sources must still be null; await server data directly |
| `useId` | Use a surrounding `HookIdScope`; client islands need their own serialized scopes |

Use local variables or refs for non-reactive server computations. This API does not add live server reactivity, browser state transfer, cross-request caching, or client-side async builds. A synchronous `HookBuilder` returned by an async host owns separate hook state and follows its normal synchronous rules.

## Completion, failure, and unmount

A successful build closes hook-call access but retains its owned hook state until replacement or unmount. A failed build closes its session, disposes all of its hooks in reverse order, and reports the failure to Jaspr so server rendering can finish with an error response. Cleanup failures are reported without skipping the remaining disposers.

Unmount during suspension closes the session, disposes existing hooks, and invalidates the pending result. The underlying Dart future cannot be physically cancelled; its later result or error is observed and ignored. Code that resumes and tries to call another hook receives `StateError`. Keep resource operations cancellable at their source when needed.

Rebuild requests for the same element are serialized. If its configuration changes during a pending build, that result is discarded and the latest configuration builds with a fresh session before its subtree renders. Normal hook order and key preservation rules still apply.

HTTP response completion does not guarantee element unmount. Manage request connections and asynchronous cleanup explicitly in the caller with `try`/`finally`; `useDisposable` retains its element-lifetime ownership rule. See [SSR and hydration](guides/ssr-and-hydration) and [rules of hooks](guides/rules-of-hooks).
