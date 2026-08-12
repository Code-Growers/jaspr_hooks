import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:universal_web/web.dart' as web;

import 'web_hooks_types.dart';

abstract interface class BrowserSubscription {
  void cancel();
}

final class _CallbackSubscription implements BrowserSubscription {
  _CallbackSubscription(this._cancel);

  final void Function() _cancel;
  bool _cancelled = false;

  @override
  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    _cancel();
  }
}

web.EventTarget get defaultEventTarget => web.window;

BrowserSubscription? watchElementSize(
  web.Element target,
  ResizeObserverBox box,
  void Function(ElementSize value) callback,
) {
  if (!_hasFunction(globalContext, 'ResizeObserver')) return null;
  web.ResizeObserver? observer;
  try {
    observer = web.ResizeObserver(
      ((JSArray<web.ResizeObserverEntry> entries, web.ResizeObserver _) {
        for (final entry in entries.toDart) {
          if (entry.target == target) {
            final value = _readElementSize(entry, box);
            if (value != null) callback(value);
          }
        }
      }).toJS,
    );
    observer.observe(target, web.ResizeObserverOptions(box: _resizeBoxName(box)));
  } catch (_) {
    observer?.disconnect();
    return null;
  }
  return _CallbackSubscription(() => observer?.disconnect());
}

ElementSize? _readElementSize(web.ResizeObserverEntry entry, ResizeObserverBox box) {
  try {
    final sizes = switch (box) {
      ResizeObserverBox.contentBox => entry.contentBoxSize.toDart,
      ResizeObserverBox.borderBox => entry.borderBoxSize.toDart,
      ResizeObserverBox.devicePixelContentBox => entry.devicePixelContentBoxSize.toDart,
    };
    if (sizes.isNotEmpty) {
      final size = sizes.first;
      return _usesVerticalWritingMode(entry.target)
          ? ElementSize(size.blockSize, size.inlineSize)
          : ElementSize(size.inlineSize, size.blockSize);
    }
  } catch (_) {
    if (box == ResizeObserverBox.devicePixelContentBox) return null;
  }
  if (box == ResizeObserverBox.contentBox) {
    return ElementSize(entry.contentRect.width, entry.contentRect.height);
  }
  final rect = entry.target.getBoundingClientRect();
  return ElementSize(rect.width, rect.height);
}

bool _usesVerticalWritingMode(web.Element target) {
  try {
    final writingMode = web.window.getComputedStyle(target).writingMode;
    return writingMode.startsWith('vertical-') || writingMode.startsWith('sideways-');
  } catch (_) {
    return false;
  }
}

String _resizeBoxName(ResizeObserverBox box) {
  return switch (box) {
    ResizeObserverBox.contentBox => 'content-box',
    ResizeObserverBox.borderBox => 'border-box',
    ResizeObserverBox.devicePixelContentBox => 'device-pixel-content-box',
  };
}

WindowSize readWindowSize() => WindowSize(web.window.innerWidth.toDouble(), web.window.innerHeight.toDouble());

BrowserSubscription watchWindowSize(
  WindowSizeOptions options,
  void Function(WindowSize value) callback,
) {
  Timer? timer;
  final listener = ((web.Event _) {
    final debounce = options.debounce;
    if (debounce == null || debounce == Duration.zero) {
      callback(readWindowSize());
      return;
    }
    timer?.cancel();
    timer = Timer(debounce, () => callback(readWindowSize()));
  }).toJS;
  web.window.addEventListener('resize', listener);
  return _CallbackSubscription(() {
    timer?.cancel();
    web.window.removeEventListener('resize', listener);
  });
}

