import 'dart:async';
import 'dart:collection';

import 'package:jaspr/jaspr.dart';

import 'framework.dart';

/// Determines how an [AsyncAction] handles overlapping dispatches.
enum ActionConcurrency {
  /// Runs dispatches in call order. Each action receives the state produced by
  /// the preceding successful action.
  sequential,

  /// Starts every dispatch immediately and only applies the latest result.
  latest,

  /// Rejects dispatches made while another dispatch is running with an
  /// [ActionDroppedException].
  drop,

  /// Starts every dispatch immediately and applies results in completion order.
  concurrent,
}

/// Computes the next state for an asynchronous action.
typedef AsyncActionHandler<StateT, InputT> = FutureOr<StateT> Function(
  StateT previousState,
  InputT input,
);

/// A stable controller for user-initiated asynchronous state changes.
abstract interface class AsyncAction<StateT, InputT> {
  /// The latest successfully committed state.
  StateT get state;

  /// Whether at least one relevant dispatch is waiting to complete.
  bool get isPending;

  /// The most recent relevant action error, or `null`.
  Object? get error;

  /// The stack trace associated with [error].
  StackTrace? get stackTrace;

  /// Runs the configured action with [input].
  Future<StateT> dispatch(InputT input);

  /// Restores the initial state and invalidates pending results on the client.
  void reset();
}

/// Thrown when [ActionConcurrency.drop] rejects an overlapping dispatch.
final class ActionDroppedException implements Exception {
  /// Creates an action-dropped error.
  const ActionDroppedException();

  @override
  String toString() => 'ActionDroppedException: an action is already pending.';
}

/// Thrown when a queued action is invalidated before it starts.
final class ActionCancelledException implements Exception {
  /// Creates an action-cancelled error.
  const ActionCancelledException();

  @override
  String toString() => 'ActionCancelledException: the action was invalidated before it started.';
}

/// Creates a stable controller for user-initiated asynchronous work.
///
/// [initialState] is captured when the hook is created. The latest [action]
/// supplied by a build is used when an operation starts.
///
/// The controller is idle during server rendering and [AsyncAction.dispatch]
/// and [AsyncAction.reset] throw when invoked there. Futures already running
/// cannot be physically cancelled, but results invalidated by
/// [AsyncAction.reset], replacement, or disposal are prevented from changing
/// hook state.
AsyncAction<StateT, InputT> useAsyncAction<StateT, InputT>({
  required StateT initialState,
  required AsyncActionHandler<StateT, InputT> action,
  ActionConcurrency concurrency = ActionConcurrency.sequential,
}) {
  return use(
    _AsyncActionHook<StateT, InputT>(
      initialState: initialState,
      action: action,
      concurrency: concurrency,
    ),
  );
}

class _AsyncActionHook<StateT, InputT> extends Hook<AsyncAction<StateT, InputT>> {
  const _AsyncActionHook({
    required this.initialState,
    required this.action,
    required this.concurrency,
  });

  final StateT initialState;
  final AsyncActionHandler<StateT, InputT> action;
  final ActionConcurrency concurrency;

  @override
  _AsyncActionHookState<StateT, InputT> createState() => _AsyncActionHookState<StateT, InputT>();
}

