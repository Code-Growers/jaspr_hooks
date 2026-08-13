/// Hooks for browser focus, scheduling, history, cancellation, and clipboard APIs.
library;

import 'dart:async';

import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

import 'framework.dart';
import 'web_hooks_platform_stub.dart' if (dart.library.js_interop) 'web_hooks_platform_web.dart' as platform;
import 'web_hooks_types.dart';

export 'web_hooks_types.dart';

/// An imperative focus handle returned by [useFocus].
abstract interface class FocusController {
  /// Whether the target currently owns document focus, or null before attachment.
  bool? get hasFocus;

  /// Requests focus for the attached target.
  void focus({bool preventScroll = false});

  /// Removes focus from the attached target.
  void blur();
}

/// Tracks and controls focus for [target].
FocusController useFocus(GlobalNodeKey<web.HTMLElement> target, {bool enabled = true}) {
  return use(_FocusHook(target, enabled));
}

class _FocusHook extends Hook<FocusController> {
  const _FocusHook(this.target, this.enabled);

  final GlobalNodeKey<web.HTMLElement> target;
  final bool enabled;

  @override
  _FocusHookState createState() => _FocusHookState();
}

class _FocusHookState extends HookState<FocusController, _FocusHook> implements FocusController {
  web.HTMLElement? _node;
  platform.BrowserSubscription? _subscription;
  bool? _hasFocus;
  int _generation = 0;

  @override
  bool? get hasFocus => _hasFocus;

  @override
  void initHook() => _scheduleAttachment();

  @override
  void didUpdateHook(_FocusHook oldHook) {
    if (!identical(hook.target, oldHook.target) || hook.enabled != oldHook.enabled) {
      _detach();
      _scheduleAttachment();
    }
  }

  void _scheduleAttachment() {
    final generation = ++_generation;
    if (!context.binding.isClient) return;
    context.binding.addPostFrameCallback(() {
      if (!mounted || generation != _generation) return;
      final node = hook.enabled ? hook.target.currentNode : null;
      if (identical(node, _node) && _subscription != null) return;
      _detach(notify: false);
      _node = node;
      if (node == null) {
        if (_hasFocus != null) setState(() => _hasFocus = null);
        return;
      }
      final activeGeneration = ++_generation;
      _hasFocus = platform.readFocus(node, within: false);
      _subscription = platform.watchFocus((_) => _refresh(activeGeneration));
      setState(() {});
    });
  }

  void _refresh(int generation) {
    scheduleMicrotask(() {
      final node = _node;
      if (!mounted || generation != _generation || node == null) return;
      final value = platform.readFocus(node, within: false);
      if (value != _hasFocus) setState(() => _hasFocus = value);
    });
  }

  @override
  void focus({bool preventScroll = false}) {
    final node = _node;
    if (node == null) throw StateError('FocusController.focus() called before target attachment.');
    platform.focusElement(node, preventScroll: preventScroll);
    final value = platform.readFocus(node, within: false);
    if (value != _hasFocus) setState(() => _hasFocus = value);
  }

  @override
  void blur() {
    final node = _node;
    if (node == null) throw StateError('FocusController.blur() called before target attachment.');
    platform.blurElement(node);
    final value = platform.readFocus(node, within: false);
    if (value != _hasFocus) setState(() => _hasFocus = value);
  }

  void _detach({bool notify = true}) {
    _generation++;
    _subscription?.cancel();
    _subscription = null;
    _node = null;
    if (notify) _hasFocus = null;
  }

  @override
  FocusController build(BuildContext context) => this;

  @override
  void dispose() => _detach();
}

/// Returns whether focus is on [target] or one of its descendants.
bool? useFocusWithin(GlobalNodeKey<web.Element> target, {bool enabled = true}) {
  return use(_FocusWithinHook(target, enabled));
}

class _FocusWithinHook extends Hook<bool?> {
  const _FocusWithinHook(this.target, this.enabled);

  final GlobalNodeKey<web.Element> target;
  final bool enabled;

  @override
  _FocusWithinHookState createState() => _FocusWithinHookState();
}

class _FocusWithinHookState extends HookState<bool?, _FocusWithinHook> {
  web.Element? _node;
  platform.BrowserSubscription? _subscription;
  bool? _value;
  int _generation = 0;

  @override
  void initHook() => _scheduleAttachment();

  @override
  void didUpdateHook(_FocusWithinHook oldHook) {
    if (!identical(hook.target, oldHook.target) || hook.enabled != oldHook.enabled) {
      _detach();
      _scheduleAttachment();
    }
  }

