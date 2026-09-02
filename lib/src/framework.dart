// This runtime is substantially adapted from flutter_hooks 0.21.3+1.
// Copyright (c) 2018 Remi Rousselet. Licensed under the MIT License.

import 'dart:collection';

import 'package:jaspr/jaspr.dart';

/// Registers [hook] in the currently building hook component and returns its
/// value.
///
/// Hooks must be called unconditionally and in the same order on every build.
/// Calling this function outside [HookComponent], [StatefulHookComponent], or
/// [HookBuilder] throws a [StateError].
R use<R>(Hook<R> hook) {
  final element = _HookElement._currentHookElement;
  if (element == null) {
    throw StateError(
      'Hooks can only be called while a HookComponent, '
      'StatefulHookComponent, or HookBuilder is building.',
    );
  }
  return element._use(hook);
}

/// A stable callable that always invokes the latest handler supplied to
/// [useEvent].
abstract interface class StableEventCallback<T, R> {
  /// Invokes the current event handler with [value].
  R call(T value);
}

/// Returns a stable callback that always invokes the latest [handler].
///
/// Unlike [useCallback], changing [handler] never changes the returned
/// callback's identity. Use a record as [T] when an event carries multiple
/// values.
StableEventCallback<T, R> useEvent<T, R>(R Function(T value) handler) {
  return use(_EventHook<T, R>(handler));
}

class _EventHook<T, R> extends Hook<StableEventCallback<T, R>> {
  const _EventHook(this.handler);

  final R Function(T value) handler;

  @override
  _EventHookState<T, R> createState() => _EventHookState<T, R>();
}

class _EventHookState<T, R> extends HookState<StableEventCallback<T, R>, _EventHook<T, R>>
    implements StableEventCallback<T, R> {
  @override
  R call(T value) => hook.handler(value);

  @override
  StableEventCallback<T, R> build(BuildContext context) => this;
}

/// Returns an HTML id that is stable across rebuilds, server rendering, and
/// hydration when the component tree and hook order match.
String useId({String prefix = 'jh'}) {
  if (prefix.isEmpty) {
    throw ArgumentError.value(prefix, 'prefix', 'must not be empty');
  }
  final element = _HookElement._currentHookElement;
  if (element == null) {
    throw StateError('useId() can only be called while a hook component is building.');
  }
  return use(_IdHook(prefix, element._currentHookIndex));
}

class _IdHook extends Hook<String> {
  _IdHook(this.prefix, this.hookIndex) : super(keys: <Object?>[prefix]);

  final String prefix;
  final int hookIndex;

  @override
  _IdHookState createState() => _IdHookState();
}

class _IdHookState extends HookState<String, _IdHook> {
  String? _value;

  @override
  String build(BuildContext context) {
    return _value ??= _elementPath(context as Element, hook.hookIndex, hook.prefix);
  }
}

String _elementPath(Element element, int hookIndex, String prefix) {
  final indices = <int>[];
  Element? current = element;
  while (current?.parent != null) {
    indices.add(current!.slot.index);
    current = current.parent;
  }
  final path = indices.reversed.join('-');
  return path.isEmpty ? '$prefix-$hookIndex' : '$prefix-$path-$hookIndex';
}

/// Immutable configuration for a reusable piece of lifecycle-aware state.
///
/// A custom hook normally subclasses this class and returns its mutable state
/// from [createState]. Hook calls are identified by their order within the
/// component build.
abstract class Hook<R> {
  /// Creates a hook configuration with optional identity [keys].
  const Hook({this.keys});

  /// Values that determine whether an existing [HookState] is preserved.
  final List<Object?>? keys;

