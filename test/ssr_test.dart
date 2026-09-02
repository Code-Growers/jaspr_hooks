import 'dart:async';

import 'package:jaspr/jaspr.dart';
import 'package:jaspr_hooks/jaspr_hooks.dart';
import 'package:jaspr_test/server_test.dart';

import 'support/capturing_binding.dart';
import 'support/harness.dart';

void main() {
  group('server-safe effects', () {
    testComponents(
      'effect, post-frame effect, and debounce stay inactive',
      (tester) async {
        final harness = TestHarnessController();
        final events = <String>[];
        String? debounced;

        Component child() => HookBuilder(
          builder: (context) {
            useEffect(() {
              events.add('effect');
              return () => events.add('cleanup:effect');
            });
            usePostFrameEffect(() {
              events.add('post-frame');
              return () => events.add('cleanup:post-frame');
            });
            debounced = useDebounced(
              'server',
              const Duration(milliseconds: 5),
            );
            return const Component.empty();
          },
        );

        tester.pumpComponent(TestHarness(controller: harness, builder: child));
        await Future<void>.delayed(const Duration(milliseconds: 15));
        await tester.pump();
        expect(events, isEmpty);
        expect(debounced, isNull);

        harness.unmountChild();
        await tester.pump();
        expect(events, isEmpty);
      },
      isClient: false,
    );
  });

  group('browser lifecycle SSR contract', () {
    testComponents(
      'location hooks return server fallbacks and window focus attaches nothing',
      (tester) async {
        Uri? location;
        String? route;

        tester.pumpComponent(
          HookBuilder(
            builder: (context) {
              location = useLocation();
              route = useBrowserRoute<String>('server', (_) => 'client');
              useOnWindowFocus(() => fail('window focus must not attach on the server'));
              return const Component.empty();
            },
          ),
        );

        await tester.pump();
        expect(location, isNull);
        expect(route, 'server');
      },
      isClient: false,
    );
  });

  group('async SSR contract', () {
    test('rejects non-null Future, Stream, and stream listener sources', () {
      final futureBinding = _captureServerError(
        HookBuilder(
          builder: (context) {
            useFuture(Future<int>.value(1));
            return const Component.empty();
          },
        ),
      );
      addTearDown(futureBinding.detachRootComponent);

      final streamBinding = _captureServerError(
        HookBuilder(
          builder: (context) {
            useStream(const Stream<int>.empty());
            return const Component.empty();
          },
        ),
      );
      addTearDown(streamBinding.detachRootComponent);

      final listenerBinding = _captureServerError(
        HookBuilder(
          builder: (context) {
            useOnStreamChange(const Stream<int>.empty());
            return const Component.empty();
          },
        ),
      );
      addTearDown(listenerBinding.detachRootComponent);

      for (final binding in <CapturingTestComponentsBinding>[
        futureBinding,
        streamBinding,
        listenerBinding,
      ]) {
        expect(binding.errors, hasLength(1));
        expect(binding.errors.single.error, isA<StateError>());
        expect(
          binding.errors.single.error.toString(),
          allOf(contains('server'), contains('null')),
        );
      }
    });

    testComponents(
      'null sources expose deterministic initial snapshots',
      (tester) async {
        AsyncSnapshot<int>? futureSnapshot;
        AsyncSnapshot<int>? streamSnapshot;
        StreamSubscription<int>? subscription;

        tester.pumpComponent(
          HookBuilder(
            builder: (context) {
              futureSnapshot = useFuture<int>(null, initialData: 1);
              streamSnapshot = useStream<int>(null, initialData: 2);
              subscription = useOnStreamChange<int>(null);
              return const Component.empty();
            },
          ),
        );

        expect(futureSnapshot!.connectionState, ConnectionState.none);
        expect(futureSnapshot!.data, 1);
        expect(streamSnapshot!.connectionState, ConnectionState.none);
        expect(streamSnapshot!.data, 2);
        expect(subscription, isNull);
      },
      isClient: false,
    );
  });

  group('listenable SSR contract', () {
    testComponents(
      'reads deterministic values but never attaches live listeners',
      (tester) async {
        final notifier = _ServerValueNotifier(3);
        int? listened;
        int? selected;
        var callbacks = 0;

        tester.pumpComponent(
          HookBuilder(
            builder: (context) {
              useListenable(notifier);
              listened = useValueListenable(notifier);
              selected = useListenableSelector(
                notifier,
                () => notifier.value.isEven ? 0 : 1,
              );
              useOnListenableChange(notifier, () => callbacks++);
              return const Component.empty();
            },
          ),
        );

        expect(listened, 3);
        expect(selected, 1);
        expect(notifier.addCalls, 0);
        notifier.value = 4;
        expect(callbacks, 0);
      },
      isClient: false,
    );
  });

  group('web lifecycle SSR contract', () {
    testComponents(
      'returns unknown and does not call change handlers',
      (tester) async {
        DocumentVisibility? visibility;
        PreferredColorScheme? colorScheme;
        var visibilityChanges = 0;
        var colorChanges = 0;

        tester.pumpComponent(
          HookBuilder(
            builder: (context) {
              visibility = useDocumentVisibility();
              colorScheme = usePreferredColorScheme();
              useOnDocumentVisibilityChange(
                (previous, current) => visibilityChanges++,
              );
              useOnPreferredColorSchemeChange(
                (previous, current) => colorChanges++,
              );
              return const Component.empty();
            },
          ),
        );

        expect(visibility, DocumentVisibility.unknown);
        expect(colorScheme, PreferredColorScheme.unknown);
        expect(visibilityChanges, 0);
        expect(colorChanges, 0);
      },
      isClient: false,
    );
  });

  testServer('renders representative deterministic hook state', (tester) async {
    final effects = <String>[];
    tester.pumpComponent(
      HookBuilder(
        builder: (context) {
          final state = useState(4);
          final future = useFuture<int>(null, initialData: 5);
          useEffect(() {
            effects.add('effect');
            return null;
          });
          return Component.element(
            tag: 'main',
            attributes: const <String, String>{'data-hook-page': 'true'},
            children: <Component>[
              Component.text('${state.value}:${future.data}'),
            ],
          );
        },
      ),
    );

    final response = await tester.request('/');
    expect(response.statusCode, 200);
    expect(response.body, contains('data-hook-page="true"'));
    expect(response.body, contains('4:5'));
    expect(effects, isEmpty);
  });
}

CapturingTestComponentsBinding _captureServerError(Component component) {
  final binding = CapturingTestComponentsBinding(isClient: false);
  binding.attachRootComponent(component);
  return binding;
}

final class _ServerValueNotifier extends ChangeNotifier implements ValueListenable<int> {
  _ServerValueNotifier(this._value);

  int addCalls = 0;
  int _value;

  @override
  int get value => _value;

  set value(int value) {
    _value = value;
    notifyListeners();
  }

  @override
  void addListener(VoidCallback listener) {
    addCalls++;
    super.addListener(listener);
  }
}
