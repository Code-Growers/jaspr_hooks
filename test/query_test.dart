import 'dart:async';

import 'package:jaspr_hooks/jaspr_hooks.dart';
import 'package:test/test.dart';

void main() {
  test('keys canonicalize map order, preserve list order and reject mutable models', () {
    expect(
      QueryKey([
        'x',
        {'b': 2, 'a': 1},
      ]),
      QueryKey([
        'x',
        {'a': 1, 'b': 2},
      ]),
    );
    expect(QueryKey(['x', 1, 2]), isNot(QueryKey(['x', 2, 1])));
    expect(
      QueryKey([
        'x',
        {'a': 1},
        3,
      ]).startsWith(
        QueryKey([
          'x',
          {'a': 1},
        ]),
      ),
      isTrue,
    );
    expect(() => QueryKey([Object()]), throwsArgumentError);
  });
  test('concurrent requests deduplicate and fresh cached data avoids I/O', () async {
    final client = QueryClient();
    addTearDown(client.dispose);
    final response = Completer<int>();
    var calls = 0;
    final options = QueryOptions(
      key: QueryKey(['item']),
      queryFn: (_) {
        calls++;
        return response.future;
      },
    );
    final a = client.fetchQuery(options);
    final b = client.fetchQuery(options);
    expect(calls, 1);
    response.complete(42);
    expect(await a, 42);
    expect(await b, 42);
    expect(await client.fetchQuery(options), 42);
    expect(calls, 1);
  });
  test('failed background fetch retains previous data and exposes error', () async {
    final client = QueryClient();
    addTearDown(client.dispose);
    var fails = false;
    final options = QueryOptions(
      key: QueryKey(['item']),
      queryFn: (_) async {
        if (fails) throw StateError('offline');
        return 3;
      },
    );
    await client.fetchQuery(options);
    fails = true;
    await expectLater(client.fetchQuery(options, force: true), throwsStateError);
    final state = client.getQueryState<int>(options.key)!;
    expect(state.data, 3);
    expect(state.isError, isTrue);
    expect(state.isFetching, isFalse);
  });
  test('cancellation settles callers and late response cannot overwrite cache', () async {
    final client = QueryClient();
    addTearDown(client.dispose);
    final response = Completer<int>();
    var cancelled = false;
    final options = QueryOptions(
      key: QueryKey(['item']),
      queryFn: (ctx) {
        ctx.signal.onCancel(() => cancelled = true);
        return response.future;
      },
    );
    final request = client.fetchQuery(options);
    final check = expectLater(request, throwsA(isA<QueryCancelled>()));
    client.setQueryData(options, 9);
    await check;
    response.complete(1);
    await Future<void>.delayed(Duration.zero);
    expect(cancelled, isTrue);
    expect(client.getQueryData<int>(options.key), 9);
  });
  test('invalidation refetches enabled matching observers only', () async {
    final client = QueryClient();
    addTearDown(client.dispose);
    var calls = 0;
    final options = QueryOptions(key: QueryKey(['items', 1]), queryFn: (_) async => ++calls);
    final entry = client.observe(options);
    await entry.fetch(options);
    final stop = entry.subscribe(() {});
    addTearDown(stop);
    await client.invalidateQueries(QueryKey(['other']));
    expect(calls, 1);
    await client.invalidateQueries(QueryKey(['items']));
    expect(calls, 2);
    expect(entry.snapshot.data, 2);
  });
  test('disabled observer does not fetch on mount, focus or invalidation', () async {
    final client = QueryClient();
    addTearDown(client.dispose);
    var calls = 0;
    final options = QueryOptions(key: QueryKey(['item']), enabled: false, queryFn: (_) async => ++calls);
    final stop = client.observe(options).subscribe(() {});
    addTearDown(stop);
    client.onWindowFocus();
    client.onReconnect();
    await client.invalidateQueries(QueryKey(['item']));
    expect(calls, 0);
    expect(await client.fetchQuery(options), 1);
  });
  test('retry requires read allowlist and classifier; mutations run once', () async {
    expect(() => QueryOptions(key: QueryKey(['x']), queryFn: (_) async => 1, retry: 1), throwsArgumentError);
    final client = QueryClient();
    addTearDown(client.dispose);
    var calls = 0;
    final options = QueryOptions(
      key: QueryKey(['x']),
      readOnly: true,
      retry: 2,
      retryWhen: (e) => e is TimeoutException,
      retryDelay: (_) => Duration.zero,
      queryFn: (_) async {
        if (++calls < 3) throw TimeoutException('transient');
        return 1;
      },
    );
    expect(await client.fetchQuery(options), 1);
    expect(calls, 3);
    var writes = 0;
    final mutation = MutationController<int, int>(
      MutationOptions(
        mutationFn: (_, _) async {
          writes++;
          throw TimeoutException('unknown commit');
        },
      ),
    );
    await expectLater(mutation.mutateAsync(1), throwsA(isA<TimeoutException>()));
    expect(writes, 1);
    expect(mutation.snapshot.isError, isTrue);
  });
  test('deadline cancels transport and rejects result', () async {
    final client = QueryClient();
    addTearDown(client.dispose);
    var cancelled = false;
    final options = QueryOptions<int>(
      key: QueryKey(['slow']),
      timeout: const Duration(milliseconds: 5),
      queryFn: (ctx) {
        ctx.signal.onCancel(() => cancelled = true);
        return Completer<int>().future;
      },
    );
    await expectLater(client.fetchQuery(options), throwsA(isA<TimeoutException>()));
    expect(cancelled, isTrue);
  });
  test('hydration preserves timestamp, decodes types and keeps newer local data', () async {
    var now = DateTime.utc(2026);
    final server = QueryClient(server: true, now: () => now);
    addTearDown(server.dispose);
    final browser = QueryClient(now: () => now);
    addTearDown(browser.dispose);
    var calls = 0;
    final options = QueryOptions(
      key: QueryKey(['x']),
      queryFn: (_) async => ++calls,
      codec: QueryCodec<int>(encode: (v) => '$v', decode: (v) => int.parse(v as String)),
    );
    await server.prefetchQuery(options);
    browser.hydrate(server.dehydrate());
    expect(await browser.fetchQuery(options), 1);
    expect(calls, 1);
    now = now.add(const Duration(seconds: 31));
    expect(await browser.fetchQuery(options), 2);
    browser.hydrate(server.dehydrate());
    expect(browser.getQueryData<int>(options.key), 2);
  });
  test('last unsubscribe cancels; inactive entries are collected', () async {
    final client = QueryClient();
    addTearDown(client.dispose);
    final options = QueryOptions(key: QueryKey(['x']), gcTime: Duration.zero, queryFn: (_) async => 1);
    final entry = client.observe(options);
    await entry.fetch(options);
    final a = entry.subscribe(() {});
    final b = entry.subscribe(() {});
    a();
    expect(entry.isActive, isTrue);
    b();
    await Future<void>.delayed(Duration.zero);
    expect(client.getQueryState<int>(options.key), isNull);
  });
  test('mutation context, callbacks, invalidation and latest invocation ordering', () async {
    final first = Completer<int>();
    final second = Completer<int>();
    final events = <Object?>[];
    final mutation = MutationController<int, int>(
      MutationOptions(
        onMutate: (v) => v * 10,
        mutationFn: (v, ctx) {
          expect(ctx.timeout, const Duration(seconds: 30));
          return v == 1 ? first.future : second.future;
        },
        onSuccess: (data, v, ctx) => events.add(ctx),
        onSettled: (d, e, v, ctx) => events.add(v),
      ),
    );
    final a = mutation.mutateAsync(1);
    final b = mutation.mutateAsync(2);
    second.complete(2);
    await b;
    first.complete(1);
    await a;
    expect(mutation.snapshot.data, 2);
    expect(events, [20, 2, 10, 1]);
    mutation.reset();
    expect(mutation.snapshot.isIdle, isTrue);
  });
}