  void _scheduleAttachment() {
    final generation = ++_generation;
    if (!context.binding.isClient) return;
    context.binding.addPostFrameCallback(() {
      if (!mounted || generation != _generation) return;
      final node = hook.enabled ? hook.target.currentNode : null;
      if (identical(node, _node) && _subscription != null) return;
      _detach();
      _node = node;
      if (node == null) return;
      final activeGeneration = ++_generation;
      _value = platform.readFocus(node, within: true);
      _subscription = platform.watchFocus((_) => _refresh(activeGeneration));
      setState(() {});
    });
  }

  void _refresh(int generation) {
    scheduleMicrotask(() {
      final node = _node;
      if (!mounted || generation != _generation || node == null) return;
      final value = platform.readFocus(node, within: true);
      if (value != _value) setState(() => _value = value);
    });
  }

  void _detach() {
    _generation++;
    _subscription?.cancel();
    _subscription = null;
    _node = null;
    _value = null;
  }

  @override
  bool? build(BuildContext context) => _value;

  @override
  void dispose() => _detach();
}

/// Returns the document's active element, or null during SSR and first hydration.
web.Element? useActiveElement() => use(const _ActiveElementHook());

class _ActiveElementHook extends Hook<web.Element?> {
  const _ActiveElementHook();

  @override
  _ActiveElementHookState createState() => _ActiveElementHookState();
}

class _ActiveElementHookState extends HookState<web.Element?, _ActiveElementHook> {
  web.Element? _value;
  platform.BrowserSubscription? _subscription;
  int _generation = 0;

  @override
  void initHook() {
    final generation = ++_generation;
    if (!context.binding.isClient) return;
    context.binding.addPostFrameCallback(() {
      if (!mounted || generation != _generation) return;
      _value = platform.readActiveElement();
      _subscription = platform.watchFocus((value) {
        scheduleMicrotask(() {
          if (!mounted || generation != _generation) return;
          final current = platform.readActiveElement();
          if (!identical(current, _value)) setState(() => _value = current);
        });
      });
      setState(() {});
    });
  }

  @override
  web.Element? build(BuildContext context) => _value;

  @override
  void dispose() {
    _generation++;
    _subscription?.cancel();
    _subscription = null;
  }
}

/// Creates a browser AbortController and aborts it when [keys] change or the
/// hook is removed. Returns null during SSR and first hydration.
web.AbortController? useAbortController([List<Object?> keys = const <Object?>[]]) {
  return use(_AbortControllerHook(keys: keys));
}

class _AbortControllerHook extends Hook<web.AbortController?> {
  const _AbortControllerHook({required super.keys});

  @override
  _AbortControllerHookState createState() => _AbortControllerHookState();
}

class _AbortControllerHookState extends HookState<web.AbortController?, _AbortControllerHook> {
  web.AbortController? _controller;
  int _generation = 0;

  @override
  void initHook() {
    final generation = ++_generation;
    if (!context.binding.isClient) return;
    context.binding.addPostFrameCallback(() {
      if (!mounted || generation != _generation) return;
      final controller = platform.createAbortController();
      if (controller != null) setState(() => _controller = controller);
    });
  }

  @override
  web.AbortController? build(BuildContext context) => _controller;

  @override
  void dispose() {
    _generation++;
    _controller?.abort();
    _controller = null;
  }
}

/// Invokes the latest [callback] for every browser animation frame while
/// [enabled]. No frames are scheduled during SSR.
void useAnimationFrame(AnimationFrameCallback callback, {bool enabled = true}) {
  use(_AnimationFrameHook(callback, enabled));
}

class _AnimationFrameHook extends Hook<void> {
  const _AnimationFrameHook(this.callback, this.enabled);

  final AnimationFrameCallback callback;
  final bool enabled;

  @override
  _AnimationFrameHookState createState() => _AnimationFrameHookState();
}

class _AnimationFrameHookState extends HookState<void, _AnimationFrameHook> {
  platform.BrowserSubscription? _subscription;
  int _generation = 0;

  @override
  void initHook() => _schedule();

  @override
  void didUpdateHook(_AnimationFrameHook oldHook) {
    if (hook.enabled != oldHook.enabled) {
      _detach();
      _schedule();
    }
  }

  void _schedule() {
    final generation = ++_generation;
    if (!context.binding.isClient || !hook.enabled) return;
    context.binding.addPostFrameCallback(() {
      if (!mounted || generation != _generation || !hook.enabled) return;
      _subscription = platform.watchAnimationFrames((timestamp) {
        if (!mounted || generation != _generation) return;
        try {
          hook.callback(timestamp);
        } catch (error, stackTrace) {
          reportHookError(error, stackTrace);
        }
      });
    });
  }

