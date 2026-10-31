import 'dart:async';

import 'package:jaspr/server.dart';
import 'package:jaspr_hooks/jaspr_hooks.dart';
import 'package:jaspr_test/server_test.dart';

void main() {
  testServer('awaits server data before building a synchronous hook host', (tester) async {
    tester.pumpComponent(
      AsyncBuilder(
        builder: (_) async {
          final data = await Future<int>.value(42);
          return HookBuilder(
            builder: (_) {
              final value = useMemoized(() => 'loaded:$data');
              useEffect(() => throw StateError('server effect must stay inactive'));
              return Component.text(value);
            },
          );
        },
      ),
    );
    final response = await tester.request('/');
    expect(response.statusCode, 200);
    expect(response.body, contains('loaded:42'));
  });

  testServer('preloads StatefulHookComponent before its synchronous build', (tester) async {
    tester.pumpComponent(const _PreloadedHookComponent());
    final response = await tester.request('/');
    expect(response.statusCode, 200);
    expect(response.body, contains('preloaded:7'));
  });

  testServer('overlapping async requests get independent synchronous hook state', (tester) async {
    final pending = <String, Completer<int>>{};
    tester.pumpComponent(
      AsyncBuilder(
        builder: (context) async {
          final path = context.binding.currentUrl;
          final data = await (pending[path] = Completer<int>()).future;
          return HookBuilder(
            builder: (_) {
              final state = useState(data);
              final reference = useRef(path);
              return Component.text('${reference.value}:${state.value}');
            },
          );
        },
      ),
    );
    final first = tester.request('/first');
    final second = tester.request('/second');
    await pumpEventQueue();
    pending['/second']!.complete(2);
    final secondResponse = await second;
    pending['/first']!.complete(1);
    final firstResponse = await first;
    expect(firstResponse.statusCode, 200);
    expect(secondResponse.statusCode, 200);
    expect(firstResponse.body, contains('/first:1'));
    expect(firstResponse.body, isNot(contains('/second:2')));
    expect(secondResponse.body, contains('/second:2'));
  });

  testServer('direct hooks remain unsupported before and after await in async builds', (tester) async {
    final failures = <Object>[];
    tester.pumpComponent(
      AsyncBuilder(
        builder: (_) async {
          try {
            useState(0);
          } catch (error) {
            failures.add(error);
          }
          await Future<void>.value();
          try {
            useRef(0);
          } catch (error) {
            failures.add(error);
          }
          return const Component.empty();
        },
      ),
    );
    final response = await tester.request('/');
    expect(response.statusCode, 200);
    expect(failures, hasLength(2));
    expect(failures, everyElement(isA<StateError>()));
  });

  testServer('useDisposable cleans up on explicit unmount, not response completion', (tester) async {
    var disposed = 0;
    late ServerAppBinding binding;
    tester.pumpComponent(
      HookBuilder(
        builder: (context) {
          binding = context.binding as ServerAppBinding;
          useDisposable(Object.new, (_) => disposed++);
          return const Component.empty();
        },
      ),
    );
    final response = await tester.request('/');
    expect(response.statusCode, 200);
    expect(disposed, 0);
    binding.detachRootComponent();
    expect(disposed, 1);
  });
}

class _PreloadedHookComponent extends StatefulHookComponent {
  const _PreloadedHookComponent();

  @override
  State<_PreloadedHookComponent> createState() => _PreloadedHookState();
}

class _PreloadedHookState extends State<_PreloadedHookComponent> with PreloadStateMixin {
  late int _data;

  @override
  Future<void> preloadState() async {
    _data = await Future<int>.value(7);
  }

  @override
  Component build(BuildContext context) {
    final value = useState(_data);
    return Component.text('preloaded:${value.value}');
  }
}
