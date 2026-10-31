import 'dart:async';

import 'package:jaspr/jaspr.dart';

import 'framework.dart';
import 'primitives.dart';

/// Keeps the latest [value] in a stable reference without requesting rebuilds.
///
/// The reference is updated during every component build.
ObjectRef<T> useLatest<T>(T value) {
  final reference = useRef(value);
  reference.value = value;
  return reference;
}

/// Creates an owned resource and disposes it when [keys] change or its hook is
/// removed.
///
/// Creation runs during both server and client builds and must be deterministic.
/// Each resource retains the disposer supplied when that resource was created.
/// Hot reload replaces the resource on the next build. Cleanup follows element
/// unmounting, not HTTP response completion; manage server request resources
/// explicitly with `try`/`finally` in the caller.
T useDisposable<T>(
  T Function() create,
  void Function(T value) dispose, [
  List<Object?> keys = const <Object?>[],
]) {
  return use(_DisposableHook<T>(create, dispose, keys: keys));
}

class _DisposableHook<T> extends Hook<T> {
  const _DisposableHook(this.create, this.disposeResource, {required super.keys});

  final T Function() create;
  final void Function(T value) disposeResource;

  @override
  _DisposableHookState<T> createState() => _DisposableHookState<T>();
}

class _DisposableHookState<T> extends HookState<T, _DisposableHook<T>> {
  T? _value;
  void Function(T value)? _disposeResource;
  bool _initialized = false;
  bool _needsRecreate = false;

  @override
  void initHook() {
    _createResource();
  }

  void _createResource() {
    final value = hook.create();
    _value = value;
    _disposeResource = hook.disposeResource;
    _initialized = true;
  }

  @override
  void reassemble() {
    _needsRecreate = true;
  }

  @override
  T build(BuildContext context) {
    if (_needsRecreate) {
      try {
        _disposeResourceValue();
      } catch (error, stackTrace) {
        reportHookError(error, stackTrace);
      }
      _createResource();
      _needsRecreate = false;
    }
    return _value as T;
  }

  @override
  void dispose() => _disposeResourceValue();

  void _disposeResourceValue() {
    if (!_initialized) {
      return;
    }
    final value = _value as T;
    final disposeResource = _disposeResource!;
    _initialized = false;
    _value = null;
    _disposeResource = null;
    disposeResource(value);
  }
}

/// Subscribes [notify] to an external store and returns its unsubscribe
/// callback.
typedef ExternalStoreSubscribe = Dispose Function(VoidCallback notify);

/// Decides whether two external-store snapshots represent the same value.
typedef ExternalStoreSnapshotEquals<T> = bool Function(T previous, T current);

/// Reads and subscribes to an external immutable snapshot.
///
/// Server rendering reads [getServerSnapshot] when supplied and otherwise
/// [getSnapshot], without subscribing. On a browser client, providing
/// [getServerSnapshot] preserves that value through the first build, then
/// subscribes and reads [getSnapshot] after the first frame. Without a server
/// snapshot, the client subscribes immediately. If replacing a subscription
/// throws while unsubscribing, the error is reported and the new subscription
/// is still established.
T useExternalStore<T>(
  ExternalStoreSubscribe subscribe,
  T Function() getSnapshot, {
  T Function()? getServerSnapshot,
  ExternalStoreSnapshotEquals<T>? equals,
}) {
  return use(
    _ExternalStoreHook<T>(
      subscribe,
      getSnapshot,
      getServerSnapshot: getServerSnapshot,
      equals: equals,
    ),
  );
}

class _ExternalStoreHook<T> extends Hook<T> {
  const _ExternalStoreHook(
    this.subscribe,
    this.getSnapshot, {
    required this.getServerSnapshot,
    required this.equals,
  });

  final ExternalStoreSubscribe subscribe;
  final T Function() getSnapshot;
  final T Function()? getServerSnapshot;
  final ExternalStoreSnapshotEquals<T>? equals;