class _AsyncActionHookState<StateT, InputT>
    extends HookState<AsyncAction<StateT, InputT>, _AsyncActionHook<StateT, InputT>>
    implements AsyncAction<StateT, InputT> {
  final Queue<_QueuedAction<StateT, InputT>> _sequentialQueue = Queue<_QueuedAction<StateT, InputT>>();

  late final StateT _initialState;
  late StateT _state;
  Object? _error;
  StackTrace? _stackTrace;
  int _pendingCount = 0;
  int _epoch = 0;
  int _latestDispatch = 0;
  bool _sequentialRunning = false;
  bool _dropRunning = false;

  @override
  void initHook() {
    _initialState = hook.initialState;
    _state = _initialState;
  }

  @override
  StateT get state => _state;

  @override
  bool get isPending => _pendingCount > 0;

  @override
  Object? get error => _error;

  @override
  StackTrace? get stackTrace => _stackTrace;

  @override
  void didUpdateHook(_AsyncActionHook<StateT, InputT> oldHook) {
    if (oldHook.concurrency != hook.concurrency) {
      _invalidatePending(notify: false);
    }
  }

  @override
  Future<StateT> dispatch(InputT input) {
    _ensureClientMutation('dispatch');
    return switch (hook.concurrency) {
      ActionConcurrency.sequential => _dispatchSequential(input),
      ActionConcurrency.latest => _dispatchLatest(input),
      ActionConcurrency.drop => _dispatchDrop(input),
      ActionConcurrency.concurrent => _dispatchConcurrent(input),
    };
  }

  void _ensureClientMutation(String method) {
    if (!mounted) {
      throw StateError('AsyncAction.$method() called after the hook was disposed.');
    }
    if (!context.binding.isClient) {
      throw StateError(
        'AsyncAction.$method() cannot run during server or static rendering. '
        'Invoke action mutations from browser event handlers.',
      );
    }
  }

  Future<StateT> _dispatchSequential(InputT input) {
    final request = _QueuedAction<StateT, InputT>(input, _epoch);
    _sequentialQueue.add(request);
    setState(() {
      _pendingCount++;
      _clearError();
    });
    _drainSequentialQueue();
    return request.completer.future;
  }

  void _drainSequentialQueue() {
    if (_sequentialRunning || _sequentialQueue.isEmpty) {
      return;
    }
    final request = _sequentialQueue.removeFirst();
    if (request.epoch != _epoch || !mounted) {
      request.completeCancelled();
      _drainSequentialQueue();
      return;
    }
    _sequentialRunning = true;
    unawaited(_runSequential(request));
  }

  Future<void> _runSequential(_QueuedAction<StateT, InputT> request) async {
    try {
      final result = await Future<StateT>.sync(() => hook.action(_state, request.input));
      request.completer.complete(result);
      if (mounted && request.epoch == _epoch) {
        setState(() {
          _state = result;
          _pendingCount--;
          _clearError();
        });
      }
    } catch (error, stackTrace) {
      request.completer.completeError(error, stackTrace);
      if (mounted && request.epoch == _epoch) {
        setState(() {
          _pendingCount--;
          _error = error;
          _stackTrace = stackTrace;
        });
      }
    } finally {
      if (request.epoch == _epoch) {
        _sequentialRunning = false;
        _drainSequentialQueue();
      }
    }
  }

  Future<StateT> _dispatchLatest(InputT input) {
    final epoch = _epoch;
    final dispatch = ++_latestDispatch;
    final completer = Completer<StateT>();
    setState(() {
      _pendingCount = 1;
      _clearError();
    });
    unawaited(
      _invoke(input).then<void>(
        (result) {
          completer.complete(result);
          if (mounted && epoch == _epoch && dispatch == _latestDispatch) {
            setState(() {
              _state = result;
              _pendingCount = 0;
              _clearError();
            });
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          completer.completeError(error, stackTrace);
          if (mounted && epoch == _epoch && dispatch == _latestDispatch) {
            setState(() {
              _pendingCount = 0;
              _error = error;
              _stackTrace = stackTrace;
            });
          }
        },
      ),
    );
    return completer.future;
  }

  Future<StateT> _dispatchDrop(InputT input) {
    if (_dropRunning) {
      return Future<StateT>.error(const ActionDroppedException());
    }
    final epoch = _epoch;
    final completer = Completer<StateT>();
    _dropRunning = true;
    setState(() {
      _pendingCount = 1;
      _clearError();
    });
    unawaited(
      _invoke(input).then<void>(
        (result) {
          completer.complete(result);
          if (mounted && epoch == _epoch) {
            setState(() {
              _state = result;
              _pendingCount = 0;
              _dropRunning = false;
              _clearError();
            });
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          completer.completeError(error, stackTrace);
          if (mounted && epoch == _epoch) {
            setState(() {
              _pendingCount = 0;
              _dropRunning = false;
              _error = error;
              _stackTrace = stackTrace;
            });
          }
        },
      ),
    );
    return completer.future;
  }

  Future<StateT> _dispatchConcurrent(InputT input) {
    final epoch = _epoch;
    final completer = Completer<StateT>();
    setState(() {
      _pendingCount++;
      _clearError();
    });
    unawaited(
      _invoke(input).then<void>(
        (result) {
          completer.complete(result);
          if (mounted && epoch == _epoch) {
            setState(() {
              _state = result;
              _pendingCount--;
              _clearError();
            });
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          completer.completeError(error, stackTrace);
          if (mounted && epoch == _epoch) {
            setState(() {
              _pendingCount--;
              _error = error;
              _stackTrace = stackTrace;
            });
          }
        },
      ),
    );
    return completer.future;
  }

  Future<StateT> _invoke(InputT input) {
    return Future<StateT>.sync(() => hook.action(_state, input));
  }

  void _clearError() {
    _error = null;
    _stackTrace = null;
  }

  @override
  void reset() {
    _ensureClientMutation('reset');
    _invalidatePending(notify: true, resetState: true);
  }

  void _invalidatePending({required bool notify, bool resetState = false}) {
    _epoch++;
    _latestDispatch++;
    _sequentialRunning = false;
    _dropRunning = false;
    while (_sequentialQueue.isNotEmpty) {
      _sequentialQueue.removeFirst().completeCancelled();
    }
    void update() {
      _pendingCount = 0;
      if (resetState) {
        _state = _initialState;
      }
      _clearError();
    }

    if (notify) {
      setState(update);
    } else {
      update();
    }
  }

  @override
  AsyncAction<StateT, InputT> build(BuildContext context) => this;

  @override
  void dispose() {
    _invalidatePending(notify: false);
  }
}

final class _QueuedAction<StateT, InputT> {
  _QueuedAction(this.input, this.epoch);

  final InputT input;
  final int epoch;
  final Completer<StateT> completer = Completer<StateT>();

  void completeCancelled() {
    if (!completer.isCompleted) {
      completer.completeError(const ActionCancelledException());
    }
  }
}

/// A handle for one pending optimistic update.
abstract interface class OptimisticUpdateHandle<StateT> {
  /// Whether this update is still pending.
  bool get isPending;

  /// Accepts the update and replaces the authoritative base with [state].
  void commit(StateT state);

  /// Removes this update without changing the authoritative base.
  void rollback();
}

/// A stable controller for optimistic state layered over authoritative state.
abstract interface class OptimisticState<StateT, UpdateT> {
  /// The authoritative state with all pending updates applied in call order.
  StateT get value;

  /// Whether at least one optimistic update is unresolved.
  bool get hasPendingUpdates;

  /// The number of unresolved optimistic updates.
  int get pendingCount;

  /// Applies [update] immediately and returns its commit/rollback handle.
  OptimisticUpdateHandle<StateT> add(UpdateT update);

  /// Applies [update] while [operation] runs, committing or rolling back it.
  Future<ResultT> run<ResultT>(
    UpdateT update,
    Future<ResultT> Function() operation, {
    required StateT Function(ResultT result) authoritativeState,
  });

  /// Removes every pending update and restores the latest authoritative input.
  void reset();
}

/// Layers optimistic updates over [authoritativeState].
///
/// [reducer] must be deterministic and free of side effects because it can run
/// whenever [OptimisticState.value] is read, including during component builds.
///
/// When [authoritativeState] changes, unresolved updates are reapplied in their
/// original order. Calling [OptimisticUpdateHandle.commit] adopts the supplied
/// authoritative state before reapplying all other unresolved updates.
OptimisticState<StateT, UpdateT> useOptimistic<StateT, UpdateT>(
  StateT authoritativeState,
  StateT Function(StateT current, UpdateT update) reducer,
) {
  return use(
    _OptimisticHook<StateT, UpdateT>(
      authoritativeState: authoritativeState,
      reducer: reducer,
    ),
  );
}

class _OptimisticHook<StateT, UpdateT> extends Hook<OptimisticState<StateT, UpdateT>> {
  const _OptimisticHook({
    required this.authoritativeState,
    required this.reducer,
  });

  final StateT authoritativeState;
  final StateT Function(StateT current, UpdateT update) reducer;

  @override
  _OptimisticHookState<StateT, UpdateT> createState() => _OptimisticHookState<StateT, UpdateT>();
}

class _OptimisticHookState<StateT, UpdateT>
    extends HookState<OptimisticState<StateT, UpdateT>, _OptimisticHook<StateT, UpdateT>>
    implements OptimisticState<StateT, UpdateT> {
  final List<_OptimisticEntry<StateT, UpdateT>> _entries = <_OptimisticEntry<StateT, UpdateT>>[];

  late StateT _authoritative;

  @override
  void initHook() {
    _authoritative = hook.authoritativeState;
  }

  @override
  StateT get value {
    var result = _authoritative;
    for (final entry in _entries) {
      result = hook.reducer(result, entry.update);
    }
    return result;
  }

  @override
  bool get hasPendingUpdates => _entries.isNotEmpty;

  @override
  int get pendingCount => _entries.length;

  @override
  void didUpdateHook(_OptimisticHook<StateT, UpdateT> oldHook) {
    if (!_valuesMatch(oldHook.authoritativeState, hook.authoritativeState)) {
      _authoritative = hook.authoritativeState;
    }
  }

  @override
  OptimisticUpdateHandle<StateT> add(UpdateT update) {
    _ensureMutable('add');
    final entry = _OptimisticEntry<StateT, UpdateT>(this, update);
    setState(() => _entries.add(entry));
    return entry;
  }

  @override
  Future<ResultT> run<ResultT>(
    UpdateT update,
    Future<ResultT> Function() operation, {
    required StateT Function(ResultT result) authoritativeState,
  }) async {
    final handle = add(update);
    try {
      final result = await Future<ResultT>.sync(operation);
      if (handle.isPending) {
        final state = authoritativeState(result);
        if (handle.isPending) {
          handle.commit(state);
        }
      }
      return result;
    } catch (error, stackTrace) {
      if (handle.isPending) {
        handle.rollback();
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  void _ensureMutable(String method) {
    if (!mounted) {
      throw StateError('OptimisticState.$method() called after the hook was disposed.');
    }
    if (!context.binding.isClient) {
      throw StateError(
        'OptimisticState.$method() cannot run during server or static rendering. '
        'Apply optimistic updates from browser event handlers.',
      );
    }
  }

  void _commit(_OptimisticEntry<StateT, UpdateT> entry, StateT state) {
    _ensurePending(entry, 'commit');
    setState(() {
      _authoritative = state;
      _entries.remove(entry);
      entry.owner = null;
    });
  }

  void _rollback(_OptimisticEntry<StateT, UpdateT> entry) {
    _ensurePending(entry, 'rollback');
    setState(() {
      _entries.remove(entry);
      entry.owner = null;
    });
  }

  void _ensurePending(_OptimisticEntry<StateT, UpdateT> entry, String method) {
    _ensureMutable(method);
    if (!identical(entry.owner, this) || !_entries.contains(entry)) {
      throw StateError('This optimistic update is no longer pending.');
    }
  }

  @override
  void reset() {
    _ensureMutable('reset');
    setState(() {
      _authoritative = hook.authoritativeState;
      for (final entry in _entries) {
        entry.owner = null;
      }
      _entries.clear();
    });
  }

  @override
  OptimisticState<StateT, UpdateT> build(BuildContext context) => this;

  @override
  void dispose() {
    for (final entry in _entries) {
      entry.owner = null;
    }
    _entries.clear();
  }
}

bool _valuesMatch(Object? previous, Object? current) {
  if (previous is num && current is num) {
    if (previous.isNaN && current.isNaN) {
      return true;
    }
    if (previous == 0 && current == 0) {
      return previous.isNegative == current.isNegative;
    }
  }
  if (identical(previous, current)) {
    return true;
  }
  return previous == current;
}

final class _OptimisticEntry<StateT, UpdateT> implements OptimisticUpdateHandle<StateT> {
  _OptimisticEntry(this.owner, this.update);

  _OptimisticHookState<StateT, UpdateT>? owner;
  final UpdateT update;

  @override
  bool get isPending => owner != null;

  @override
  void commit(StateT state) {
    final currentOwner = owner;
    if (currentOwner == null) {
      throw StateError('This optimistic update is no longer pending.');
    }
    currentOwner._commit(this, state);
  }

  @override
  void rollback() {
    final currentOwner = owner;
    if (currentOwner == null) {
      throw StateError('This optimistic update is no longer pending.');
    }
    currentOwner._rollback(this);
  }
}
