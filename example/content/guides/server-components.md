---
title: Server components
description: Combine hook-based client wrappers with async server content and nested client islands.
---

Jaspr 0.24 lets a `@client` component receive server-rendered components through constructor properties. Use hooks for the interactive wrapper and keep file access, database queries, and server-only dependencies in the component supplied by the server.

## Interactive example

Both cards below receive content loaded asynchronously from a server file. Each contains an independent client counter. Expanding a card changes its visibility while keeping its server content and nested counter mounted.

<ServerCompositionDemo/>

The remove button unmounts the cards. Reload the page to create them again; a removed server component cannot generally be reconstructed by client code.

## A hook-based client wrapper

Put an ID scope inside the client boundary, above the hook host that calls `useId`. Pass a document-unique seed through a serialized constructor property. The server and browser can then derive matching IDs without sharing their outer element trees.

```dart
@client
class ExpandableCard extends StatelessComponent {
  const ExpandableCard({
    required this.idScope,
    required this.content,
    super.key,
  });

  final String idScope;
  final Component content;

  @override
  Component build(BuildContext context) => HookIdScope(
    seed: idScope,
    child: HookBuilder(builder: (_) {
      final expanded = useState(false);
      final panelId = useId();
      return div([
        button(
          attributes: {'aria-controls': panelId},
          onClick: () => expanded.value = !expanded.value,
          [Component.text(expanded.value ? 'Collapse' : 'Expand')],
        ),
        div(
          id: panelId,
          styles: Styles(
            display: expanded.value ? Display.block : Display.none,
          ),
          [content],
        ),
      ]);
    }),
  );
}
```

Always include `content` during the initial server build. A condition such as `if (expanded.value) content` omits the server output when the initial value is false. The browser has no server build code to create it later. Lists and maps of component constructor properties follow the same rule. Nested `@client` components within server content hydrate independently and need their own ID scopes when they use `useId`.

## Await data before building hooks

`AsyncStatelessComponent` and `AsyncBuilder` are server-only APIs from `package:jaspr/server.dart`. Their build methods can await data, then return a synchronous hook host:

```dart
class UserDetails extends AsyncStatelessComponent {
  @override
  Future<Component> build(BuildContext context) async {
    final user = await loadUserFromDatabase();
    return HookBuilder(builder: (_) {
      final label = useMemoized(() => formatUser(user), [user]);
      return Component.text(label);
    });
  }
}
```

The hook calls belong to the returned builder. Ordinary Jaspr async builds do not support direct hook calls. For hooks across sequential awaits, explicitly use the experimental `AsyncHookComponent` or `AsyncHookBuilder` from `package:jaspr_hooks/server.dart`; see [Async server hooks](guides/async-server-hooks). The interactive demo above uses both async hook hosts.

For a stateful alternative, extend `StatefulHookComponent`, preload data with `PreloadStateMixin`, and call hooks in the synchronous `State.build`. `preloadState` runs only on the server; a hydrated component still needs serialized constructor properties or synchronized state to reproduce its initial data in the browser. Hooks cannot be called from `preloadState` or `initState`.

## Server state and resource lifetime

Each server render owns separate hook state. It is not a request cache, a browser state transfer mechanism, or a live subscription. Deterministic state, memoization, references, and inherited reads work during synchronous server builds. Effects and browser subscriptions stay inactive. The existing `useFuture` and stream hooks still require null sources on the server.

Hook resource cleanup follows replacement and element unmounting. Jaspr's server renderer does not guarantee unmount at response completion. Manage request resources in the caller, including asynchronous cleanup:

```dart
Future<User> loadUserFromDatabase() async {
  final connection = await openConnection();
  try {
    return await connection.loadUser();
  } finally {
    await connection.close();
  }
}
```

Do not put a request connection in `useDisposable` and assume it closes when the response finishes. See [SSR and hydration](guides/ssr-and-hydration), [useId](hooks/use-id), and Jaspr's [Server Components documentation](https://docs.jaspr.site/going_further/server_components).
