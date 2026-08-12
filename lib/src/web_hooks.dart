/// Browser DOM hooks for Jaspr components.
library;

import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

import 'framework.dart';
import 'primitives.dart';
import 'web_hooks_platform_stub.dart' if (dart.library.js_interop) 'web_hooks_platform_web.dart' as platform;
import 'web_hooks_types.dart';

export 'web_hooks_types.dart';

/// Creates a stable Jaspr key that exposes its rendered browser node.
GlobalNodeKey<T> useNodeKey<T extends web.Node>({String? debugLabel}) {
  return useMemoized(() => GlobalNodeKey<T>(debugLabel: debugLabel));
}

/// Returns the latest size of [target], or null before browser attachment.
ElementSize? useElementSize(
  GlobalNodeKey<web.Element> target, {
  ResizeObserverBox box = ResizeObserverBox.contentBox,
}) {
  return use(_ElementSizeHook(target, box));
}

class _ElementSizeHook extends Hook<ElementSize?> {
  const _ElementSizeHook(this.target, this.box);

  final GlobalNodeKey<web.Element> target;
  final ResizeObserverBox box;

  @override
  _ElementSizeHookState createState() => _ElementSizeHookState();
}

class _ElementSizeHookState extends HookState<ElementSize?, _ElementSizeHook> {
  ElementSize? _value;
  web.Element? _node;
  platform.BrowserSubscription? _subscription;
  int _scheduleGeneration = 0;
  int _activeGeneration = 0;

  @override
  void initHook() {
    _scheduleReconciliation();
  }

  @override
  void didUpdateHook(_ElementSizeHook oldHook) {
    if (!identical(hook.target, oldHook.target) || hook.box != oldHook.box) {
      _clear();
    }
    _scheduleReconciliation();
  }

  void _scheduleReconciliation() {
    final scheduleGeneration = ++_scheduleGeneration;
    if (!context.binding.isClient) return;
    context.binding.addPostFrameCallback(() {
      if (!mounted || scheduleGeneration != _scheduleGeneration) return;
      final node = hook.target.currentNode;
      if (identical(node, _node)) return;
      final hadValue = _value != null;
      _clear();
      _node = node;
      if (node == null) {
        if (hadValue) setState(() {});
        return;
      }
      final activeGeneration = ++_activeGeneration;
      _subscription = platform.watchElementSize(node, hook.box, (value) {
        if (!mounted || activeGeneration != _activeGeneration || value == _value) return;
        setState(() => _value = value);
      });
      if (hadValue) setState(() {});
    });
  }

  void _clear() {
    _activeGeneration++;
    _subscription?.cancel();
    _subscription = null;
    _node = null;
    _value = null;
  }

  @override
  ElementSize? build(context) => _value;

  @override
  void dispose() {
    _scheduleGeneration++;
    _clear();
  }
}

/// Returns the browser viewport size, or null during SSR and first hydration.
WindowSize? useWindowSize([WindowSizeOptions options = const WindowSizeOptions()]) {
  final debounce = options.debounce;
  if (debounce != null && debounce.isNegative) {
    throw ArgumentError.value(debounce, 'options.debounce', 'must not be negative');
  }
  return use(_WindowSizeHook(options));
}

class _WindowSizeHook extends Hook<WindowSize?> {
  const _WindowSizeHook(this.options);

  final WindowSizeOptions options;

  @override
  _WindowSizeHookState createState() => _WindowSizeHookState();
}

class _WindowSizeHookState extends HookState<WindowSize?, _WindowSizeHook> {
  WindowSize? _value;
  platform.BrowserSubscription? _subscription;
  int _generation = 0;

  @override
  void initHook() {
    _scheduleAttachment();
  }

  @override
  void didUpdateHook(_WindowSizeHook oldHook) {
    if (hook.options != oldHook.options) {
      _detach();
      _value = null;
      _scheduleAttachment();
    }
  }

