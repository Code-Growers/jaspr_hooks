// Portions of this file are adapted from flutter_hooks 0.21.3+1.
// Copyright (c) 2018 Remi Rousselet. Licensed under the MIT License.

import 'package:jaspr/jaspr.dart';

import 'framework.dart';

/// Returns [listenable] and rebuilds when it notifies on the browser client.
///
/// No listener is attached during server rendering.
T useListenable<T extends Listenable?>(T listenable) {
  use(_ListenableHook(listenable));
  return listenable;
}

class _ListenableHook extends Hook<void> {
  const _ListenableHook(this.listenable);

  final Listenable? listenable;

  @override
  _ListenableHookState createState() => _ListenableHookState();
}

class _ListenableHookState extends HookState<void, _ListenableHook> {
  bool get _canListen => context.binding.isClient;

  @override
  void initHook() {
    if (_canListen) {
      hook.listenable?.addListener(_listener);
    }
  }

  @override
  void didUpdateHook(_ListenableHook oldHook) {
    if (_canListen && hook.listenable != oldHook.listenable) {
      oldHook.listenable?.removeListener(_listener);
      hook.listenable?.addListener(_listener);
    }
  }

  void _listener() {
    setState(() {});
  }

  @override
  void build(BuildContext context) {}

  @override
  void dispose() {
    if (_canListen) {
      hook.listenable?.removeListener(_listener);
    }
  }
}

/// Subscribes to [valueListenable] and returns its current value.
///
/// The value is read during SSR, but live notifications are browser-client
/// only.
T useValueListenable<T>(ValueListenable<T> valueListenable) {
  useListenable(valueListenable);
  return valueListenable.value;
}

/// Rebuilds only when the result of [selector] changes.
///
/// [selector] is evaluated during SSR, but no live listener is attached there.
R useListenableSelector<R>(Listenable? listenable, R Function() selector) {
  return use(_ListenableSelectorHook<R>(listenable, selector));
}

class _ListenableSelectorHook<R> extends Hook<R> {
  const _ListenableSelectorHook(this.listenable, this.selector);

  final Listenable? listenable;
  final R Function() selector;

  @override
  _ListenableSelectorHookState<R> createState() => _ListenableSelectorHookState<R>();
}

class _ListenableSelectorHookState<R> extends HookState<R, _ListenableSelectorHook<R>> {
  late R _selection = hook.selector();

  bool get _canListen => context.binding.isClient;

  @override
  void initHook() {
    if (_canListen) {
      hook.listenable?.addListener(_listener);
    }
  }

  @override
  void didUpdateHook(_ListenableSelectorHook<R> oldHook) {
    if (hook.selector != oldHook.selector) {
      _selection = hook.selector();
    }
    if (_canListen && hook.listenable != oldHook.listenable) {
      oldHook.listenable?.removeListener(_listener);
      hook.listenable?.addListener(_listener);
      _selection = hook.selector();
    }
  }

  void _listener() {
    final nextSelection = hook.selector();
    if (_selection != nextSelection) {
      setState(() => _selection = nextSelection);
    }
  }

  @override
  R build(BuildContext context) => _selection;

  @override
  void dispose() {
    if (_canListen) {
      hook.listenable?.removeListener(_listener);
    }
  }
}

/// Creates a [ValueNotifier] and disposes it when its hook is removed.
///
/// Unlike [useState], this hook does not subscribe its component to the
/// notifier.
ValueNotifier<T> useValueNotifier<T>(T initialData, [List<Object?>? keys]) {
  return use(_ValueNotifierHook<T>(initialData: initialData, keys: keys));
}

class _ValueNotifierHook<T> extends Hook<ValueNotifier<T>> {
  const _ValueNotifierHook({required this.initialData, super.keys});

  final T initialData;

  @override
  _ValueNotifierHookState<T> createState() => _ValueNotifierHookState<T>();
}

class _ValueNotifierHookState<T> extends HookState<ValueNotifier<T>, _ValueNotifierHook<T>> {
  late final ValueNotifier<T> _notifier = ValueNotifier<T>(hook.initialData);

  @override
  ValueNotifier<T> build(BuildContext context) => _notifier;

  @override
  void dispose() {
    _notifier.dispose();
  }
}

/// Invokes [listener] when [listenable] notifies on the browser client.
///
/// The latest callback is used without resubscribing. No listener is attached
/// during server rendering.
void useOnListenableChange(Listenable? listenable, VoidCallback listener) {
  use(_OnListenableChangeHook(listenable, listener));
}

class _OnListenableChangeHook extends Hook<void> {
  const _OnListenableChangeHook(this.listenable, this.listener);

  final Listenable? listenable;
  final VoidCallback listener;

  @override
  _OnListenableChangeHookState createState() => _OnListenableChangeHookState();
}

class _OnListenableChangeHookState extends HookState<void, _OnListenableChangeHook> {
  bool get _canListen => context.binding.isClient;

  @override
  void initHook() {
    if (_canListen) {
      hook.listenable?.addListener(_listener);
    }
  }

  @override
  void didUpdateHook(_OnListenableChangeHook oldHook) {
    if (_canListen && hook.listenable != oldHook.listenable) {
      oldHook.listenable?.removeListener(_listener);
      hook.listenable?.addListener(_listener);
    }
  }

  void _listener() {
    hook.listener();
  }

  @override
  void build(BuildContext context) {}

  @override
  void dispose() {
    if (_canListen) {
      hook.listenable?.removeListener(_listener);
    }
  }
}
