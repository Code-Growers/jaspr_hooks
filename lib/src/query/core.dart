import 'dart:async';
import 'dart:convert';

/// Immutable, canonical JSON key. Map order is ignored; list order is significant.
/// Include all filters, pagination and identity-dependent inputs in the key.
final class QueryKey {
  QueryKey(List<Object?> parts) : encoded = jsonEncode(_canonical(parts));
  QueryKey._(this.encoded);
  final String encoded;
  List<Object?> get parts => (jsonDecode(encoded) as List).cast<Object?>();
  bool startsWith(QueryKey prefix) {
    final own = parts;
    final other = prefix.parts;
    return own.length >= other.length &&
        List.generate(other.length, (i) => jsonEncode(own[i]) == jsonEncode(other[i])).every((v) => v);
  }

  @override
  bool operator ==(Object other) => other is QueryKey && encoded == other.encoded;
  @override
  int get hashCode => encoded.hashCode;
  @override
  String toString() => encoded;
}

Object? _canonical(Object? value) {
  if (value is Map<String, Object?>) {
    final keys = value.keys.toList()..sort();
    return {for (final key in keys) key: _canonical(value[key])};
  }
  if (value is List) return value.map(_canonical).toList();
  if (value == null || value is String || value is bool || (value is num && value.isFinite)) return value;
  throw ArgumentError.value(value, 'key', 'Query keys require finite JSON values');
}

/// A cancelled query must never publish a late result into the cache.
final class QueryCancelled implements Exception {
  const QueryCancelled();
}

/// Cooperative cancellation. Transports should register their cancellation API.
final class QuerySignal {
  final _listeners = <void Function()>[];
  final _cancellation = Completer<void>();
  Future<void> get whenCancelled => _cancellation.future;
  bool _cancelled = false;
  bool get isCancelled => _cancelled;
  void throwIfCancelled() {
    if (_cancelled) throw const QueryCancelled();
  }

  void Function() onCancel(void Function() callback) {
    if (_cancelled) {
      callback();
      return () {};
    }
    _listeners.add(callback);
    return () => _listeners.remove(callback);
  }

  void _cancel() {
    if (_cancelled) return;
    _cancelled = true;
    _cancellation.complete();
    for (final callback in List.of(_listeners)) {
      callback();
    }
    _listeners.clear();
  }
}

/// Inputs supplied to a repository query, including its per-attempt deadline.
final class QueryFunctionContext {
  const QueryFunctionContext({required this.key, required this.signal, required this.timeout});
  final QueryKey key;
  final QuerySignal signal;
  final Duration timeout;
}

enum QueryStatus { pending, success, error }

enum QueryFetchStatus { idle, fetching }

/// Immutable observable query state. Data can coexist with a refetch error.
final class QuerySnapshot<T> {
  const QuerySnapshot({
    this.data,
    this.hasData = false,
    this.error,
    this.status = QueryStatus.pending,
    this.fetchStatus = QueryFetchStatus.idle,
    this.updatedAt,
    this.failureCount = 0,
  });
  final T? data;
  final bool hasData;
  final Object? error;
  final QueryStatus status;
  final QueryFetchStatus fetchStatus;
  final DateTime? updatedAt;
  final int failureCount;
  bool get isPending => status == QueryStatus.pending;
  bool get isFetching => fetchStatus == QueryFetchStatus.fetching;
  bool get isLoading => isPending && isFetching;
  bool get isError => status == QueryStatus.error;
  bool get isSuccess => status == QueryStatus.success;
}

/// Transport-neutral query definition. Retries are opt-in AND require [readOnly].
/// A repository must enforce [timeout] on its actual request, using the context.
final class QueryOptions<T> {
  QueryOptions({
    required this.key,
    required this.queryFn,
    this.enabled = true,
    this.staleTime = const Duration(seconds: 30),
    this.gcTime = const Duration(minutes: 5),
    this.timeout = const Duration(seconds: 30),
    this.readOnly = false,
    this.retry = 0,
    this.retryWhen,
    this.retryDelay = defaultQueryRetryDelay,
    this.refetchOnMount = true,
    this.refetchOnWindowFocus = true,
    this.refetchOnReconnect = true,
    this.refetchInterval,
    this.codec,
  }) {
    if (retry < 0 || (retry > 0 && !readOnly)) throw ArgumentError('Retries require an explicitly read-only query');
    if (timeout <= Duration.zero ||
        staleTime.isNegative ||
        gcTime.isNegative ||
        (refetchInterval != null && refetchInterval! <= Duration.zero)) {
      throw ArgumentError('Invalid query duration');
    }
  }
  final QueryKey key;
  final Future<T> Function(QueryFunctionContext context) queryFn;
  final bool enabled;
  final Duration staleTime;
  final Duration gcTime;
  final Duration timeout;
  final bool readOnly;
  final int retry;
  final bool Function(Object error)? retryWhen;
  final Duration Function(int failureCount) retryDelay;
  final bool refetchOnMount;
  final bool refetchOnWindowFocus;
  final bool refetchOnReconnect;
  final Duration? refetchInterval;
  final QueryCodec<T>? codec;
}