  void _scheduleAttachment() {
    final generation = ++_generation;
    if (!context.binding.isClient) return;
    context.binding.addPostFrameCallback(() {
      if (!mounted || generation != _generation) return;
      _subscription = platform.watchWindowSize(hook.options, (value) {
        if (!mounted || generation != _generation || value == _value) return;
        setState(() => _value = value);
      });
      final current = platform.readWindowSize();
      if (current != null && current != _value) {
        setState(() => _value = current);
      }
    });
  }

  void _detach() {
    _generation++;
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  WindowSize? build(context) => _value;

  @override
  void dispose() {
    _detach();
  }
}

/// Returns the latest intersection state for [target].
IntersectionSnapshot? useIntersection(
  GlobalNodeKey<web.Element> target, [
  IntersectionOptions options = const IntersectionOptions(),
]) {
  final snapshot = IntersectionOptions(
    root: options.root,
    rootMargin: options.rootMargin,
    thresholds: List<double>.unmodifiable(options.thresholds),
    freezeOnceVisible: options.freezeOnceVisible,
  );
  if (snapshot.thresholds.isEmpty || snapshot.thresholds.any((value) => !value.isFinite || value < 0 || value > 1)) {
    throw ArgumentError.value(snapshot.thresholds, 'options.thresholds', 'must contain values from zero to one');
  }
  return use(_IntersectionHook(target, snapshot));
}

class _IntersectionHook extends Hook<IntersectionSnapshot?> {
  const _IntersectionHook(this.target, this.options);

  final GlobalNodeKey<web.Element> target;
  final IntersectionOptions options;

  @override
  _IntersectionHookState createState() => _IntersectionHookState();
}

class _IntersectionHookState extends HookState<IntersectionSnapshot?, _IntersectionHook> {
  IntersectionSnapshot? _value;
  web.Element? _node;
  web.Element? _root;
  platform.BrowserSubscription? _subscription;
  int _scheduleGeneration = 0;
  int _activeGeneration = 0;

  @override
  void initHook() {
    _scheduleReconciliation();
  }

  @override
  void didUpdateHook(_IntersectionHook oldHook) {
    if (!identical(hook.target, oldHook.target) || hook.options != oldHook.options) {
      _clear();
    }
    _scheduleReconciliation();
  }

  void _scheduleReconciliation() {
    final scheduleGeneration = ++_scheduleGeneration;
    if (!context.binding.isClient) return;
    context.binding.addPostFrameCallback(() {
      if (!mounted || scheduleGeneration != _scheduleGeneration) return;
      final node = hook.target.currentNode;
      final rootKey = hook.options.root;
      final root = rootKey?.currentNode;
      if (identical(node, _node) && identical(root, _root)) return;
      final hadValue = _value != null;
      _clear();
      _node = node;
      _root = root;
      if (node == null || (rootKey != null && root == null)) {
        if (hadValue) setState(() {});
        return;
      }
      final activeGeneration = ++_activeGeneration;
      try {
        _subscription = platform.watchIntersection(node, root, hook.options, (value) {
          if (!mounted || activeGeneration != _activeGeneration || value == _value) return;
          setState(() => _value = value);
        });
      } catch (error, stackTrace) {
        reportHookError(error, stackTrace);
      }
      if (hadValue) setState(() {});
    });
  }

  void _clear() {
    _activeGeneration++;
    _subscription?.cancel();
    _subscription = null;
    _node = null;
    _root = null;
    _value = null;
  }

  @override
  IntersectionSnapshot? build(context) => _value;

  @override
  void dispose() {
    _scheduleGeneration++;
    _clear();
  }
}

/// Subscribes to a native DOM event after the first browser frame.
///
/// Omitting [target] listens on the browser window. A supplied resolver that
/// returns null leaves the hook detached until a later build resolves a target.
void useEventListener<E extends web.Event>(
  String type,
  void Function(E event) listener, {
  WebEventTargetResolver? target,
  bool enabled = true,
  WebEventListenerOptions options = const WebEventListenerOptions(),
}) {
  if (type.isEmpty) throw ArgumentError.value(type, 'type', 'must not be empty');
  use(_EventListenerHook<E>(type, listener, target, enabled, options));
}

class _EventListenerHook<E extends web.Event> extends Hook<void> {
  const _EventListenerHook(this.type, this.listener, this.target, this.enabled, this.options);

