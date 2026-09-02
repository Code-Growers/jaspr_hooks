// Portions of this file are adapted from flutter_hooks 0.21.3+1.
// Copyright (c) 2018 Remi Rousselet. Licensed under the MIT License.

import 'package:jaspr/jaspr.dart';

import 'framework.dart';

/// A mutable reference whose value survives component rebuilds.
class ObjectRef<T> {
  /// Creates a reference holding [value].
  ObjectRef(this.value);

  /// The current value. Assigning it does not request a rebuild.
  T value;
}

/// Preserves a mutable [ObjectRef] across builds.
ObjectRef<T> useRef<T>(T initialValue) => useMemoized(() => ObjectRef<T>(initialValue));

/// Preserves [callback] until one of [keys] changes.
T useCallback<T extends Function>(T callback, [List<Object?> keys = const <Object>[]]) {
  return useMemoized(() => callback, keys);
}

/// Evaluates [valueBuilder] once and caches its value until [keys] change.
T useMemoized<T>(T Function() valueBuilder, [List<Object?> keys = const <Object>[]]) {
  return use(_MemoizedHook<T>(valueBuilder, keys: keys));
}

class _MemoizedHook<T> extends Hook<T> {
  const _MemoizedHook(this.valueBuilder, {required List<Object?> keys}) : super(keys: keys);

  final T Function() valueBuilder;

  @override
  _MemoizedHookState<T> createState() => _MemoizedHookState<T>();
}

class _MemoizedHookState<T> extends HookState<T, _MemoizedHook<T>> {
  late final T value = hook.valueBuilder();

  @override
  T build(BuildContext context) => value;
}

/// Calls [valueChange] when [value] changes and returns its latest result.
///
/// The callback is not invoked for the first build.
R? useValueChanged<T, R>(T value, R? Function(T oldValue, R? oldResult) valueChange) {
  return use(_ValueChangedHook<T, R>(value, valueChange));
}

class _ValueChangedHook<T, R> extends Hook<R?> {
  const _ValueChangedHook(this.value, this.valueChanged);

  final T value;
  final R? Function(T oldValue, R? oldResult) valueChanged;

  @override
  _ValueChangedHookState<T, R> createState() => _ValueChangedHookState<T, R>();
}

class _ValueChangedHookState<T, R> extends HookState<R?, _ValueChangedHook<T, R>> {
  R? _result;

  @override
  void didUpdateHook(_ValueChangedHook<T, R> oldHook) {
    if (hook.value != oldHook.value) {
      _result = hook.valueChanged(oldHook.value, _result);
    }
  }

  @override
  R? build(BuildContext context) => _result;
}

/// A cleanup function returned by an effect.
typedef Dispose = void Function();

/// Runs a synchronous browser-client side effect.
///
/// Effects are skipped during server and static rendering. With omitted
/// [keys], the previous cleanup runs and the effect reruns on every client
/// build. With keys, it reruns only when their ordered contents change.
void useEffect(Dispose? Function() effect, [List<Object?>? keys]) {
  use(_EffectHook(effect, keys));
}

class _EffectHook extends Hook<void> {
  const _EffectHook(this.effect, [List<Object?>? keys]) : super(keys: keys);

  final Dispose? Function() effect;

  @override
  _EffectHookState createState() => _EffectHookState();
}

class _EffectHookState extends HookState<void, _EffectHook> {
  Dispose? _disposer;

  @override
  void initHook() {
    if (context.binding.isClient) {
      _runEffect();
    }
  }

  @override
  void didUpdateHook(_EffectHook oldHook) {
    if (hook.keys == null && context.binding.isClient) {
      _runCleanupSafely();
      _runEffect();
    }
  }

  void _runEffect() {
    _disposer = hook.effect();
  }

  void _runCleanupSafely() {
    final disposer = _disposer;
    _disposer = null;
    if (disposer == null) {
      return;
    }
    try {
      disposer();
    } catch (error, stackTrace) {
      reportHookError(error, stackTrace);
    }
  }

  @override
  void build(BuildContext context) {}

  @override
  void dispose() {
    _disposer?.call();
    _disposer = null;
  }
}

/// Runs [effect] after the next completed browser-client frame.
///
/// The scheduled callback is invalidated when this hook is disposed or its
/// keys change before execution. This hook never runs on the server.
void usePostFrameEffect(Dispose? Function() effect, [List<Object?>? keys]) {
  use(_PostFrameEffectHook(effect, keys));
}

