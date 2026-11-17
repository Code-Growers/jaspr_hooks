import 'package:jaspr/jaspr.dart';

import '../foundation_hooks.dart';
import '../framework.dart';
import '../primitives.dart';
import 'core.dart';
import 'lifecycle_stub.dart' if (dart.library.js_interop) 'lifecycle_web.dart' as lifecycle;
import 'mutation.dart';

/// Provides an explicitly owned cache. The caller disposes [client] on identity
/// changes and, on the server, after response rendering. Hydrate it before mount.
class QueryClientProvider extends InheritedComponent {
  const QueryClientProvider({required this.client, required super.child, super.key});
  final QueryClient client;
  @override
  bool updateShouldNotify(covariant QueryClientProvider oldComponent) => client != oldComponent.client;
}

/// Reads the nearest cache without allocating one. Works during SSR.
QueryClient useQueryClient() {
  final provider = useInherited<QueryClientProvider>();
  if (provider == null) throw StateError('A QueryClientProvider is required');
  return provider.client;
}

/// Subscribes to a keyed query. SSR only reads prefetched cache data and starts
/// no I/O, subscriptions or timers. Hydrate the cache before the first client
/// render for matching HTML; subscriptions/fetching activate after that frame.
/// Key changes unsubscribe the old query. The last observer cancels its fetch.
QueryResult<T> useQuery<T>(QueryOptions<T> options, {QueryClient? client}) {
  final isClient = useContext().binding.isClient;
  final cache = client ?? useQueryClient();
  final observer = useMemoized(() => cache.observe(options), [cache, options.key]);
  final latest = useLatest(options);
  final subscribe = useCallback((void Function() notify) => observer.subscribe(notify, definition: latest.value), [
    observer,
    options.enabled,
    options.staleTime,
    options.gcTime,
    options.refetchOnMount,
    options.refetchOnWindowFocus,
    options.refetchOnReconnect,
    options.refetchInterval,
  ]);
  final snapshot = useExternalStore(subscribe, () => observer.snapshot, getServerSnapshot: () => observer.snapshot);
  return QueryResult(snapshot, () {
    if (!isClient) return Future.error(StateError('Prefetch queries outside server hook builds'));
    return observer.fetch(latest.value, force: true);
  });
}

/// Query state plus an explicit refetch operation, which propagates failures.
final class QueryResult<T> {
  const QueryResult(this.snapshot, this.refetch);
  final QuerySnapshot<T> snapshot;
  final Future<T> Function() refetch;
  T? get data => snapshot.data;
  Object? get error => snapshot.error;
  bool get hasData => snapshot.hasData;
  bool get isPending => snapshot.isPending;
  bool get isFetching => snapshot.isFetching;
  bool get isLoading => snapshot.isLoading;
  bool get isError => snapshot.isError;
  bool get isSuccess => snapshot.isSuccess;
  DateTime? get updatedAt => snapshot.updatedAt;
}

/// Owns mutation state until unmount. No mutation starts during SSR. Options
/// update on rebuild; each invocation retains the callbacks it started with.
MutationController<T, V> useMutation<T, V>(MutationOptions<T, V> options) {
  final isClient = useContext().binding.isClient;
  final controller = useDisposable(
    () => MutationController(options, allowExecution: isClient),
    (value) => value.dispose(),
  );
  controller.options = options;
  useExternalStore(controller.subscribe, () => controller.snapshot, getServerSnapshot: () => controller.snapshot);
  return controller;
}

/// Installs one browser focus/reconnect bridge per app cache. No work on SSR;
/// removes listeners on unmount or client replacement. Call once in the shell.
void useQueryLifecycle(QueryClient client) {
  useEffect(() => lifecycle.watchQueryLifecycle(client.onWindowFocus, client.onReconnect), [client]);
}