BrowserSubscription? watchIntersection(
  web.Element target,
  web.Element? root,
  IntersectionOptions options,
  void Function(IntersectionSnapshot value) callback,
) {
  if (!_hasFunction(globalContext, 'IntersectionObserver')) return null;
  web.IntersectionObserver? observer;
  try {
    final threshold = options.thresholds.length == 1
        ? options.thresholds.single.toJS
        : options.thresholds.map((value) => value.toJS).toList().toJS;
    observer = web.IntersectionObserver(
      ((JSArray<web.IntersectionObserverEntry> entries, web.IntersectionObserver _) {
        for (final entry in entries.toDart) {
          if (entry.target != target) continue;
          callback(
            IntersectionSnapshot(
              isIntersecting: entry.isIntersecting,
              ratio: entry.intersectionRatio,
            ),
          );
          if (entry.isIntersecting && options.freezeOnceVisible) {
            observer?.disconnect();
          }
        }
      }).toJS,
      web.IntersectionObserverInit(
        root: root,
        rootMargin: options.rootMargin,
        threshold: threshold,
      ),
    );
    observer.observe(target);
  } catch (_) {
    observer?.disconnect();
    rethrow;
  }
  return _CallbackSubscription(() => observer?.disconnect());
}

BrowserSubscription? watchEvent(
  web.EventTarget target,
  String type,
  WebEventListenerOptions options,
  void Function(web.Event event) callback,
) {
  final listener = ((web.Event event) => callback(event)).toJS;
  try {
    target.addEventListener(
      type,
      listener,
      web.AddEventListenerOptions(
        capture: options.capture,
        passive: options.passive,
        once: options.once,
      ),
    );
  } catch (_) {
    return null;
  }
  return _CallbackSubscription(() {
    target.removeEventListener(type, listener, web.EventListenerOptions(capture: options.capture));
  });
}

bool? readHover(web.Element target) {
  try {
    return target.matches(':hover');
  } catch (_) {
    return null;
  }
}

BrowserSubscription? watchHover(web.Element target, void Function(bool value) callback) {
  final enter = ((web.Event _) => callback(true)).toJS;
  final leave = ((web.Event _) => callback(false)).toJS;
  var enteredAttached = false;
  var leaveAttached = false;
  try {
    target.addEventListener('pointerenter', enter);
    enteredAttached = true;
    target.addEventListener('pointerleave', leave);
    leaveAttached = true;
  } catch (_) {
    if (enteredAttached) {
      try {
        target.removeEventListener('pointerenter', enter);
      } catch (_) {}
    }
    if (leaveAttached) {
      try {
        target.removeEventListener('pointerleave', leave);
      } catch (_) {}
    }
    return null;
  }
  return _CallbackSubscription(() {
    target
      ..removeEventListener('pointerenter', enter)
      ..removeEventListener('pointerleave', leave);
  });
}

bool eventOccurredOutside(web.Event event, Iterable<web.Node> targets) {
  final nodes = targets.toList(growable: false);
  if (nodes.isEmpty) return false;
  final path = event.composedPath().toDart;
  return nodes.every((node) => !path.any((entry) => entry == node));
}

BrowserSubscription? watchMutations(
  web.Node target,
  MutationObserverOptions options,
  WebMutationCallback callback,
) {
  if (!_hasFunction(globalContext, 'MutationObserver')) return null;
  web.MutationObserver? observer;
  try {
    observer = web.MutationObserver(
      ((JSArray<web.MutationRecord> records, web.MutationObserver _) {
        callback(List<web.MutationRecord>.unmodifiable(records.toDart));
      }).toJS,
    );
    final init = web.MutationObserverInit(
      childList: options.childList,
      attributes: options.attributes || options.attributeOldValue || options.attributeFilter != null,
      characterData: options.characterData || options.characterDataOldValue,
      subtree: options.subtree,
      attributeOldValue: options.attributeOldValue,
      characterDataOldValue: options.characterDataOldValue,
    );
    final attributeFilter = options.attributeFilter;
    if (attributeFilter != null) {
      init.attributeFilter = attributeFilter.map((value) => value.toJS).toList().toJS;
    }
    observer.observe(target, init);
  } catch (_) {
    observer?.disconnect();
    return null;
  }
  return _CallbackSubscription(() => observer?.disconnect());
}

bool _hasFunction(JSObject object, String property) {
  final value = object.getProperty<JSAny?>(property.toJS);
  return value != null && value.typeofEquals('function');
}