  final String type;
  final void Function(E event) listener;
  final WebEventTargetResolver? target;
  final bool enabled;
  final WebEventListenerOptions options;

  @override
  _EventListenerHookState<E> createState() => _EventListenerHookState<E>();
}

class _EventListenerHookState<E extends web.Event> extends HookState<void, _EventListenerHook<E>> {
  web.EventTarget? _target;
  platform.BrowserSubscription? _subscription;
  int _scheduleGeneration = 0;
  int _activeGeneration = 0;

  @override
  void initHook() {
    _scheduleReconciliation();
  }

  @override
  void didUpdateHook(_EventListenerHook<E> oldHook) {
    if (hook.type != oldHook.type || hook.enabled != oldHook.enabled || hook.options != oldHook.options) {
      _clear();
    }
    _scheduleReconciliation();
  }

  void _scheduleReconciliation() {
    final scheduleGeneration = ++_scheduleGeneration;
    if (!context.binding.isClient) return;
    context.binding.addPostFrameCallback(() {
      if (!mounted || scheduleGeneration != _scheduleGeneration) return;
      web.EventTarget? target;
      if (hook.enabled) {
        try {
          target = hook.target == null ? platform.defaultEventTarget : hook.target!.call();
        } catch (error, stackTrace) {
          reportHookError(error, stackTrace);
        }
      }
      if (identical(target, _target)) return;
      _clear();
      _target = target;
      if (target == null) return;
      final activeGeneration = ++_activeGeneration;
      _subscription = platform.watchEvent(target, hook.type, hook.options, (event) {
        if (!mounted || activeGeneration != _activeGeneration) return;
        try {
          hook.listener(event as E);
        } catch (error, stackTrace) {
          reportHookError(error, stackTrace);
        }
      });
    });
  }

  void _clear() {
    _activeGeneration++;
    _subscription?.cancel();
    _subscription = null;
    _target = null;
  }

  @override
  void build(context) {}

  @override
  void dispose() {
    _scheduleGeneration++;
    _clear();
  }
}

/// Calls [listener] for pointer presses outside [target] and related elements.
void useOnClickOutside(
  GlobalNodeKey<web.Element> target,
  void Function(web.PointerEvent event) listener, {
  List<GlobalNodeKey<web.Element>> additionalTargets = const <GlobalNodeKey<web.Element>>[],
  bool enabled = true,
}) {
  useEventListener<web.PointerEvent>(
    'pointerdown',
    (event) {
      final nodes = <web.Node>[
        ?target.currentNode,
        for (final key in additionalTargets) ?key.currentNode,
      ];
      if (platform.eventOccurredOutside(event, nodes)) listener(event);
    },
    enabled: enabled,
    options: const WebEventListenerOptions(capture: true),
  );
}

/// Returns whether the pointer hovers [target], or null before attachment.
bool? useHover(GlobalNodeKey<web.Element> target, {bool enabled = true}) {
  return use(_HoverHook(target, enabled));
}

class _HoverHook extends Hook<bool?> {
  const _HoverHook(this.target, this.enabled);

  final GlobalNodeKey<web.Element> target;
  final bool enabled;

  @override
  _HoverHookState createState() => _HoverHookState();
}

class _HoverHookState extends HookState<bool?, _HoverHook> {
  bool? _value;
  web.Element? _node;
  platform.BrowserSubscription? _subscription;
  int _scheduleGeneration = 0;
  int _activeGeneration = 0;

  @override
  void initHook() {
    _scheduleReconciliation();
  }

