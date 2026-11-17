import 'dart:async';

/// State of the latest mutation invocation. Mutations never retry automatically.
enum MutationStatus { idle, pending, success, error }

/// A mutation receives the actual transport deadline for this attempt.
final class MutationContext {
  const MutationContext(this.timeout);
  final Duration timeout;
}

/// Lifecycle callbacks run even after the initiating component unmounts, so
/// cache invalidation completes. Keep UI-only effects outside these callbacks.
final class MutationOptions<T, V> {
  const MutationOptions({
    required this.mutationFn,
    this.timeout = const Duration(seconds: 30),
    this.onMutate,
    this.onSuccess,
    this.onError,
    this.onSettled,
  });
  final Future<T> Function(V variables, MutationContext context) mutationFn;
  final Duration timeout;
  final FutureOr<Object?> Function(V variables)? onMutate;
  final FutureOr<void> Function(T data, V variables, Object? context)? onSuccess;
  final FutureOr<void> Function(Object error, V variables, Object? context)? onError;
  final FutureOr<void> Function(T? data, Object? error, V variables, Object? context)? onSettled;
}

final class MutationSnapshot<T> {
  const MutationSnapshot({this.status = MutationStatus.idle, this.data, this.error});
  final MutationStatus status;
  final T? data;
  final Object? error;
  bool get isPending => status == MutationStatus.pending;
  bool get isSuccess => status == MutationStatus.success;
  bool get isError => status == MutationStatus.error;
  bool get isIdle => status == MutationStatus.idle;
}

/// Framework-independent mutation observer; each invocation runs exactly once.
/// Concurrent calls are permitted. Only the latest call updates the snapshot.
final class MutationController<T, V> {
  MutationController(this.options, {this.allowExecution = true});
  final bool allowExecution;
  MutationOptions<T, V> options;
  MutationSnapshot<T> snapshot = MutationSnapshot<T>();
  final _listeners = <void Function()>{};
  int _generation = 0;
  bool _disposed = false;
  void Function() subscribe(void Function() notify) {
    _listeners.add(notify);
    return () => _listeners.remove(notify);
  }

  void _set(MutationSnapshot<T> next, int generation) {
    if (_disposed || generation != _generation) return;
    snapshot = next;
    for (final listener in List.of(_listeners)) {
      listener();
    }
  }

  Future<T> mutateAsync(V variables) async {
    if (_disposed || !allowExecution) throw StateError('Mutation execution requires an active client');
    final current = options;
    if (current.timeout <= Duration.zero) throw ArgumentError('Mutation timeout must be positive');
    final generation = ++_generation;
    _set(MutationSnapshot(status: MutationStatus.pending), generation);
    Object? context;
    T? data;
    Object? failure;
    try {
      context = await current.onMutate?.call(variables);
      final result = await current.mutationFn(variables, MutationContext(current.timeout));
      data = result;
      await current.onSuccess?.call(result, variables, context);
      _set(MutationSnapshot(status: MutationStatus.success, data: data), generation);
      return result;
    } catch (error) {
      failure = error;
      _set(MutationSnapshot(status: MutationStatus.error, error: error), generation);
      await current.onError?.call(error, variables, context);
      rethrow;
    } finally {
      await current.onSettled?.call(data, failure, variables, context);
    }
  }

  /// Event-handler convenience. Failures are exposed in the snapshot/callbacks.
  void mutate(V variables) =>
      unawaited(mutateAsync(variables).then<void>((_) {}, onError: (Object _, StackTrace _) {}));
  void reset() => _set(MutationSnapshot<T>(), ++_generation);
  void dispose() {
    _disposed = true;
    _generation++;
    _listeners.clear();
  }
}
