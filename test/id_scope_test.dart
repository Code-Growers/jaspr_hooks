import 'package:jaspr/jaspr.dart';
import 'package:jaspr_hooks/jaspr_hooks.dart';
import 'package:jaspr_test/jaspr_test.dart';

import 'support/capturing_binding.dart';
import 'support/harness.dart';

void main() {
  test('HookIdScope ignores different ancestors outside the boundary', () async {
    final server = CapturingTestComponentsBinding(isClient: false);
    final client = CapturingTestComponentsBinding(isClient: true);
    addTearDown(server.detachRootComponent);
    addTearDown(client.detachRootComponent);
    final serverIds = <String>[];
    final clientIds = <String>[];

    Component scoped(List<String> ids) => HookIdScope(
      seed: 'account/settings: žluťoučký',
      child: HookBuilder(
        builder: (_) {
          ids.addAll([useId(), useId(prefix: 'field')]);
          return const Component.empty();
        },
      ),
    );

    server.attachRootComponent(
      Component.element(
        tag: 'main',
        children: [
          const Component.empty(),
          Builder(builder: (_) => scoped(serverIds)),
        ],
      ),
    );
    client.attachRootComponent(scoped(clientIds));
    await server.pump();
    expect(serverIds, clientIds);
    expect(serverIds.toSet(), hasLength(2));
    expect(serverIds, everyElement(isNot(contains(' '))));
  });

  testComponents('HookIdScope has independent nested namespaces and follows seed changes', (tester) async {
    final harness = TestHarnessController();
    var seed = 'first';
    final ids = <String, String>{};
    final child = HookBuilder(
      builder: (_) {
        ids['outer'] = useId();
        return HookIdScope(
          seed: 'nested',
          child: HookBuilder(
            builder: (_) {
              ids['nested'] = useId();
              return const Component.empty();
            },
          ),
        );
      },
    );
    tester.pumpComponent(
      TestHarness(
        controller: harness,
        builder: () => HookIdScope(seed: seed, child: child),
      ),
    );
    final initial = Map<String, String>.of(ids);
    expect(initial.values.toSet(), hasLength(2));

    harness.rebuild();
    await tester.pump();
    expect(ids, initial);
    seed = 'second';
    harness.rebuild();
    await tester.pump();
    expect(ids['outer'], isNot(initial['outer']));
    expect(ids['nested'], initial['nested']);
  });

  testComponents('HookIdScope keeps keyed IDs and avoids reusing their old positions', (tester) async {
    final harness = TestHarnessController();
    var items = ['a', 'b'];
    final ids = <String, String>{};
    tester.pumpComponent(
      TestHarness(
        controller: harness,
        builder: () => HookIdScope(
          seed: 'list',
          child: Component.fragment([
            for (final item in items)
              HookBuilder(
                key: ValueKey(item),
                builder: (_) {
                  ids[item] = useId();
                  return const Component.empty();
                },
              ),
          ]),
        ),
      ),
    );
    final initial = Map<String, String>.of(ids);
    items = ['c', 'a', 'b'];
    harness.rebuild();
    await tester.pump();
    expect(ids['a'], initial['a']);
    expect(ids['b'], initial['b']);
    expect(ids.values.toSet(), hasLength(3));
  });

  test('HookIdScope rejects an empty seed at useId', () {
    final binding = CapturingTestComponentsBinding(isClient: true);
    addTearDown(binding.detachRootComponent);
    binding.attachRootComponent(
      HookIdScope(
        seed: '',
        child: HookBuilder(
          builder: (_) {
            useId();
            return const Component.empty();
          },
        ),
      ),
    );
    expect(binding.errors.single.error, isA<ArgumentError>());
  });
}
