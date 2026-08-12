library;

enum HookCategory {
  framework('Framework'),
  primitives('Primitives'),
  state('Lifecycle & state'),
  async('Async'),
  listenables('Listenables'),
  browser('Browser lifecycle');

  const HookCategory(this.label);

  final String label;
}

final class HookDoc {
  const HookDoc({
    required this.name,
    required this.slug,
    required this.category,
    required this.summary,
  });

  final String name;

  final String slug;

  final HookCategory category;

  final String summary;

  String get href => 'hooks/$slug';

  String get testFile => switch (category) {
    HookCategory.framework => 'test/framework_test.dart',
    HookCategory.primitives || HookCategory.state => 'test/primitives_test.dart',
    HookCategory.async => 'test/async_test.dart',
    HookCategory.listenables => 'test/listenable_test.dart',
    HookCategory.browser => 'test/browser_lifecycle_test.dart',
  };
}

const List<HookDoc> hookCatalog = <HookDoc>[
  HookDoc(
    name: 'use',
    slug: 'custom-hook',
    category: HookCategory.framework,
    summary: 'Registers a custom Hook object in the current hook component.',
  ),
  HookDoc(
    name: 'useContext',
    slug: 'use-context',
    category: HookCategory.framework,
    summary: 'Returns the BuildContext of the currently building hook component.',
  ),
  HookDoc(
    name: 'useState',
    slug: 'use-state',
    category: HookCategory.primitives,
    summary: 'Creates an owned ValueNotifier that rebuilds the component when changed.',
  ),
  HookDoc(
    name: 'useEffect',
    slug: 'use-effect',
    category: HookCategory.primitives,
    summary: 'Runs a synchronous client-side effect with optional cleanup.',
  ),
  HookDoc(
    name: 'usePostFrameEffect',
    slug: 'use-post-frame-effect',
    category: HookCategory.primitives,
    summary: 'Runs a client-side effect after the next completed frame.',
  ),
  HookDoc(
    name: 'useMemoized',
    slug: 'use-memoized',
    category: HookCategory.primitives,
    summary: 'Caches a computed value until its ordered keys change.',
  ),
  HookDoc(
    name: 'useCallback',
    slug: 'use-callback',
    category: HookCategory.primitives,
    summary: 'Keeps a callback instance stable until its ordered keys change.',
  ),
  HookDoc(
    name: 'useRef',
    slug: 'use-ref',
    category: HookCategory.primitives,
    summary: 'Preserves a mutable cell without scheduling rebuilds.',
  ),
  HookDoc(
    name: 'useValueChanged',
    slug: 'use-value-changed',
    category: HookCategory.primitives,
    summary: 'Runs a transformation when a value changes and retains its result.',
  ),
  HookDoc(
    name: 'useReducer',
    slug: 'use-reducer',
    category: HookCategory.state,
    summary: 'Creates a reducer-backed store with synchronous action dispatch.',
  ),
  HookDoc(
    name: 'usePrevious',
    slug: 'use-previous',
    category: HookCategory.state,
    summary: 'Returns the value supplied during the preceding build.',
  ),
  HookDoc(
    name: 'useIsMounted',
    slug: 'use-is-mounted',
    category: HookCategory.state,
    summary: 'Returns a stable callback that reports whether its hook remains mounted.',
  ),
  HookDoc(
    name: 'useDebounced',
    slug: 'use-debounced',
    category: HookCategory.state,
    summary: 'Publishes a value after it remains unchanged for a duration.',
  ),
  HookDoc(
    name: 'useFuture',
    slug: 'use-future',
    category: HookCategory.async,
    summary: 'Subscribes to a client Future and exposes its AsyncSnapshot.',
  ),
  HookDoc(
    name: 'useStream',
    slug: 'use-stream',
    category: HookCategory.async,
    summary: 'Subscribes to a client Stream and exposes its AsyncSnapshot.',
  ),
  HookDoc(
    name: 'useStreamController',
    slug: 'use-stream-controller',
    category: HookCategory.async,
    summary: 'Creates and automatically closes a broadcast StreamController.',
  ),
  HookDoc(
    name: 'useOnStreamChange',
    slug: 'use-on-stream-change',
    category: HookCategory.async,
    summary: 'Runs current callbacks for events from a client Stream.',
  ),
  HookDoc(
    name: 'useListenable',
    slug: 'use-listenable',
    category: HookCategory.listenables,
    summary: 'Rebuilds when a Jaspr Listenable notifies.',
  ),
  HookDoc(
    name: 'useListenableSelector',
    slug: 'use-listenable-selector',
    category: HookCategory.listenables,
    summary: 'Rebuilds only when a selected Listenable value changes.',
  ),
  HookDoc(
    name: 'useValueNotifier',
    slug: 'use-value-notifier',
    category: HookCategory.listenables,
    summary: 'Creates and disposes an owned ValueNotifier without subscribing to it.',
  ),
  HookDoc(
    name: 'useValueListenable',
    slug: 'use-value-listenable',
    category: HookCategory.listenables,
    summary: 'Subscribes to a ValueListenable and returns its current value.',
  ),
  HookDoc(
    name: 'useOnListenableChange',
    slug: 'use-on-listenable-change',
    category: HookCategory.listenables,
    summary: 'Runs the latest callback whenever a Listenable notifies.',
  ),
  HookDoc(
    name: 'useDocumentVisibility',
    slug: 'use-document-visibility',
    category: HookCategory.browser,
    summary: 'Tracks whether the browser document is visible or hidden.',
  ),
  HookDoc(
    name: 'useOnDocumentVisibilityChange',
    slug: 'use-on-document-visibility-change',
    category: HookCategory.browser,
    summary: 'Runs a callback after the document visibility changes.',
  ),
  HookDoc(
    name: 'usePreferredColorScheme',
    slug: 'use-preferred-color-scheme',
    category: HookCategory.browser,
    summary: 'Tracks the browser preference for a light or dark color scheme.',
  ),
  HookDoc(
    name: 'useOnPreferredColorSchemeChange',
    slug: 'use-on-preferred-color-scheme-change',
    category: HookCategory.browser,
    summary: 'Runs a callback when the preferred color scheme changes.',
  ),
];

const List<({String title, String href})> guideCatalog = <({String title, String href})>[
  (title: 'Getting started', href: 'guides/getting-started'),
  (title: 'AI agents', href: 'guides/ai-agents'),
  (title: 'Rules of hooks', href: 'guides/rules-of-hooks'),
  (title: 'SSR & hydration', href: 'guides/ssr-and-hydration'),
  (title: 'Writing custom hooks', href: 'guides/custom-hooks'),
  (title: 'Migrating from flutter_hooks', href: 'guides/migration'),
  (title: 'Attribution & licensing', href: 'guides/attribution'),
  (title: 'Troubleshooting', href: 'guides/troubleshooting'),
  (title: 'Testing hooks', href: 'guides/testing'),
];
