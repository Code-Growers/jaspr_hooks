---
title: useRef
description: Keep a mutable ObjectRef without triggering rebuilds when it changes.
---

## What it does

`useRef<T>(initialValue)` returns a stable `ObjectRef<T>` with a mutable `.value` field.

Changing the ref does not notify Jaspr or rebuild the component. It is appropriate for bookkeeping, latest callback data, and imperative handles. Use reactive state when the rendered UI must change.

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

## Server rendering

The initial ref exists during SSR. Avoid mutating it in ways that make the server and hydration markup diverge.

## Related APIs

Use `useState` when mutation should rebuild. Use `usePrevious` when only the preceding build value is needed.