  @override
  void didUpdateHook(_HoverHook oldHook) {
    if (!identical(hook.target, oldHook.target) || hook.enabled != oldHook.enabled) {
      _clear();
    }
    _scheduleReconciliation();
  }

  void _scheduleReconciliation() {
    final scheduleGeneration = ++_scheduleGeneration;
    if (!context.binding.isClient) return;
    context.binding.addPostFrameCallback(() {
      if (!mounted || scheduleGeneration != _scheduleGeneration) return;
      final node = hook.enabled ? hook.target.currentNode : null;
      if (identical(node, _node)) return;
      final hadValue = _value != null;
      _clear();
      _node = node;
      if (node == null) {
        if (hadValue) setState(() {});
        return;
      }
      final activeGeneration = ++_activeGeneration;
      _subscription = platform.watchHover(node, (value) {
        if (!mounted || activeGeneration != _activeGeneration || value == _value) return;
        setState(() => _value = value);
      });
      final current = platform.readHover(node);
      if (current != null && current != _value) {
        setState(() => _value = current);
      } else if (hadValue) {
        setState(() {});
      }
    });
  }

  void _clear() {
    _activeGeneration++;
    _subscription?.cancel();
    _subscription = null;
    _node = null;
    _value = null;
  }

  @override
  bool? build(context) => _value;

  @override
  void dispose() {
    _scheduleGeneration++;
    _clear();
  }
}

/// Observes DOM mutations beneath [target].
void useMutationObserver(
  GlobalNodeKey<web.Node> target,
  WebMutationCallback callback, {
  MutationObserverOptions options = const MutationObserverOptions(),
}) {
  final snapshot = MutationObserverOptions(
    childList: options.childList,
    attributes: options.attributes,
    characterData: options.characterData,
    subtree: options.subtree,
    attributeOldValue: options.attributeOldValue,
    characterDataOldValue: options.characterDataOldValue,
    attributeFilter: options.attributeFilter == null ? null : List<String>.unmodifiable(options.attributeFilter!),
  );
  if (!snapshot.isValid) {
    throw ArgumentError.value(snapshot, 'options', 'must observe child, attribute, or character-data changes');
  }
  use(_MutationObserverHook(target, callback, snapshot));
}

class _MutationObserverHook extends Hook<void> {
  const _MutationObserverHook(this.target, this.callback, this.options);

  final GlobalNodeKey<web.Node> target;
  final WebMutationCallback callback;
  final MutationObserverOptions options;

  @override
  _MutationObserverHookState createState() => _MutationObserverHookState();
}

class _MutationObserverHookState extends HookState<void, _MutationObserverHook> {
  web.Node? _node;
  platform.BrowserSubscription? _subscription;
  int _scheduleGeneration = 0;
  int _activeGeneration = 0;

  @override
  void initHook() {
    _scheduleReconciliation();
  }

  @override
  void didUpdateHook(_MutationObserverHook oldHook) {
    if (!identical(hook.target, oldHook.target) || hook.options != oldHook.options) {
      _clear();
    }
    _scheduleReconciliation();
  }

  void _scheduleReconciliation() {
    final scheduleGeneration = ++_scheduleGeneration;
    if (!context.binding.isClient) return;
    context.binding.addPostFrameCallback(() {
      if (!mounted || scheduleGeneration != _scheduleGeneration) return;
      final node = hook.target.currentNode;
      if (identical(node, _node)) return;
      _clear();
      _node = node;
      if (node == null) return;
      final activeGeneration = ++_activeGeneration;
      _subscription = platform.watchMutations(node, hook.options, (records) {
        if (!mounted || activeGeneration != _activeGeneration) return;
        try {
          hook.callback(records);
        } catch (error, stackTrace) {
          reportHookError(error, stackTrace);
        }
      });
    });
  }

  void _clear() {
    _activeGeneration++;
    _subscription?.cancel();
    _subscription = null;
    _node = null;
  }

  @override
  void build(context) {}

  @override
  void dispose() {
    _scheduleGeneration++;
    _clear();
  }
}
