// Portions of this file are adapted from flutter_hooks 0.21.3+1.
// Copyright (c) 2018 Remi Rousselet. Licensed under the MIT License.

import 'dart:async';

import 'package:jaspr/jaspr.dart';

import 'framework.dart';

/// A mutable state store updated through actions.
abstract class Store<StateT, ActionT> {
  /// Creates a reducer-backed store interface.
  Store();

  /// The current state.
  StateT get state;

  /// Synchronously applies [action].
  void dispatch(ActionT action);
}

/// Combines a state and action into the next state.
typedef Reducer<StateT, ActionT> = StateT Function(StateT state, ActionT action);

/// Creates a reducer-backed [Store].
Store<StateT, ActionT> useReducer<StateT, ActionT>(
  Reducer<StateT, ActionT> reducer, {
  required StateT initialState,
  required ActionT initialAction,
}) {
  return use(
    _ReducerHook<StateT, ActionT>(
      reducer,
      initialState: initialState,
      initialAction: initialAction,
    ),
  );
}

class _ReducerHook<StateT, ActionT> extends Hook<Store<StateT, ActionT>> {
  const _ReducerHook(this.reducer, {required this.initialState, required this.initialAction});

  final Reducer<StateT, ActionT> reducer;
  final StateT initialState;
  final ActionT initialAction;

  @override
  _ReducerHookState<StateT, ActionT> createState() => _ReducerHookState<StateT, ActionT>();
}

class _ReducerHookState<StateT, ActionT> extends HookState<Store<StateT, ActionT>, _ReducerHook<StateT, ActionT>>
    implements Store<StateT, ActionT> {
  @override
  late StateT state = hook.reducer(hook.initialState, hook.initialAction);

  @override
  void initHook() {
    state;
  }

  @override
  void dispatch(ActionT action) {
    final nextState = hook.reducer(state, action);
    if (state != nextState) {
      setState(() => state = nextState);
    }
  }

  @override
  Store<StateT, ActionT> build(BuildContext context) => this;
}

/// Returns the value supplied during the preceding build, or `null` initially.
T? usePrevious<T>(T value) => use(_PreviousHook<T>(value));

class _PreviousHook<T> extends Hook<T?> {
  const _PreviousHook(this.value);

  final T value;

  @override
  _PreviousHookState<T> createState() => _PreviousHookState<T>();
}

class _PreviousHookState<T> extends HookState<T?, _PreviousHook<T>> {
  T? _previous;

  @override
  void didUpdateHook(_PreviousHook<T> oldHook) {
    _previous = oldHook.value;
  }

  @override
  T? build(BuildContext context) => _previous;
}

/// Function that reports whether its hook remains mounted.
typedef IsMounted = bool Function();

/// Returns a stable callback that becomes `false` after hook disposal.
IsMounted useIsMounted() => use(const _IsMountedHook());

class _IsMountedHook extends Hook<IsMounted> {
  const _IsMountedHook();

  @override
  _IsMountedHookState createState() => _IsMountedHookState();
}

class _IsMountedHookState extends HookState<IsMounted, _IsMountedHook> {
  bool _mounted = true;

  @override
  IsMounted build(BuildContext context) => _isMounted;

  bool _isMounted() => _mounted;

  @override
  void dispose() {
    _mounted = false;
  }
}

/// Returns [value] after it has remained unchanged for [timeout].
///
/// The hook returns `null` and creates no timer during server rendering.
T? useDebounced<T>(T value, Duration timeout) {
  return use(_DebouncedHook<T>(value: value, timeout: timeout));
}

class _DebouncedHook<T> extends Hook<T?> {
  const _DebouncedHook({required this.value, required this.timeout});

  final T value;
  final Duration timeout;

  @override
  _DebouncedHookState<T> createState() => _DebouncedHookState<T>();
}

class _DebouncedHookState<T> extends HookState<T?, _DebouncedHook<T>> {
  T? _value;
  Timer? _timer;

  @override
  void initHook() {
    if (context.binding.isClient) {
      _start(hook.value);
    }
  }

  @override
  void didUpdateHook(_DebouncedHook<T> oldHook) {
    if (context.binding.isClient && (hook.value != oldHook.value || hook.timeout != oldHook.timeout)) {
      _start(hook.value);
    }
  }

  void _start(T value) {
    _timer?.cancel();
    _timer = Timer(hook.timeout, () {
      if (mounted) {
        setState(() => _value = value);
      }
    });
  }

  @override
  T? build(BuildContext context) => _value;

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