Duration defaultQueryRetryDelay(int failureCount) =>
    Duration(milliseconds: 1000 * (1 << (failureCount - 1).clamp(0, 5)));

/// Explicit wire codec for SSR. Do not serialize tokens or errors in query data.
final class QueryCodec<T> {
  const QueryCodec({required this.encode, required this.decode});
  final Object? Function(T value) encode;
  final T Function(Object? value) decode;
}

/// Shared query cache. Create one per SSR request and one per browser identity.
/// Dispose on logout/identity changes; never share a server instance globally.
final class QueryClient {
  QueryClient({DateTime Function()? now, this.server = false}) : _now = now ?? DateTime.now;
  final DateTime Function() _now;
  final bool server;
  final _entries = <QueryKey, QueryObserver<dynamic>>{};
  final _hydrated = <QueryKey, Map<String, Object?>>{};
  bool _disposed = false;

  QueryObserver<T> observe<T>(QueryOptions<T> options) {
    if (_disposed) throw StateError('QueryClient is disposed');
    final existing = _entries[options.key];
    if (existing != null) {
      if (existing is! QueryObserver<T>) {
        throw StateError('Query key reused with a different data type: ${options.key}');
      }
      return existing;
    }
    final entry = QueryObserver<T>._(this, options);
    _entries[options.key] = entry;
    entry._hydrate(_hydrated.remove(options.key));
    return entry;
  }

  Future<T> fetchQuery<T>(QueryOptions<T> options, {bool force = false}) =>
      observe(options).fetch(options, force: force);
  Future<void> prefetchQuery<T>(QueryOptions<T> options) async {
    await fetchQuery(options);
  }

  QuerySnapshot<T>? getQueryState<T>(QueryKey key) => (_entries[key] as QueryObserver<T>?)?.snapshot;
  T? getQueryData<T>(QueryKey key) => getQueryState<T>(key)?.data;
  void setQueryData<T>(QueryOptions<T> options, T data, {DateTime? updatedAt}) =>
      observe(options)._setData(data, updatedAt ?? _now());

  /// Marks all matching keys stale; active enabled observers refetch by default.
  Future<void> invalidateQueries(QueryKey prefix, {bool refetch = true}) async {
    final pending = <Future<void>>[];
    for (final entry in List.of(_entries.values)) {
      if (!entry.key.startsWith(prefix)) continue;
      entry.cancel();
      entry._invalidated = true;
      if (refetch && entry.isActive) pending.add(entry._refetchActive());
    }
    await Future.wait(pending);
  }

  Future<void> refetchQueries(QueryKey prefix) async {
    await Future.wait([
      for (final entry in List.of(_entries.values))
        if (entry.key.startsWith(prefix) && entry.isActive) entry._refetchActive(),
    ]);
  }

  void cancelQueries(QueryKey prefix) {
    for (final entry in _entries.values) {
      if (entry.key.startsWith(prefix)) entry.cancel();
    }
  }

  void removeQueries(QueryKey prefix) {
    for (final entry in List.of(_entries.values)) {
      if (!entry.key.startsWith(prefix)) continue;
      if (entry._subscriptions.isNotEmpty) {
        entry._reset();
      } else {
        _remove(entry);
      }
    }
    _hydrated.removeWhere((key, _) => key.startsWith(prefix));
  }

  /// Called by the browser adapter; only stale active queries are revalidated.
  void onWindowFocus() => _lifecycle((o) => o.refetchOnWindowFocus);
  void onReconnect() => _lifecycle((o) => o.refetchOnReconnect);
  void _lifecycle(bool Function(QueryOptions<dynamic>) shouldFetch) {
    if (_disposed || server) return;
    for (final entry in _entries.values) {
      final options = entry._activeOptions.where(shouldFetch).firstOrNull;
      if (options != null && entry.isStale(options)) entry._backgroundFetch(options);
    }
  }

  void _remove(QueryObserver<dynamic> entry) {
    if (!identical(_entries[entry.key], entry)) return;
    entry._dispose();
    _entries.remove(entry.key);
  }