  /// Returns whether the state belonging to [hook1] can be reused for [hook2].
  ///
  /// Besides ordered equality, this treats two `NaN` values as equal and
  /// distinguishes positive zero from negative zero.
  static bool shouldPreserveState(Hook<Object?> hook1, Hook<Object?> hook2) {
    final keys1 = hook1.keys;
    final keys2 = hook2.keys;

    if (keys1 == keys2) {
      return true;
    }
    if (keys1 == null || keys2 == null || keys1.length != keys2.length) {
      return false;
    }

    final iterator1 = keys1.iterator;
    final iterator2 = keys2.iterator;
    while (true) {
      if (!iterator1.moveNext() || !iterator2.moveNext()) {
        return true;
      }

      final value1 = iterator1.current;
      final value2 = iterator2.current;
      if (value1 is num && value2 is num) {
        if (value1.isNaN && value2.isNaN) {
          continue;
        }
        if (value1 == 0 && value2 == 0) {
          if (value1.isNegative != value2.isNegative) {
            return false;
          }
          continue;
        }
      }
      if (value1 != value2) {
        return false;
      }
    }
  }

  /// Creates the mutable state associated with this hook invocation.
  @protected
  HookState<R, Hook<R>> createState();
}

/// Mutable lifecycle state associated with one [Hook] invocation.
///
/// Custom implementations may initialize resources in [initHook], return a
/// value from [build], react to configuration updates in [didUpdateHook], and
/// release resources in [dispose].
abstract class HookState<R, H extends Hook<R>> {
  /// Creates mutable lifecycle state for a custom [Hook].
  HookState();

  _HookElement? _element;
  H? _hook;

  /// The build context of the component that owns this hook.
  @protected
  BuildContext get context {
    final element = _element;
    if (element == null) {
      throw StateError('This HookState is no longer mounted.');
    }
    return element;
  }

  /// The most recent immutable configuration for this state.
  @protected
  H get hook => _hook!;

  /// Whether this state is currently attached to a hook component.
  bool get mounted => _element != null;

  /// Called exactly once after this state is attached to its component.
  @protected
  void initHook() {}

  /// Returns this hook's current value.
  @protected
  R build(BuildContext context);

  /// Called after a preserved state receives a new hook configuration.
  @protected
  void didUpdateHook(covariant H oldHook) {}

  /// Called when the owning element is temporarily removed from the tree.
  void deactivate() {}

  /// Releases resources held by this state.
  @protected
  void dispose() {}

  /// Decides whether an optional rebuild requested by [markMayNeedRebuild]
  /// should proceed.
  bool shouldRebuild() => true;

  /// Requests a rebuild that may be skipped if every requesting hook returns
  /// `false` from [shouldRebuild].
  void markMayNeedRebuild() {
    final element = _element;
    if (element == null) {
      throw StateError('markMayNeedRebuild() called after the hook was disposed.');
    }
    if (element._isOptionalRebuild != false) {
      element
        .._isOptionalRebuild = true
        .._shouldRebuildQueue.add(_Entry<bool Function()>(shouldRebuild))
        ..markNeedsBuild();
    }
  }

  /// Mutates this state and requests an unconditional component rebuild.
  @protected
  void setState(VoidCallback callback) {
    final element = _element;
    if (element == null) {
      throw StateError('setState() called after the hook was disposed.');
    }
    callback();
    element._isOptionalRebuild = false;
    element._requestRebuild();
  }

  /// Reports a lifecycle callback failure through the owning Jaspr binding.
  ///
  /// This is useful for callbacks that must isolate failures and continue with
  /// other cleanup work. Calls after disposal are ignored because there is no
  /// longer an owning element to attribute the failure to.
  @protected
  void reportHookError(Object error, StackTrace stackTrace) {
    final element = _element;
    if (element != null) {
      element.binding.reportBuildError(element, error, stackTrace);
    }
  }
}

final class _Entry<T> extends LinkedListEntry<_Entry<T>> {
  _Entry(this.value);

  T value;
}

/// A stateless Jaspr component whose [build] method may call hooks.
abstract class HookComponent extends StatelessComponent {
  /// Creates a hook component.
  const HookComponent({super.key});

  @override
  Element createElement() => _StatelessHookElement(this);
}

class _StatelessHookElement extends StatelessElement with _HookElement {
  _StatelessHookElement(HookComponent super.component);
}

/// A stateful Jaspr component whose [State.build] method may call hooks.
///
/// This is useful when hooks need to coexist with Jaspr state mixins such as
/// `PreloadStateMixin` or `SyncStateMixin`.
abstract class StatefulHookComponent extends StatefulComponent {
  /// Creates a stateful hook component.
  const StatefulHookComponent({super.key});