  @override
  _ExternalStoreHookState<T> createState() => _ExternalStoreHookState<T>();
}

class _ExternalStoreHookState<T> extends HookState<T, _ExternalStoreHook<T>> {
  T? _snapshot;
  Dispose? _unsubscribe;
  bool _hasSnapshot = false;
  bool _awaitingClientActivation = false;
  bool _isConnecting = false;
  bool _notifiedWhileConnecting = false;
  int _subscriptionGeneration = 0;

  @override
  void initHook() {
    if (!context.binding.isClient) {
      _readServerSnapshot();
      return;
    }

    final getServerSnapshot = hook.getServerSnapshot;
    if (getServerSnapshot != null) {
      _setSnapshot(getServerSnapshot());
      _awaitingClientActivation = true;
      context.binding.addPostFrameCallback(_activateClient);
      return;
    }

    _setSnapshot(hook.getSnapshot());
    _connect();
  }

  @override
  void didUpdateHook(_ExternalStoreHook<T> oldHook) {
    if (!context.binding.isClient) {
      _readServerSnapshot();
      return;
    }

    if (_awaitingClientActivation) {
      final getServerSnapshot = hook.getServerSnapshot;
      if (getServerSnapshot != null) {
        _setSnapshot(getServerSnapshot());
      }
      return;
    }

    if (hook.subscribe != oldHook.subscribe) {
      _disconnectForReplacement();
      _connect();
    } else {
      final next = hook.getSnapshot();
      if (!_snapshotsEqual(_snapshot as T, next)) {
        _setSnapshot(next);
      }
    }
  }

  void _readServerSnapshot() {
    final getServerSnapshot = hook.getServerSnapshot;
    _setSnapshot(getServerSnapshot == null ? hook.getSnapshot() : getServerSnapshot());
  }

  void _activateClient() {
    if (!mounted || !_awaitingClientActivation) {
      return;
    }
    _awaitingClientActivation = false;
    try {
      if (_connect()) {
        setState(() {});
      }
    } catch (error, stackTrace) {
      reportHookError(error, stackTrace);
    }
  }

  bool _connect() {
    final generation = ++_subscriptionGeneration;
    Dispose? unsubscribe;
    _isConnecting = true;
    _notifiedWhileConnecting = false;
    try {
      unsubscribe = hook.subscribe(() => _handleStoreChange(generation));
      var next = hook.getSnapshot();
      if (_notifiedWhileConnecting) {
        _notifiedWhileConnecting = false;
        next = hook.getSnapshot();
      }
      final changed = !_hasSnapshot || !_snapshotsEqual(_snapshot as T, next);
      if (changed) {
        _setSnapshot(next);
      }
      _unsubscribe = unsubscribe;
      return changed;
    } catch (error, stackTrace) {
      _subscriptionGeneration++;
      if (unsubscribe != null) {
        try {
          unsubscribe();
        } catch (cleanupError, cleanupStackTrace) {
          reportHookError(cleanupError, cleanupStackTrace);
        }
      }
      Error.throwWithStackTrace(error, stackTrace);
    } finally {
      _isConnecting = false;
    }
  }

  void _handleStoreChange(int generation) {
    if (!mounted || generation != _subscriptionGeneration) {
      return;
    }
    if (_isConnecting) {
      _notifiedWhileConnecting = true;
      return;
    }

    try {
      final current = _snapshot as T;
      final next = hook.getSnapshot();
      if (!_snapshotsEqual(current, next)) {
        setState(() => _setSnapshot(next));
      }
    } catch (error, stackTrace) {
      reportHookError(error, stackTrace);
    }
  }

