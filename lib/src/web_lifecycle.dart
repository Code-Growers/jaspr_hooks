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
      final observation = platform.observeDocumentVisibility((value) {
        if (mounted && generation == _generation && value != _value) {
          setState(() => _value = value);
        }
      });
      _subscription = observation.subscription;
      final current = observation.value;
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
      final observation = platform.observeDocumentVisibility((current) {
        if (!mounted || generation != _generation) {
          return;
        }
        final previous = _previous;
        _previous = current;
        if (current != previous) {
          try {
            hook.callback(previous, current);
          } catch (error, stackTrace) {
            reportHookError(error, stackTrace);
          }
        }
      });
      _subscription = observation.subscription;
      _previous = observation.value;
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
      final observation = platform.observePreferredColorScheme((value) {
        if (mounted && generation == _generation && value != _value) {
          setState(() => _value = value);
        }
      });
      _subscription = observation.subscription;
      final current = observation.value;
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
      final observation = platform.observePreferredColorScheme((current) {
        if (!mounted || generation != _generation) {
          return;
        }
        final previous = _previous;
        _previous = current;
        if (current != previous) {
          try {
            hook.callback(previous, current);
          } catch (error, stackTrace) {
            reportHookError(error, stackTrace);
          }
        }
      });
      _subscription = observation.subscription;
      _previous = observation.value;
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

/// Returns whether the document matches [query].
///
/// This returns [MediaQueryMatch.unknown] during SSR and the first hydration
/// build, then synchronizes after the first client frame.
MediaQueryMatch useMediaQuery(String query) {
  return use(_MediaQueryHook(query));
}

class _MediaQueryHook extends Hook<MediaQueryMatch> {
  const _MediaQueryHook(this.query);

  final String query;

  @override
  _MediaQueryHookState createState() => _MediaQueryHookState();
}

class _MediaQueryHookState extends HookState<MediaQueryMatch, _MediaQueryHook> {
  MediaQueryMatch _value = MediaQueryMatch.unknown;
  platform.LifecycleSubscription? _subscription;
  int _generation = 0;

  @override
  void initHook() {
    _scheduleSynchronization();
  }

  @override
  void didUpdateHook(_MediaQueryHook oldHook) {
    if (hook.query != oldHook.query) {
      _subscription?.cancel();
      _subscription = null;
      _value = MediaQueryMatch.unknown;
      _scheduleSynchronization();
    }
  }

  void _scheduleSynchronization() {
    final generation = ++_generation;
    if (!context.binding.isClient) {
      return;
    }
    context.binding.addPostFrameCallback(() {
      if (!mounted || generation != _generation) {
        return;
      }
      final observation = platform.observeMediaQuery(hook.query, (value) {
        if (mounted && generation == _generation && value != _value) {
          setState(() => _value = value);
        }
      });
      _subscription = observation.subscription;
      final current = observation.value;
      if (current != _value) {
        setState(() => _value = current);
      }
    });
  }

  @override
  MediaQueryMatch build(context) => _value;

  @override
  void dispose() {
    _generation++;
    _subscription?.cancel();
    _subscription = null;
  }
}

/// Calls [callback] when [query] changes after initial browser synchronization.
void useOnMediaQueryChange(String query, MediaQueryCallback callback) {
  use(_OnMediaQueryChangeHook(query, callback));
}

class _OnMediaQueryChangeHook extends Hook<void> {
  const _OnMediaQueryChangeHook(this.query, this.callback);

  final String query;
  final MediaQueryCallback callback;

  @override
  _OnMediaQueryChangeHookState createState() => _OnMediaQueryChangeHookState();
}

class _OnMediaQueryChangeHookState extends HookState<void, _OnMediaQueryChangeHook> {
  platform.LifecycleSubscription? _subscription;
  MediaQueryMatch _previous = MediaQueryMatch.unknown;
  int _generation = 0;

  @override
  void initHook() {
    _scheduleSynchronization();
  }

  @override
  void didUpdateHook(_OnMediaQueryChangeHook oldHook) {
    if (hook.query != oldHook.query) {
      _subscription?.cancel();
      _subscription = null;
      _previous = MediaQueryMatch.unknown;
      _scheduleSynchronization();
    }
  }