  void _detach() {
    _generation++;
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  void build(BuildContext context) {}

  @override
  void dispose() => _detach();
}

/// Observes and controls same-document browser history.
///
/// Returns null during SSR and first hydration.
HistoryController? useHistoryState() => use(const _HistoryHook());

class _HistoryHook extends Hook<HistoryController?> {
  const _HistoryHook();

  @override
  _HistoryHookState createState() => _HistoryHookState();
}

class _HistoryHookState extends HookState<HistoryController?, _HistoryHook> implements HistoryController {
  HistoryEntry? _entry;
  platform.BrowserSubscription? _subscription;
  int _generation = 0;

  @override
  HistoryEntry get entry => _entry ?? (throw StateError('HistoryController is not attached.'));

  void _ensureAttached() {
    if (!mounted || _entry == null) {
      throw StateError('HistoryController is not attached.');
    }
  }

  @override
  void initHook() {
    final generation = ++_generation;
    if (!context.binding.isClient) return;
    context.binding.addPostFrameCallback(() {
      if (!mounted || generation != _generation) return;
      _entry = platform.readHistoryEntry();
      _subscription = platform.watchHistory((entry) {
        if (mounted && generation == _generation && entry != _entry) setState(() => _entry = entry);
      });
      setState(() {});
    });
  }

  void _update(void Function() operation) {
    _ensureAttached();
    operation();
    final next = platform.readHistoryEntry();
    if (next != null && next != _entry) setState(() => _entry = next);
  }

  @override
  void push(Uri uri, {Object? state}) => _update(() => platform.pushHistory(uri, state));

  @override
  void replace(Uri uri, {Object? state}) => _update(() => platform.replaceHistory(uri, state));

  @override
  void back() {
    _ensureAttached();
    platform.historyBack();
  }

  @override
  void forward() {
    _ensureAttached();
    platform.historyForward();
  }

  @override
  void go(int delta) {
    _ensureAttached();
    platform.historyGo(delta);
  }

  @override
  HistoryController? build(BuildContext context) => _entry == null ? null : this;

  @override
  void dispose() {
    _generation++;
    _subscription?.cancel();
    _subscription = null;
    _entry = null;
  }
}

/// Returns a stable controller for plain-text clipboard operations.
ClipboardController useClipboard() => use(const _ClipboardHook());

class _ClipboardHook extends Hook<ClipboardController> {
  const _ClipboardHook();

  @override
  _ClipboardHookState createState() => _ClipboardHookState();
}

class _ClipboardHookState extends HookState<ClipboardController, _ClipboardHook> implements ClipboardController {
  bool _supported = false;
  ClipboardStatus _status = ClipboardStatus.idle;
  String? _text;
  Object? _error;
  int _operation = 0;

  @override
  bool get isSupported => _supported;

  @override
  ClipboardStatus get status => _status;

  @override
  String? get text => _text;

  @override
  Object? get error => _error;

  @override
  void initHook() {
    if (!context.binding.isClient) return;
    context.binding.addPostFrameCallback(() {
      if (!mounted) return;
      final supported = platform.clipboardSupported;
      if (supported != _supported) setState(() => _supported = supported);
    });
  }

  void _ensureSupported() {
    if (!mounted) throw StateError('ClipboardController is not attached.');
    if (!_supported) throw UnsupportedError('Clipboard API is unavailable in this browser context.');
  }

  @override
  Future<String> readText() async {
    _ensureSupported();
    final operation = ++_operation;
    setState(() {
      _status = ClipboardStatus.reading;
      _error = null;
    });
    try {
      final value = await platform.readClipboardText();
      if (mounted && operation == _operation) {
        setState(() {
          _text = value;
          _status = ClipboardStatus.success;
        });
      }
      return value;
    } catch (error) {
      if (mounted && operation == _operation) {
        setState(() {
          _error = error;
          _status = ClipboardStatus.error;
        });
      }
      rethrow;
    }
  }

  @override
  Future<void> writeText(String value) async {
    _ensureSupported();
    final operation = ++_operation;
    setState(() {
      _status = ClipboardStatus.writing;
      _error = null;
    });
    try {
      await platform.writeClipboardText(value);
      if (mounted && operation == _operation) {
        setState(() {
          _text = value;
          _status = ClipboardStatus.success;
        });
      }
    } catch (error) {
      if (mounted && operation == _operation) {
        setState(() {
          _error = error;
          _status = ClipboardStatus.error;
        });
      }
      rethrow;
    }
  }

  @override
  ClipboardController build(BuildContext context) => this;

  @override
  void dispose() {
    _operation++;
    _supported = false;
  }
}