  @override
  Element createElement() => _StatefulHookElement(this);
}

class _StatefulHookElement extends StatefulElement with _HookElement {
  _StatefulHookElement(StatefulHookComponent super.component);
}

/// A hook component that delegates its build to [builder].
class HookBuilder extends HookComponent {
  /// Creates a hook builder.
  const HookBuilder({required this.builder, super.key});

  /// Produces the component subtree and may call hooks.
  final Component Function(BuildContext context) builder;

  @override
  Component build(BuildContext context) => builder(context);
}

/// Returns the [BuildContext] of the currently building hook component.
BuildContext useContext() {
  final element = _HookElement._currentHookElement;
  if (element == null) {
    throw StateError('useContext() can only be called while a hook component is building.');
  }
  return element;
}

mixin _HookElement on BuildableElement {
  static _HookElement? _currentHookElement;
  static int _buildDepth = 0;

  final LinkedList<_Entry<HookState<Object?, Hook<Object?>>>> _hooks = LinkedList();
  final LinkedList<_Entry<bool Function()>> _shouldRebuildQueue = LinkedList();
  _Entry<HookState<Object?, Hook<Object?>>>? _currentHookState;
  LinkedList<_Entry<HookState<Object?, Hook<Object?>>>>? _pendingDisposals;
  Element? _cleanupErrorContext;
  bool? _isOptionalRebuild = false;
  Component? _buildCache;
  bool _isInitializingHook = false;
  bool _rebuildDeferred = false;
  bool _isUnmounted = false;
  int _currentHookIndex = 0;

  @override
  void update(covariant Component newComponent) {
    _isOptionalRebuild = false;
    super.update(newComponent);
  }

  @override
  void didChangeDependencies() {
    _isOptionalRebuild = false;
    super.didChangeDependencies();
  }

  @override
  Component build() {
    final mustRebuild = _isOptionalRebuild != true || _shouldRebuildQueue.any((callback) => callback.value());
    _isOptionalRebuild = null;
    _shouldRebuildQueue.clear();

    if (!mustRebuild) {
      final cache = _buildCache;
      if (cache == null) {
        throw StateError('A hook component attempted to reuse an empty build cache.');
      }
      return cache;
    }

    _currentHookState = _hooks.isEmpty ? null : _hooks.first;
    _currentHookIndex = 0;
    final previousElement = _currentHookElement;
    _currentHookElement = this;
    _buildDepth++;
    try {
      _buildCache = super.build();
      return _buildCache!;
    } finally {
      _buildDepth--;
      _isOptionalRebuild = null;
      _removeRemainingHooks();
      _currentHookElement = previousElement;
      _disposePendingHooks();
    }
  }

  /// Jaspr clears an element's dirty flag only after its build returns, so a
  /// rebuild requested while any hook component is building would be dropped
  /// (own element) or rejected (another element). Those requests are replayed
  /// after the frame instead.
  void _requestRebuild() {
    if (_buildDepth == 0 || !binding.isClient) {
      markNeedsBuild();
      return;
    }
    if (_rebuildDeferred) {
      return;
    }
    _rebuildDeferred = true;
    binding.addPostFrameCallback(() {
      _rebuildDeferred = false;
      if (!_isUnmounted) {
        markNeedsBuild();
      }
    });
  }

  R _use<R>(Hook<R> hook) {
    _currentHookIndex++;
    if (_currentHookState == null) {
      _appendHook(hook);
    } else if (hook.runtimeType != _currentHookState!.value.hook.runtimeType) {
      final previousType = _currentHookState!.value.hook.runtimeType;
      _removeRemainingHooks();
      throw StateError(
        'Hook order changed: expected $previousType at this position, '
        'but received ${hook.runtimeType}. Hooks must be called unconditionally '
        'and in the same order on every build.',
      );
    } else if (!identical(hook, _currentHookState!.value.hook)) {
      final previousHook = _currentHookState!.value.hook;
      if (Hook.shouldPreserveState(previousHook, hook)) {
        _currentHookState!.value
          .._hook = hook
          ..didUpdateHook(previousHook);
      } else {
        final previousState = _currentHookState!.value;
        final nextState = _createHookState(hook);
        _pendingDisposals ??= LinkedList();
        _pendingDisposals!.add(_Entry(previousState));
        _currentHookState!.value = nextState;
      }
    }

    final current = _currentHookState!;
    final result = current.value.build(this) as R;
    _currentHookState = current.next;
    return result;
  }

  HookState<R, Hook<R>> _createHookState<R>(Hook<R> hook) {
    _isInitializingHook = true;
    HookState<R, Hook<R>>? state;
    try {
      state = hook.createState()
        .._element = this
        .._hook = hook;
      state.initHook();
      return state;
    } catch (error, stackTrace) {
      if (state != null) {
        try {
          state.dispose();
        } catch (cleanupError, cleanupStackTrace) {
          binding.reportBuildError(this, cleanupError, cleanupStackTrace);
        } finally {
          state
            .._element = null
            .._hook = null;
        }
      }
      Error.throwWithStackTrace(error, stackTrace);
    } finally {
      _isInitializingHook = false;
    }
  }

  void _appendHook<R>(Hook<R> hook) {
    final entry = _Entry<HookState<Object?, Hook<Object?>>>(_createHookState(hook));
    _currentHookState = entry;
    _hooks.add(entry);
  }

  void _removeRemainingHooks() {
    final firstRemaining = _currentHookState;
    if (firstRemaining == null) {
      return;
    }
    _pendingDisposals ??= LinkedList();
    var current = firstRemaining;
    while (true) {
      final next = current.next;
      current.unlink();
      _pendingDisposals!.add(current);
      if (next == null) {
        break;
      }
      current = next;
    }
    _currentHookState = null;
  }

  void _disposePendingHooks() {
    final pending = _pendingDisposals;
    if (pending == null) {
      return;
    }
    for (var entry = pending.isEmpty ? null : pending.last; entry != null; entry = entry.previous) {
      _disposeHook(entry.value);
    }
    _pendingDisposals = null;
  }

  void _disposeHook(HookState<Object?, Hook<Object?>> state) {
    try {
      state.dispose();
    } catch (error, stackTrace) {
      binding.reportBuildError(_cleanupErrorContext ?? this, error, stackTrace);
    } finally {
      state
        .._element = null
        .._hook = null;
    }
  }

  @override
  T? dependOnInheritedComponentOfExactType<T extends InheritedComponent>({Object? aspect}) {
    if (_isInitializingHook) {
      throw StateError(
        'Inherited components cannot be watched inside HookState.initHook(). '
        'Read them from HookState.build() instead.',
      );
    }
    return super.dependOnInheritedComponentOfExactType<T>(aspect: aspect);
  }

  @override
  void deactivate() {
    for (final entry in _hooks) {
      try {
        entry.value.deactivate();
      } catch (error, stackTrace) {
        binding.reportBuildError(this, error, stackTrace);
      }
    }
    super.deactivate();
  }

  @override
  void unmount() {
    _isUnmounted = true;
    final errorContext = _CleanupErrorElement(component);
    Object? unmountError;
    StackTrace? unmountStackTrace;
    try {
      _cleanupErrorContext = errorContext;
      super.unmount();
    } catch (error, stackTrace) {
      unmountError = error;
      unmountStackTrace = stackTrace;
    }
    try {
      if (_hooks.isNotEmpty) {
        for (_Entry<HookState<Object?, Hook<Object?>>>? entry = _hooks.last; entry != null; entry = entry.previous) {
          _disposeHook(entry.value);
        }
        _hooks.clear();
      }
      _disposePendingHooks();
    } finally {
      _cleanupErrorContext = null;
    }
    if (unmountError != null) {
      Error.throwWithStackTrace(unmountError, unmountStackTrace!);
    }
  }
}

class _CleanupErrorElement extends Element {
  _CleanupErrorElement(super.component);

  @override
  bool get debugDoingBuild => false;

  @override
  void performRebuild() {}

  @override
  bool shouldRebuild(Component newComponent) => false;

  @override
  void visitChildren(ElementVisitor visitor) {}
}
