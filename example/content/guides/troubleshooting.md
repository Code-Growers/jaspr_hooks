---
title: Troubleshooting
description: Diagnose hook-order errors, SSR source errors, stale values, and hydration surprises.
---

## “Hooks can only be called while a hook component is building”

The hook ran outside `HookComponent`, `StatefulHookComponent`, or `HookBuilder`, or it ran later from an event callback. Call hooks synchronously during build and capture their returned values for callbacks.

```dart
final count = useState(0);

return button(
  // Correct: useState already ran during build.
  onClick: () => count.value++,
  [Component.text('${count.value}')],
);
```

## “Hook order changed”

A condition, loop, early return, or changed custom-hook implementation altered the sequence of hook types. Move the branch inside a hook callback or extract a child hook component.

## Async source error during server rendering

Pass `null` to `useFuture`, `useStream`, and `useOnStreamChange` on the server. Obtain server HTML data through Jaspr preloading, sync state, serialized client properties, or `jaspr_riverpod`.

## An effect did not run during static generation

That is intentional. `useEffect` and `usePostFrameEffect` are browser-client effects. Put server work in Jaspr's server lifecycle instead of relying on a UI effect.

## A `useRef` update is not visible

Changing `ObjectRef.value` does not rebuild its component. Use `useState` when the UI must update, or trigger a rebuild through another subscribed value.

## A selector does not rebuild

`useListenableSelector` compares its new selection with the previous one using `!=`. Return a value with meaningful equality and notify the source listenable after relevant changes.

## Hydrated output differs from server HTML

Check initializers for timestamps, randomness, browser-only reads, or other non-deterministic values. Render a stable initial value, then synchronize with the browser after hydration through an effect or browser lifecycle hook.

## Still stuck

Reduce the issue to a `HookBuilder` test using `jaspr_test`. Verify hook order, client/server mode, disposal, and exact key values before involving a full application.