  void _scheduleSynchronization() {
    final generation = ++_generation;
    if (!context.binding.isClient) {
      return;
    }
    context.binding.addPostFrameCallback(() {
      if (!mounted || generation != _generation) {
        return;
      }
      final observation = platform.observeMediaQuery(hook.query, (current) {
        if (!mounted || generation != _generation) {
          return;
        }
        final previous = _previous;
        _previous = current;
        if (current != previous) {
          try {
            hook.callback(previous, current);
          } catch (error, stackTrace) {
            reportHookError(error, stackTrace);
          }
        }
      });
      _subscription = observation.subscription;
      _previous = observation.value;
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

const _preferredMotionQuery = '(prefers-reduced-motion: reduce)';

/// Returns the browser's preferred animation and transition behavior.
PreferredMotion usePreferredMotion() {
  return switch (useMediaQuery(_preferredMotionQuery)) {
    MediaQueryMatch.unknown => PreferredMotion.unknown,
    MediaQueryMatch.matches => PreferredMotion.reduce,
    MediaQueryMatch.doesNotMatch => PreferredMotion.noPreference,
  };
}

/// Calls [callback] when the browser's preferred motion behavior changes.
void useOnPreferredMotionChange(PreferredMotionCallback callback) {
  useOnMediaQueryChange(_preferredMotionQuery, (previous, current) {
    callback(_preferredMotion(previous), _preferredMotion(current));
  });
}

PreferredMotion _preferredMotion(MediaQueryMatch match) {
  return switch (match) {
    MediaQueryMatch.unknown => PreferredMotion.unknown,
    MediaQueryMatch.matches => PreferredMotion.reduce,
    MediaQueryMatch.doesNotMatch => PreferredMotion.noPreference,
  };
}

/// Returns the current document location.
///
/// This returns `null` during SSR and the first hydration build, then
/// synchronizes after the first client frame. It rebuilds on `popstate`,
/// `hashchange`, `pageshow`, and same-document navigation performed through
/// a `HistoryController`.
Uri? useLocation() => use(const _LocationHook(null));

/// Derives a route value from the browser location.
///
/// This returns [serverRoute] during SSR and the first hydration build. After
/// the first client frame it returns `resolve(location)` and rebuilds whenever
/// the location changes. [onLocationChange] is invoked for every location
/// change after that initial synchronization, outside of a build.
T useBrowserRoute<T>(
  T serverRoute,
  T Function(Uri location) resolve, {
  void Function(Uri location)? onLocationChange,
}) {
  final location = use(_LocationHook(onLocationChange));
  return location == null ? serverRoute : resolve(location);
}

class _LocationHook extends Hook<Uri?> {
  const _LocationHook(this.onChange);

  final void Function(Uri location)? onChange;

  @override
  _LocationHookState createState() => _LocationHookState();
}

class _LocationHookState extends HookState<Uri?, _LocationHook> {
  Uri? _value;
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
      final observation = platform.observeLocation((next) {
        if (!mounted || generation != _generation || next == _value) {
          return;
        }
        final previous = _value;
        setState(() => _value = next);
        if (previous != null && next != null) {
          try {
            hook.onChange?.call(next);
          } catch (error, stackTrace) {
            reportHookError(error, stackTrace);
          }
        }
      });
      _subscription = observation.subscription;
      final current = observation.value;
      if (current != _value) {
        setState(() => _value = current);
      }
    });
  }

  @override
  Uri? build(context) => _value;

  @override
  void dispose() {
    _generation++;
    _subscription?.cancel();
    _subscription = null;
  }
}

/// Calls [callback] when the window regains focus.
///
/// With [includeVisibilityChange], it also fires when the document becomes
/// visible again, which covers returning to a background tab where the
/// browser fires no `focus` event. Both underlying events can fire for one
/// user action. The listener attaches after the first client frame and never
/// runs on the server.
void useOnWindowFocus(void Function() callback, {bool includeVisibilityChange = true}) {
  use(_OnWindowFocusHook(callback, includeVisibilityChange));
}

class _OnWindowFocusHook extends Hook<void> {
  const _OnWindowFocusHook(this.callback, this.includeVisibilityChange);

  final void Function() callback;
  final bool includeVisibilityChange;

  @override
  _OnWindowFocusHookState createState() => _OnWindowFocusHookState();
}

class _OnWindowFocusHookState extends HookState<void, _OnWindowFocusHook> {
  platform.LifecycleSubscription? _subscription;
  int _generation = 0;

  @override
  void initHook() {
    _scheduleSubscription();
  }

  @override
  void didUpdateHook(_OnWindowFocusHook oldHook) {
    if (hook.includeVisibilityChange != oldHook.includeVisibilityChange) {
      _detach();
      _scheduleSubscription();
    }
  }

  void _scheduleSubscription() {
    final generation = ++_generation;
    if (!context.binding.isClient) {
      return;
    }
    context.binding.addPostFrameCallback(() {
      if (!mounted || generation != _generation) {
        return;
      }
      _subscription = platform.watchWindowFocus(
        () {
          if (!mounted || generation != _generation) {
            return;
          }
          try {
            hook.callback();
          } catch (error, stackTrace) {
            reportHookError(error, stackTrace);
          }
        },
        includeVisibilityChange: hook.includeVisibilityChange,
      );
    });
  }

  void _detach() {
    _generation++;
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  void build(context) {}

  @override
  void dispose() => _detach();
}
