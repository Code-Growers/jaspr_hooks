---
title: Testing hooks
description: Test hook behavior with jaspr_test before adding browser-level smoke coverage.
---

`jaspr_test` is the primary test layer. Mount a `HookBuilder`, interact with returned state, pump the component tree, and assert rendered output and cleanup.

```dart
testComponents('useState rebuilds', (tester) async {
  ValueNotifier<int>? count;

  tester.pumpComponent(
    HookBuilder(
      builder: (context) {
        count = useState(0);
        return Component.text('Count: ${count!.value}');
      },
    ),
  );

  count!.value++;
  await tester.pump();

  expect(find.text('Count: 1'), findsOneComponent);
});
```

Test server contracts with `isClient: false` or `testServer`, especially for effects and async sources. Use a small Playwright suite for hydration, real DOM events, document visibility, media-query behavior, and the deployed GitHub Pages base path.

Every live example on this site exposes `data-hook-demo`, `data-testid="hook-action"` where it has an action, and `data-testid="hook-output"` for stable browser assertions.
