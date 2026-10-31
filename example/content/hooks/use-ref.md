---
title: useRef
description: Keep a mutable ObjectRef without triggering rebuilds when it changes.
---

## What it does

`useRef<T>(initialValue)` returns a stable `ObjectRef<T>` with a mutable `.value` field.

Changing the ref does not notify Jaspr or rebuild the component. It is appropriate for bookkeeping, latest callback data, and imperative handles. Use reactive state when the rendered UI must change.

## Signature and parameters

```dart
ObjectRef<T> useRef<T>(T initialValue)
```

`initialValue` seeds the cell once. The return is a stable, mutable `ObjectRef<T>`.

## Usage

```dart
class RequestTracker extends HookComponent {
  const RequestTracker({super.key});

  @override
  Component build(BuildContext context) {
    final requestCount = useRef(0);
    final visibleCount = useState(0);

    void request() {
      requestCount.value++;
      visibleCount.value = requestCount.value;
    }

    return button(
      onClick: request,
      [text('Requests: ${visibleCount.value}')],
    );
  }
}
```

## Live demo

<HookDemo name="useRef"/>

## Ownership and lifecycle

The hook owns the reference object but does not dispose values assigned to it. A later `initialValue` is ignored while the hook state is preserved, and mutation never requests a rebuild.

The cell and its current value survive development hot reload when hook order matches. Unlike `useMemoized`, it does not recompute on reload.

## Server rendering

The initial ref exists during SSR. Avoid mutating it in ways that make the server and hydration markup diverge.

## Common mistakes

Do not store render state solely in a ref because the UI will not update. Use `useLatest` when the cell should automatically follow a changing input and `useDisposable` when the contained resource needs cleanup.

## Related APIs

Use `useState` when mutation should rebuild. Use `usePrevious` when only the preceding build value is needed.
