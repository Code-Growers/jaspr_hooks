import 'package:jaspr/jaspr.dart';
import 'package:jaspr_hooks/jaspr_hooks.dart';
import 'package:jaspr_test/server_test.dart';

import 'support/harness.dart';

void main() {
  testComponents('query hook subscribes, shares cache, follows keys and cleans up', (tester) async {
    final client = QueryClient();
    addTearDown(client.dispose);
    final harness = TestHarnessController();
    var id = 1;
    var calls = 0;
    QueryResult<int>? result;
    Component child() => QueryClientProvider(
      client: client,
      child: HookBuilder(
        builder: (_) {
          result = useQuery(
            QueryOptions(
              key: QueryKey(['x', id]),
              queryFn: (_) async {
                calls++;
                return id;
              },
            ),
          );
          return Component.text('${result!.data}');
        },
      ),
    );
    tester.pumpComponent(TestHarness(controller: harness, builder: child));
    await tester.pump();
    await tester.pump();
    expect(result!.data, 1);
    expect(calls, 1);
    harness.rebuild();
    await tester.pump();
    expect(calls, 1);
    id = 2;
    harness.rebuild();
    await tester.pump();
    await tester.pump();
    expect(result!.data, 2);
    expect(calls, 2);
    await client.invalidateQueries(QueryKey(['x']));
    await tester.pump();
    expect(calls, 3);
    harness.unmountChild();
    await tester.pump();
    await client.invalidateQueries(QueryKey(['x']));
    expect(calls, 3);
  });
  testComponents('SSR reads hydrated cache without fetching or subscriptions', (tester) async {
    final client = QueryClient(server: true);
    addTearDown(client.dispose);
    var calls = 0;
    final options = QueryOptions(
      key: QueryKey(['x']),
      queryFn: (_) async {
        calls++;
        return 1;
      },
    );
    client.setQueryData(options, 7);
    tester.pumpComponent(
      QueryClientProvider(
        client: client,
        child: HookBuilder(
          builder: (_) {
            final result = useQuery(options);
            expect(useQueryClient(), same(client));
            useQueryLifecycle(client);
            final mutation = useMutation<int, int>(MutationOptions(mutationFn: (v, _) async => v));
            expect(mutation.snapshot.isIdle, isTrue);
            return Component.text('${result.data}');
          },
        ),
      ),
    );
    await tester.pump();
    expect(calls, 0);
    expect(find.text('7'), findsOneComponent);
  }, isClient: false);
  testComponents('mutation hook rebuilds after completion', (tester) async {
    MutationController<int, int>? mutation;
    tester.pumpComponent(
      HookBuilder(
        builder: (_) {
          mutation = useMutation(MutationOptions<int, int>(mutationFn: (v, _) async => v + 1));
          return Component.text('${mutation!.snapshot.data}');
        },
      ),
    );
    await tester.pump();
    await mutation!.mutateAsync(4);
    await tester.pump();
    expect(find.text('5'), findsOneComponent);
  });
}
