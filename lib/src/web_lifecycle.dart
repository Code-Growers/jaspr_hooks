/// Browser lifecycle hooks with deterministic SSR hydration defaults.
library;

import 'framework.dart';
import 'web_lifecycle_platform_stub.dart' if (dart.library.js_interop) 'web_lifecycle_platform_web.dart' as platform;
import 'web_lifecycle_types.dart';

export 'web_lifecycle_types.dart';

/// Returns the document visibility state.
///
/// This returns [DocumentVisibility.unknown] during SSR and the first hydration
/// build. It synchronizes with the browser after that frame.
DocumentVisibility useDocumentVisibility() {
  return use(const _DocumentVisibilityHook());
}

class _DocumentVisibilityHook extends Hook<DocumentVisibility> {
  const _DocumentVisibilityHook();

  @override
  _DocumentVisibilityHookState createState() => _DocumentVisibilityHookState();
}

class _DocumentVisibilityHookState extends HookState<DocumentVisibility, _DocumentVisibilityHook> {
  DocumentVisibility _value = DocumentVisibility.unknown;
  platform.LifecycleSubscription? _subscription;
  int _generation = 0;

  @override
  void initHook() {
    final generation = ++_generation;
    if (!context.binding.isClient) {
      return;
    }
    context.binding.addPostFrameCallback(() {
      if (!mounted || generation != _generation) {
        return;
      }
      final current = platform.readDocumentVisibility();
      _subscription = platform.watchDocumentVisibility((value) {
        if (mounted && value != _value) {
          setState(() => _value = value);
        }
      });
      if (current != _value) {
        setState(() => _value = current);
      }
    });
  }

  @override
  DocumentVisibility build(context) => _value;

  @override
  void dispose() {
    _generation++;
    _subscription?.cancel();
    _subscription = null;
  }
}

/// Calls [callback] when document visibility changes after initial browser
/// synchronization.
void useOnDocumentVisibilityChange(DocumentVisibilityCallback callback) {
  use(_OnDocumentVisibilityChangeHook(callback));
}

class _OnDocumentVisibilityChangeHook extends Hook<void> {
  const _OnDocumentVisibilityChangeHook(this.callback);

  final DocumentVisibilityCallback callback;

  @override
  _OnDocumentVisibilityChangeHookState createState() => _OnDocumentVisibilityChangeHookState();
}

class _OnDocumentVisibilityChangeHookState extends HookState<void, _OnDocumentVisibilityChangeHook> {
  platform.LifecycleSubscription? _subscription;
  DocumentVisibility _previous = DocumentVisibility.unknown;
  int _generation = 0;

  @override
  void initHook() {
    final generation = ++_generation;
    if (!context.binding.isClient) {
      return;
    }
    context.binding.addPostFrameCallback(() {
      if (!mounted || generation != _generation) {
        return;
      }
      _previous = platform.readDocumentVisibility();
      _subscription = platform.watchDocumentVisibility((current) {
        final previous = _previous;
        _previous = current;
        if (current != previous) {
          hook.callback(previous, current);
        }
      });
    });
  }

  @override
  void build(context) {}

  @override
  void dispose() {
    _generation++;
    _subscription?.cancel();
    _subscription = null;
  }
}

/// Returns the browser's preferred color scheme.
///
/// This returns [PreferredColorScheme.unknown] during SSR and the first
/// hydration build, then synchronizes after the first client frame.
PreferredColorScheme usePreferredColorScheme() {
  return use(const _PreferredColorSchemeHook());
}

class _PreferredColorSchemeHook extends Hook<PreferredColorScheme> {
  const _PreferredColorSchemeHook();

  @override
  _PreferredColorSchemeHookState createState() => _PreferredColorSchemeHookState();
}

class _PreferredColorSchemeHookState extends HookState<PreferredColorScheme, _PreferredColorSchemeHook> {
  PreferredColorScheme _value = PreferredColorScheme.unknown;
  platform.LifecycleSubscription? _subscription;
  int _generation = 0;

  @override
  void initHook() {
    final generation = ++_generation;
    if (!context.binding.isClient) {
      return;
    }
    context.binding.addPostFrameCallback(() {
      if (!mounted || generation != _generation) {
        return;
      }
      final current = platform.readPreferredColorScheme();
      _subscription = platform.watchPreferredColorScheme((value) {
        if (mounted && value != _value) {
          setState(() => _value = value);
        }
      });
      if (current != _value) {
        setState(() => _value = current);
      }
    });
  }

  @override
  PreferredColorScheme build(context) => _value;

  @override
  void dispose() {
    _generation++;
    _subscription?.cancel();
    _subscription = null;
  }
}

/// Calls [callback] when the preferred scheme changes after initial browser
/// synchronization.
void useOnPreferredColorSchemeChange(PreferredColorSchemeCallback callback) {
  use(_OnPreferredColorSchemeChangeHook(callback));
}

class _OnPreferredColorSchemeChangeHook extends Hook<void> {
  const _OnPreferredColorSchemeChangeHook(this.callback);

  final PreferredColorSchemeCallback callback;

  @override
  _OnPreferredColorSchemeChangeHookState createState() => _OnPreferredColorSchemeChangeHookState();
}

class _OnPreferredColorSchemeChangeHookState extends HookState<void, _OnPreferredColorSchemeChangeHook> {
  platform.LifecycleSubscription? _subscription;
  PreferredColorScheme _previous = PreferredColorScheme.unknown;
  int _generation = 0;

  @override
  void initHook() {
    final generation = ++_generation;
    if (!context.binding.isClient) {
      return;
    }
    context.binding.addPostFrameCallback(() {
      if (!mounted || generation != _generation) {
        return;
      }
      _previous = platform.readPreferredColorScheme();
      _subscription = platform.watchPreferredColorScheme((current) {
        final previous = _previous;
        _previous = current;
        if (current != previous) {
          hook.callback(previous, current);
        }
      });
    });
  }

  @override
  void build(context) {}

  @override
  void dispose() {
    _generation++;
    _subscription?.cancel();
    _subscription = null;
  }
}
