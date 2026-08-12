// Portions of this file are adapted from flutter_hooks 0.21.3+1.
// Copyright (c) 2018 Remi Rousselet. Licensed under the MIT License.

import 'dart:async';

import 'package:jaspr/jaspr.dart';

import 'framework.dart';

/// Subscribes to [future] on the browser client and returns its latest snapshot.
///
/// A non-null future during server rendering throws a [StateError]. Pass `null`
/// on the server and use Jaspr preloading or synchronized state for SSR data.
AsyncSnapshot<T> useFuture<T>(Future<T>? future, {T? initialData, bool preserveState = true}) {
  return use(_FutureHook<T>(future, initialData: initialData, preserveState: preserveState));
}

class _FutureHook<T> extends Hook<AsyncSnapshot<T>> {
  const _FutureHook(this.future, {required this.initialData, required this.preserveState});

  final Future<T>? future;
  final T? initialData;
  final bool preserveState;

  @override
  _FutureHookState<T> createState() => _FutureHookState<T>();
}

class _FutureHookState<T> extends HookState<AsyncSnapshot<T>, _FutureHook<T>> {
  Object? _activeCallbackIdentity;
  late AsyncSnapshot<T> _snapshot = _initialSnapshot;

  AsyncSnapshot<T> get _initialSnapshot => hook.initialData == null
      ? AsyncSnapshot<T>.nothing()
      : AsyncSnapshot<T>.withData(ConnectionState.none, hook.initialData as T);

  @override
  void initHook() {
    _validateServerSource();
    _subscribe();
  }

  @override
  void didUpdateHook(_FutureHook<T> oldHook) {
    _validateServerSource();
    if (oldHook.future != hook.future) {
      if (_activeCallbackIdentity != null) {
        _unsubscribe();
        _snapshot = hook.preserveState ? _snapshot.inState(ConnectionState.none) : _initialSnapshot;
      }
      _subscribe();
    }
  }

  void _validateServerSource() {
    if (!context.binding.isClient && hook.future != null) {
      throw StateError(
        'useFuture() received a non-null Future while rendering on the server. '
        'Pass null on the server and use PreloadStateMixin, AsyncStatelessComponent, '
        'serialized @client properties, or jaspr_riverpod for SSR data.',
      );
    }
  }

  void _subscribe() {
    final future = hook.future;
    if (future == null || !context.binding.isClient) {
      return;
    }
    final callbackIdentity = Object();
    _activeCallbackIdentity = callbackIdentity;
    unawaited(
      future.then<void>(
        (data) {
          if (_activeCallbackIdentity == callbackIdentity && mounted) {
            setState(() => _snapshot = AsyncSnapshot<T>.withData(ConnectionState.done, data));
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          if (_activeCallbackIdentity == callbackIdentity && mounted) {
            setState(() => _snapshot = AsyncSnapshot<T>.withError(ConnectionState.done, error, stackTrace));
          }
        },
      ),
    );
    _snapshot = _snapshot.inState(ConnectionState.waiting);
  }

  void _unsubscribe() {
    _activeCallbackIdentity = null;
  }

  @override
  AsyncSnapshot<T> build(BuildContext context) => _snapshot;

  @override
  void dispose() {
    _unsubscribe();
  }
}

/// Subscribes to [stream] on the browser client and returns its latest snapshot.
///
/// A non-null stream during server rendering throws a [StateError].
AsyncSnapshot<T> useStream<T>(Stream<T>? stream, {T? initialData, bool preserveState = true}) {
  return use(_StreamHook<T>(stream, initialData: initialData, preserveState: preserveState));
}

class _StreamHook<T> extends Hook<AsyncSnapshot<T>> {
  const _StreamHook(this.stream, {required this.initialData, required this.preserveState});

  final Stream<T>? stream;
  final T? initialData;
  final bool preserveState;

  @override
  _StreamHookState<T> createState() => _StreamHookState<T>();
}

class _StreamHookState<T> extends HookState<AsyncSnapshot<T>, _StreamHook<T>> {
  // ignore: cancel_subscriptions, canceled by _unsubscribe/dispose.
  StreamSubscription<T>? _subscription;
  late AsyncSnapshot<T> _snapshot = _initialSnapshot;

  AsyncSnapshot<T> get _initialSnapshot => hook.initialData == null
      ? AsyncSnapshot<T>.nothing()
      : AsyncSnapshot<T>.withData(ConnectionState.none, hook.initialData as T);

  @override
  void initHook() {
    _validateServerSource();
    _subscribe();
  }

  @override
  void didUpdateHook(_StreamHook<T> oldHook) {
    _validateServerSource();
    if (oldHook.stream != hook.stream) {
      if (_subscription != null) {
        _unsubscribe();
        _snapshot = hook.preserveState ? _snapshot.inState(ConnectionState.none) : _initialSnapshot;
      }
      _subscribe();
    }
  }

  void _validateServerSource() {
    if (!context.binding.isClient && hook.stream != null) {
      throw StateError(
        'useStream() received a non-null Stream while rendering on the server. '
        'Pass null on the server and use Jaspr server-data facilities for SSR data.',
      );
    }
  }

