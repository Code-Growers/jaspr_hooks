---
title: useQuery
description: Shared server state with query and mutation hooks.
---

## What it does

Observe typed data with structured keys and a shared QueryClient. Key changes replace the subscription.

## Signature and parameters

```dart
QueryResult<T> useQuery<T>(QueryOptions<T> options, {QueryClient? client})
```

## Live demo

<HookDemo name="useQuery"/>

## Ownership and lifecycle

The app owns QueryClient and disposes it on logout or identity replacement.
Hooks remove subscriptions and browser listeners on unmount. The final query
unsubscribe cancels in-flight reads and schedules cache garbage collection.
Mutation callbacks finish cache updates even after their component unmounts.

## Server rendering

Hooks read prefetched data without starting I/O. Restore the dehydrated cache
before the first client render. Use a request-scoped server client and explicit
codecs; never put tokens into cached data. Mutations cannot execute in SSR hooks.

## Common mistakes

Include every input in query keys. Do not mutate cached protobuf objects as form
drafts. Read retries require explicit allowlisting and an error classifier;
mutations never retry. Repository transports enforce the supplied deadline and
register cancellation. Keep uncertain-save and version-conflict handling in the editor.

## Related APIs

See [the query guide](https://code-growers.github.io/jaspr_hooks/query/) for complete examples, defaults, prefetching,
invalidation, optimistic updates and SSR hydration. QueryClientProvider,
useQuery, useMutation, useQueryClient and useQueryLifecycle work together.
