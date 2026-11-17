---
title: Queries and mutations
description: Cache and synchronize server state with jaspr_hooks.
---

Create a `QueryClient` per authenticated browser session. Provide it with
`QueryClientProvider`; dispose it on logout. Call `useQueryLifecycle(client)`
once in the app shell for browser focus and reconnect revalidation.

```dart
final query = useQuery(QueryOptions<Customer>(
  key: QueryKey(['customers', 'detail', id]),
  queryFn: (context) => repository.get(id, context),
  readOnly: true,
  staleTime: const Duration(seconds: 30),
));
```

Keys accept JSON values. Include every filter, sort and page input. Map order
is canonicalized. Reusing a key shares data and in-flight requests. Different
result types must use different keys. Query results expose `data`, `error`,
`isPending`, `isLoading`, `isFetching`, `isSuccess`, `isError`, and `refetch()`.
Background failures retain cached data. Disabled queries only fetch explicitly.
Repositories should return immutable data; editing drafts belong outside caches.

`staleTime` defaults to 30 seconds and `gcTime` to five minutes. Inactive queries
are collected after `gcTime`. Stale active queries revalidate on mount, browser
focus or reconnect. Configure these individually or set a `refetchInterval`.
The final unsubscribe cancels the query. Late cancelled results cannot overwrite
cache updates. Query callbacks receive a `signal` and `timeout`; register actual
transport cancellation with `signal.onCancel` and enforce the timeout in the RPC.

Retries default to zero. Retrying requires `readOnly: true`, a positive `retry`
count and a `retryWhen` classifier. Never classify authorization, validation or
conflict errors as transient. Backoff is exponential and cancellation interrupts it.
A query timeout cancels the attempt and is retryable only when explicitly allowed.

```dart
final save = useMutation(MutationOptions<Customer, UpdateCustomer>(
  mutationFn: (input, context) => repository.update(input, context.timeout),
  onSuccess: (customer, input, rollback) async {
    client.setQueryData(customerQuery(customer.id), customer);
    await client.invalidateQueries(QueryKey(['customers', 'list']));
  },
));
```

`mutate` records errors for event handlers; `mutateAsync` propagates errors.
Mutations never retry automatically. `onMutate` can return rollback context;
`onError` receives it, and `onSettled` always runs. Callbacks finish even after
unmount, while disposed observers stop rebuilding. Concurrent mutations execute
independently; only the latest invocation controls the observer snapshot.
`reset()` clears the snapshot without undoing a server operation. An uncertain
write outcome and version-conflict resolution remain application responsibilities.

## SSR and hydration

Create a fresh `QueryClient(server: true)` for each request. Authenticate and
prefetch with `await client.prefetchQuery(options)` before rendering. Supply a
`QueryCodec<T>` on definitions whose successful data should be serialized.
`dehydrate()` produces a versioned JSON-compatible map containing keys, data and
fetch timestamps. Embed it using safe script/JSON escaping; never embed secrets.

Restore using `client.hydrate(state)` **before** the initial browser render.
Register the same keys/codecs on both sides. Newer browser data wins over an old
snapshot. A fresh hydrated query does not immediately refetch. Server hooks read
cached data and never start I/O, timers or browser subscriptions. Dispose the
server client after the response is rendered. Authenticated SSR requires an
actual server-readable session and server repository/transport implementation.