  /// Successful entries with a codec only. Embed using a safe JSON/script encoder.
  Map<String, Object?> dehydrate() => {
    'version': 1,
    'queries': [
      for (final entry in _entries.values)
        if (entry.snapshot.hasData && entry.options.codec != null) entry._dehydrate(),
    ],
  };

  /// Restore before rendering/hydrating the first client frame. Newer local data wins.
  void hydrate(Map<String, Object?> state) {
    if (_disposed) throw StateError('QueryClient is disposed');
    if (state['version'] != 1) throw ArgumentError('Unsupported query hydration version');
    for (final raw in state['queries'] as List) {
      final row = Map<String, Object?>.from(raw as Map);
      final key = QueryKey._(row['key'] as String);
      final existing = _entries[key];
      if (existing != null) {
        existing._hydrate(row);
      } else {
        final previous = _hydrated[key];
        if (previous == null || (row['updatedAt'] as int) > (previous['updatedAt'] as int)) _hydrated[key] = row;
      }
    }
  }

  void clear() {
    for (final entry in List.of(_entries.values)) {
      entry._reset();
    }
    _hydrated.clear();
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final entry in _entries.values) {
      entry._dispose();
    }
    _entries.clear();
    _hydrated.clear();
  }
}

/// Cache entry and framework-independent observer. Subscriptions own no server I/O.
final class QueryObserver<T> {
  QueryObserver._(this.client, this.options);
  final QueryClient client;
  QueryOptions<T> options;
  QueryKey get key => options.key;
  QuerySnapshot<T> snapshot = QuerySnapshot<T>();
  final _subscriptions = <Object, ({QueryOptions<T> options, void Function() notify})>{};
  Iterable<QueryOptions<T>> get _activeOptions => _subscriptions.values.map((s) => s.options).where((o) => o.enabled);
  bool get isActive => _activeOptions.isNotEmpty;
  bool _invalidated = false;
  bool _disposed = false;
  int _generation = 0;
  Future<T>? _pending;
  QuerySignal? _signal;
  Timer? _gc;
  Timer? _poll;

  bool isStale([QueryOptions<T>? definition]) =>
      _invalidated ||
      !snapshot.hasData ||
      client._now().difference(snapshot.updatedAt!) >= (definition ?? options).staleTime;

  /// Subscribe on the client; unsubscribe releases polling and schedules eviction.
  /// Last unsubscribe cancels in-flight requests and prevents late cache writes.
  void Function() subscribe(void Function() notify, {QueryOptions<T>? definition}) {
    if (_disposed) throw StateError('Query observer is disposed');
    final token = Object();
    final current = definition ?? options;
    _subscriptions[token] = (options: current, notify: notify);
    _gc?.cancel();
    if (!client.server && current.enabled && (current.refetchOnMount || !snapshot.hasData) && isStale(current)) {
      _backgroundFetch(current);
    }
    _updatePolling();
    return () {
      _subscriptions.remove(token);
      _updatePolling();
      if (_subscriptions.isEmpty) {
        cancel();
        _scheduleGc();
      }
    };
  }

  void _notify() {
    for (final subscription in List.of(_subscriptions.values)) {
      subscription.notify();
    }
  }

  void _updatePolling() {
    _poll?.cancel();
    if (client.server) return;
    final durations = _activeOptions.map((o) => o.refetchInterval).whereType<Duration>().toList()..sort();
    if (durations.isNotEmpty) {
      _poll = Timer.periodic(durations.first, (_) {
        if (isActive) _backgroundFetch(_activeOptions.first);
      });
    }
  }

  void _scheduleGc() {
    _gc?.cancel();
    if (!client.server && !_disposed && !client._disposed && _subscriptions.isEmpty) {
      _gc = Timer(options.gcTime, () => client._remove(this));
    }
  }

  void _backgroundFetch(QueryOptions<T> definition) {
    unawaited(fetch(definition, force: true).then<void>((_) {}, onError: (Object _, StackTrace _) {}));
  }

  Future<void> _refetchActive() async {
    if (!isActive) return;
    try {
      await fetch(_activeOptions.first, force: true);
    } on Object {
      /* Failure lives in snapshot. */
    }
  }

  Future<T> fetch(QueryOptions<T> definition, {bool force = false}) {
    if (_disposed || client._disposed) return Future.error(StateError('QueryClient is disposed'));
    final current = definition;
    final active = _pending;
    if (active != null) return active;
    if (!force && !isStale(current)) return Future.value(snapshot.data as T);
    options = current;
    _gc?.cancel();
    final generation = ++_generation;
    final signal = _signal = QuerySignal();
    final completion = Completer<T>();
    _pending = completion.future;
    snapshot = QuerySnapshot(
      data: snapshot.data,
      hasData: snapshot.hasData,
      status: snapshot.status,
      fetchStatus: QueryFetchStatus.fetching,
      updatedAt: snapshot.updatedAt,
    );
    _notify();
    unawaited(_run(current, signal, generation).then(completion.complete, onError: completion.completeError));
    return completion.future;
  }