  bool _snapshotsEqual(T previous, T current) {
    final equals = hook.equals;
    if (equals != null) {
      return equals(previous, current);
    }
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

  void _setSnapshot(T value) {
    _snapshot = value;
    _hasSnapshot = true;
  }

  void _disconnect() {
    _subscriptionGeneration++;
    final unsubscribe = _unsubscribe;
    _unsubscribe = null;
    unsubscribe?.call();
  }

  void _disconnectForReplacement() {
    try {
      _disconnect();
    } catch (error, stackTrace) {
      reportHookError(error, stackTrace);
    }
  }

  @override
  T build(BuildContext context) {
    if (!_hasSnapshot) {
      throw StateError('useExternalStore() did not produce an initial snapshot.');
    }
    return _snapshot as T;
  }

  @override
  void dispose() {
    _awaitingClientActivation = false;
    _subscriptionGeneration++;
    final unsubscribe = _unsubscribe;
    _unsubscribe = null;
    unsubscribe?.call();
  }
}

/// Reads and subscribes to the nearest Jaspr inherited component of type [T].
T? useInherited<T extends InheritedComponent>({Object? aspect}) {
  return useContext().dependOnInheritedComponentOfExactType<T>(aspect: aspect);
}

/// Exposes a generated handle through [target] until this hook is replaced or
/// removed.
///
/// With omitted [keys], the handle is recreated on every build. With keys, it
/// is recreated only when their ordered contents or [target] change.
/// Creation also runs during server rendering and must be deterministic.
void useImperativeHandle<T extends Object>(
  ObjectRef<T?>? target,
  T Function() createHandle, [
  List<Object?>? keys,
]) {
  use(_ImperativeHandleHook<T>(target, createHandle, keys: keys));
}

class _ImperativeHandleHook<T extends Object> extends Hook<void> {
  const _ImperativeHandleHook(this.target, this.createHandle, {required super.keys});

  final ObjectRef<T?>? target;
  final T Function() createHandle;

  @override
  _ImperativeHandleHookState<T> createState() => _ImperativeHandleHookState<T>();
}

class _ImperativeHandleHookState<T extends Object> extends HookState<void, _ImperativeHandleHook<T>> {
  ObjectRef<T?>? _target;
  T? _handle;

  @override
  void initHook() {
    _replaceHandle();
  }

  @override
  void didUpdateHook(_ImperativeHandleHook<T> oldHook) {
    if (hook.keys == null || hook.target != oldHook.target) {
      _replaceHandle();
    }
  }

  void _replaceHandle() {
    final target = hook.target;
    if (target == null) {
      _clearHandle();
      return;
    }
    final nextHandle = hook.createHandle();
    _clearHandle();
    _target = target;
    _handle = nextHandle;
    target.value = nextHandle;
  }

  void _clearHandle() {
    final target = _target;
    final handle = _handle;
    _target = null;
    _handle = null;
    if (target != null && identical(target.value, handle)) {
      target.value = null;
    }
  }

  @override
  void build(BuildContext context) {}

  @override
  void dispose() {
    _clearHandle();
  }
}

/// Invokes the latest [callback] once after [delay] on the browser client.
///
/// Passing a null delay disables and cancels the timeout. Callback changes do
/// not restart it.
void useTimeout(VoidCallback callback, Duration? delay) {
  final callbackReference = useLatest(callback);
  useEffect(() {
    if (delay == null) {
      return null;
    }
    final timer = Timer(delay, () => callbackReference.value());
    return timer.cancel;
  }, <Object?>[delay]);
}

/// Repeatedly invokes the latest [callback] every [interval] on the browser
/// client.
///
/// Passing a null interval disables and cancels the timer. When [immediate] is
/// true, the first invocation is queued without waiting for one interval.
void useInterval(
  VoidCallback callback,
  Duration? interval, {
  bool immediate = false,
}) {
  final callbackReference = useLatest(callback);
  useEffect(() {
    if (interval == null) {
      return null;
    }
    final immediateTimer = immediate ? Timer(Duration.zero, () => callbackReference.value()) : null;
    final timer = Timer.periodic(interval, (_) => callbackReference.value());
    return () {
      immediateTimer?.cancel();
      timer.cancel();
    };
  }, <Object?>[interval, immediate]);
}
