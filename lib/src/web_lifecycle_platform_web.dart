import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import 'web_lifecycle_types.dart';

abstract interface class LifecycleSubscription {
  void cancel();
}

final class _EventLifecycleSubscription implements LifecycleSubscription {
  _EventLifecycleSubscription(this._target, this._eventType, this._listener);

  final web.EventTarget _target;
  final String _eventType;
  final web.EventListener _listener;

  @override
  void cancel() {
    _target.removeEventListener(_eventType, _listener);
  }
}

final class _LegacyMediaLifecycleSubscription implements LifecycleSubscription {
  _LegacyMediaLifecycleSubscription(this._media, this._listener);

  final web.MediaQueryList _media;
  final web.EventListener _listener;

  @override
  void cancel() {
    _media.removeListener(_listener);
  }
}

final class _NoopLifecycleSubscription implements LifecycleSubscription {
  const _NoopLifecycleSubscription();

  @override
  void cancel() {}
}

const _noopSubscription = _NoopLifecycleSubscription();

String? get _visibilityProperty {
  final document = web.document as JSObject;
  for (final property in const <String>['hidden', 'webkitHidden', 'mozHidden', 'msHidden']) {
    if (_readBooleanProperty(document, property) != null) return property;
  }
  return null;
}

String? _visibilityEvent(String property) {
  return switch (property) {
    'hidden' => 'visibilitychange',
    'webkitHidden' => 'webkitvisibilitychange',
    'mozHidden' => 'mozvisibilitychange',
    'msHidden' => 'msvisibilitychange',
    _ => null,
  };
}

bool? _readBooleanProperty(JSObject object, String property) {
  final value = object.getProperty<JSAny?>(property.toJS);
  return value != null && value.isA<JSBoolean>() ? (value as JSBoolean).toDart : null;
}

bool _hasFunction(JSObject object, String property) {
  final value = object.getProperty<JSAny?>(property.toJS);
  return value != null && value.typeofEquals('function');
}

DocumentVisibility readDocumentVisibility() {
  final property = _visibilityProperty;
  if (property == null) return DocumentVisibility.unknown;
  final hidden = _readBooleanProperty(web.document as JSObject, property);
  if (hidden == null) return DocumentVisibility.unknown;
  return hidden ? DocumentVisibility.hidden : DocumentVisibility.visible;
}

LifecycleSubscription watchDocumentVisibility(void Function(DocumentVisibility value) callback) {
  final property = _visibilityProperty;
  final eventType = property == null ? null : _visibilityEvent(property);
  if (eventType == null) return _noopSubscription;
  final listener = ((web.Event _) {
    callback(readDocumentVisibility());
  }).toJS;
  web.document.addEventListener(eventType, listener);
  return _EventLifecycleSubscription(web.document, eventType, listener);
}

PreferredColorScheme readPreferredColorScheme() {
  final media = _preferredColorMediaQuery();
  if (media == null) return PreferredColorScheme.unknown;
  return _readPreferredColorScheme(media);
}

LifecycleSubscription watchPreferredColorScheme(void Function(PreferredColorScheme value) callback) {
  final media = _preferredColorMediaQuery();
  if (media == null) return _noopSubscription;
  final listener = ((web.Event _) {
    callback(_readPreferredColorScheme(media));
  }).toJS;
  final mediaObject = media as JSObject;
  if (_hasFunction(mediaObject, 'addEventListener') && _hasFunction(mediaObject, 'removeEventListener')) {
    media.addEventListener('change', listener);
    return _EventLifecycleSubscription(media, 'change', listener);
  }
  if (_hasFunction(mediaObject, 'addListener') && _hasFunction(mediaObject, 'removeListener')) {
    media.addListener(listener);
    return _LegacyMediaLifecycleSubscription(media, listener);
  }
  return _noopSubscription;
}

web.MediaQueryList? _preferredColorMediaQuery() {
  final window = web.window as JSObject;
  if (!_hasFunction(window, 'matchMedia')) return null;
  try {
    return web.window.matchMedia('(prefers-color-scheme: dark)');
  } catch (_) {
    return null;
  }
}

PreferredColorScheme _readPreferredColorScheme(web.MediaQueryList media) {
  final matches = _readBooleanProperty(media as JSObject, 'matches');
  if (matches == null) return PreferredColorScheme.unknown;
  return matches ? PreferredColorScheme.dark : PreferredColorScheme.light;
}