  Future<T> _run(QueryOptions<T> current, QuerySignal signal, int generation) async {
    var failures = 0;
    try {
      while (true) {
        signal.throwIfCancelled();
        try {
          final value = await _attempt(current, signal);
          signal.throwIfCancelled();
          if (generation == _generation) {
            _invalidated = false;
            snapshot = QuerySnapshot(data: value, hasData: true, status: QueryStatus.success, updatedAt: client._now());
          }
          return value;
        } catch (error) {
          signal.throwIfCancelled();
          failures++;
          if (failures > current.retry || !(current.retryWhen?.call(error) ?? false)) rethrow;
          snapshot = QuerySnapshot(
            data: snapshot.data,
            hasData: snapshot.hasData,
            status: snapshot.status,
            fetchStatus: QueryFetchStatus.fetching,
            error: error,
            updatedAt: snapshot.updatedAt,
            failureCount: failures,
          );
          _notify();
          await _delay(current.retryDelay(failures), signal);
        }
      }
    } catch (error) {
      if (generation == _generation && error is! QueryCancelled) {
        snapshot = QuerySnapshot(
          data: snapshot.data,
          hasData: snapshot.hasData,
          error: error,
          status: QueryStatus.error,
          updatedAt: snapshot.updatedAt,
          failureCount: failures,
        );
      }
      rethrow;
    } finally {
      if (generation == _generation) {
        _pending = null;
        _signal = null;
        _notify();
        _scheduleGc();
      }
    }
  }

  Future<T> _attempt(QueryOptions<T> current, QuerySignal parent) async {
    final signal = QuerySignal();
    final cancelled = Completer<T>();
    final remove = parent.onCancel(() {
      signal._cancel();
      if (!cancelled.isCompleted) cancelled.completeError(const QueryCancelled());
    });
    final timer = Timer(current.timeout, () {
      signal._cancel();
      if (!cancelled.isCompleted) cancelled.completeError(TimeoutException('Query deadline exceeded', current.timeout));
    });
    try {
      return await Future.any<T>([
        Future.sync(() => current.queryFn(QueryFunctionContext(key: key, signal: signal, timeout: current.timeout))),
        cancelled.future,
      ]);
    } finally {
      timer.cancel();
      remove();
    }
  }

  void cancel() {
    _generation++;
    _signal?._cancel();
    _signal = null;
    _pending = null;
    if (snapshot.isFetching) {
      snapshot = QuerySnapshot(
        data: snapshot.data,
        hasData: snapshot.hasData,
        status: snapshot.status,
        error: snapshot.error,
        updatedAt: snapshot.updatedAt,
      );
      _notify();
    }
  }

  void _setData(T data, DateTime updatedAt) {
    cancel();
    _invalidated = false;
    snapshot = QuerySnapshot(data: data, hasData: true, status: QueryStatus.success, updatedAt: updatedAt);
    _notify();
    _scheduleGc();
  }

  Map<String, Object?> _dehydrate() => {
    'key': key.encoded,
    'data': options.codec!.encode(snapshot.data as T),
    'updatedAt': snapshot.updatedAt!.millisecondsSinceEpoch,
  };
  void _hydrate(Map<String, Object?>? row) {
    if (row == null || options.codec == null) return;
    final timestamp = DateTime.fromMillisecondsSinceEpoch(row['updatedAt'] as int);
    if (snapshot.updatedAt != null && !timestamp.isAfter(snapshot.updatedAt!)) return;
    _setData(options.codec!.decode(row['data']), timestamp);
  }

  void _reset() {
    cancel();
    _invalidated = false;
    snapshot = QuerySnapshot<T>();
    _notify();
  }

  void _dispose() {
    _disposed = true;
    _gc?.cancel();
    _poll?.cancel();
    cancel();
    _subscriptions.clear();
  }
}

Future<void> _delay(Duration duration, QuerySignal signal) async {
  final completion = Completer<void>();
  final timer = Timer(duration, completion.complete);
  final remove = signal.onCancel(() {
    timer.cancel();
    if (!completion.isCompleted) completion.complete();
  });
  try {
    await completion.future;
    signal.throwIfCancelled();
  } finally {
    remove();
    timer.cancel();
  }
}