class _PostFrameEffectHook extends Hook<void> {
  const _PostFrameEffectHook(this.effect, this.effectKeys);

  final Dispose? Function() effect;
  final List<Object?>? effectKeys;

  @override
  _PostFrameEffectHookState createState() => _PostFrameEffectHookState();
}

class _PostFrameEffectHookState extends HookState<void, _PostFrameEffectHook> {
  Dispose? _disposer;
  int _generation = 0;

  @override
  void initHook() {
    _schedule();
  }

  @override
  void didUpdateHook(_PostFrameEffectHook oldHook) {
    if (hook.effectKeys == null || !_keysMatch(oldHook.effectKeys, hook.effectKeys)) {
      _schedule();
    }
  }

  void _schedule() {
    final generation = ++_generation;
    if (!context.binding.isClient) {
      return;
    }
    context.binding.addPostFrameCallback(() {
      if (!mounted || generation != _generation) {
        return;
      }
      _runCleanupSafely();
      try {
        _disposer = hook.effect();
      } catch (error, stackTrace) {
        reportHookError(error, stackTrace);
      }
    });
  }

  @override
  void build(BuildContext context) {}

  @override
  void dispose() {
    _generation++;
    _disposer?.call();
    _disposer = null;
  }

  void _runCleanupSafely() {
    final disposer = _disposer;
    _disposer = null;
    if (disposer == null) {
      return;
    }
    try {
      disposer();
    } catch (error, stackTrace) {
      reportHookError(error, stackTrace);
    }
  }
}

bool _keysMatch(List<Object?>? keys1, List<Object?>? keys2) {
  return Hook.shouldPreserveState(
    _ComparisonHook(keys: keys1),
    _ComparisonHook(keys: keys2),
  );
}

class _ComparisonHook extends Hook<Object?> {
  const _ComparisonHook({super.keys});

  @override
  HookState<Object?, Hook<Object?>> createState() => throw UnsupportedError('Comparison-only hook');
}

/// Creates a [ValueNotifier] that rebuilds its owning component when changed.
ValueNotifier<T> useState<T>(T initialData) => use(_StateHook<T>(initialData));

class _StateHook<T> extends Hook<ValueNotifier<T>> {
  const _StateHook(this.initialData);

  final T initialData;

  @override
  _StateHookState<T> createState() => _StateHookState<T>();
}

class _StateHookState<T> extends HookState<ValueNotifier<T>, _StateHook<T>> {
  late final ValueNotifier<T> _notifier = ValueNotifier<T>(hook.initialData)..addListener(_listener);

  void _listener() {
    setState(() {});
  }

  @override
  ValueNotifier<T> build(BuildContext context) => _notifier;

  @override
  void dispose() {
    _notifier.dispose();
  }
}

/// A [ValueNotifier] that ignores assignments after it has been disposed.
class GuardedValueNotifier<T> extends ValueNotifier<T> {
  /// Creates a guarded notifier holding [value].
  GuardedValueNotifier(super.value);

  bool _isDisposed = false;

  /// Whether [dispose] has run; later assignments are dropped.
  bool get isDisposed => _isDisposed;

  @override
  set value(T newValue) {
    if (_isDisposed) {
      return;
    }
    super.value = newValue;
  }

  @override
  void dispose() {
    if (_isDisposed) {
      return;
    }
    _isDisposed = true;
    super.dispose();
  }
}

/// Creates a [GuardedValueNotifier] that rebuilds its owning component when
/// changed and silently drops assignments made after the component unmounts.
///
/// Use it for state written after an `await`, a timer, or a browser callback,
/// where the owning component may already be gone. Unlike [useState], late
/// writes neither throw nor need an `IsMounted` check.
GuardedValueNotifier<T> useGuardedState<T>(T initialData) => use(_GuardedStateHook<T>(initialData));

class _GuardedStateHook<T> extends Hook<GuardedValueNotifier<T>> {
  const _GuardedStateHook(this.initialData);

  final T initialData;

  @override
  _GuardedStateHookState<T> createState() => _GuardedStateHookState<T>();
}

class _GuardedStateHookState<T> extends HookState<GuardedValueNotifier<T>, _GuardedStateHook<T>> {
  late final GuardedValueNotifier<T> _notifier = GuardedValueNotifier<T>(hook.initialData)..addListener(_listener);

  void _listener() {
    setState(() {});
  }

  @override
  GuardedValueNotifier<T> build(BuildContext context) => _notifier;

  @override
  void dispose() {
    _notifier.dispose();
  }
}