  void _subscribe() {
    final stream = hook.stream;
    if (stream == null || !context.binding.isClient) {
      return;
    }
    _subscription = stream.listen(
      (data) {
        if (mounted) {
          setState(() => _snapshot = AsyncSnapshot<T>.withData(ConnectionState.active, data));
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (mounted) {
          setState(() => _snapshot = AsyncSnapshot<T>.withError(ConnectionState.active, error, stackTrace));
        }
      },
      onDone: () {
        if (mounted) {
          setState(() => _snapshot = _snapshot.inState(ConnectionState.done));
        }
      },
    );
    _snapshot = _snapshot.inState(ConnectionState.waiting);
  }

  void _unsubscribe() {
    final subscription = _subscription;
    _subscription = null;
    if (subscription != null) {
      unawaited(subscription.cancel());
    }
  }

  @override
  AsyncSnapshot<T> build(BuildContext context) => _snapshot;

  @override
  void dispose() {
    _unsubscribe();
  }
}

/// Creates a broadcast [StreamController] and closes it on hook disposal.
StreamController<T> useStreamController<T>({
  bool sync = false,
  VoidCallback? onListen,
  VoidCallback? onCancel,
  List<Object?>? keys,
}) {
  return use(
    _StreamControllerHook<T>(
      sync: sync,
      onListen: onListen,
      onCancel: onCancel,
      keys: keys,
    ),
  );
}

class _StreamControllerHook<T> extends Hook<StreamController<T>> {
  const _StreamControllerHook({
    required this.sync,
    required this.onListen,
    required this.onCancel,
    super.keys,
  });

  final bool sync;
  final VoidCallback? onListen;
  final VoidCallback? onCancel;

  @override
  _StreamControllerHookState<T> createState() => _StreamControllerHookState<T>();
}

class _StreamControllerHookState<T> extends HookState<StreamController<T>, _StreamControllerHook<T>> {
  late final StreamController<T> _controller = StreamController<T>.broadcast(
    sync: hook.sync,
    onListen: hook.onListen,
    onCancel: hook.onCancel,
  );

  @override
  void didUpdateHook(_StreamControllerHook<T> oldHook) {
    if (oldHook.onListen != hook.onListen) {
      _controller.onListen = hook.onListen;
    }
    if (oldHook.onCancel != hook.onCancel) {
      _controller.onCancel = hook.onCancel;
    }
  }

  @override
  StreamController<T> build(BuildContext context) => _controller;

  @override
  void dispose() {
    unawaited(_controller.close());
  }
}

/// Listens to [stream] on the browser client and invokes the latest callbacks.
///
/// Returns the active subscription, or `null` when [stream] is null. A non-null
/// stream during server rendering throws a [StateError].
StreamSubscription<T>? useOnStreamChange<T>(
  Stream<T>? stream, {
  void Function(T event)? onData,
  void Function(Object error, StackTrace stackTrace)? onError,
  void Function()? onDone,
  bool? cancelOnError,
}) {
  return use(
    _OnStreamChangeHook<T>(
      stream,
      onData: onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    ),
  );
}

class _OnStreamChangeHook<T> extends Hook<StreamSubscription<T>?> {
  const _OnStreamChangeHook(
    this.stream, {
    required this.onData,
    required this.onError,
    required this.onDone,
    required this.cancelOnError,
  });

  final Stream<T>? stream;
  final void Function(T event)? onData;
  final void Function(Object error, StackTrace stackTrace)? onError;
  final void Function()? onDone;
  final bool? cancelOnError;

  @override
  _OnStreamChangeHookState<T> createState() => _OnStreamChangeHookState<T>();
}

class _OnStreamChangeHookState<T> extends HookState<StreamSubscription<T>?, _OnStreamChangeHook<T>> {
  // ignore: cancel_subscriptions, canceled by _unsubscribe/dispose.
  StreamSubscription<T>? _subscription;

  @override
  void initHook() {
    _validateServerSource();
    _subscribe();
  }

  @override
  void didUpdateHook(_OnStreamChangeHook<T> oldHook) {
    _validateServerSource();
    if (oldHook.stream != hook.stream || oldHook.cancelOnError != hook.cancelOnError) {
      _unsubscribe();
      _subscribe();
    }
  }

  void _validateServerSource() {
    if (!context.binding.isClient && hook.stream != null) {
      throw StateError(
        'useOnStreamChange() received a non-null Stream while rendering on the server. '
        'Pass null during server rendering.',
      );
    }
  }

  void _subscribe() {
    final stream = hook.stream;
    if (stream == null || !context.binding.isClient) {
      return;
    }
    _subscription = stream.listen(
      _handleData,
      onError: _handleError,
      onDone: _handleDone,
      cancelOnError: hook.cancelOnError,
    );
  }

  void _handleData(T data) {
    hook.onData?.call(data);
  }

  void _handleError(Object error, StackTrace stackTrace) {
    hook.onError?.call(error, stackTrace);
  }

  void _handleDone() {
    hook.onDone?.call();
  }

  void _unsubscribe() {
    final subscription = _subscription;
    _subscription = null;
    if (subscription != null) {
      unawaited(subscription.cancel());
    }
  }

  @override
  StreamSubscription<T>? build(BuildContext context) => _subscription;

  @override
  void dispose() {
    _unsubscribe();
  }
}
