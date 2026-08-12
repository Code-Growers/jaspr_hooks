# jaspr_hooks example

This directory contains the static Jaspr Content documentation site and its live,
client-island hook demos. The same small counter pattern used throughout the docs
can be embedded in any Jaspr application:

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
      [text('Count: ${count.value}')],
    );
  }
}
```

Run the site from this directory with `jaspr serve`. A production static build
uses the configured `/jaspr_hooks/` base path for GitHub Pages.

