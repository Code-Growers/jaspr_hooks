import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:universal_web/web.dart' as web;

import 'web_lifecycle_types.dart';

abstract interface class LifecycleSubscription {
  void cancel();
}

final class LifecycleObservation<T> {
  const LifecycleObservation(this.value, this.subscription);

  final T value;
  final LifecycleSubscription? subscription;
}

final class _EventLifecycleSubscription implements LifecycleSubscription {
  _EventLifecycleSubscription(this._target, this._eventType, this._listener);

  final web.EventTarget _target;
  final String _eventType;
  final web.EventListener _listener;
  bool _cancelled = false;

  @override
  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    _target.removeEventListener(_eventType, _listener);
  }
}

final class _LegacyMediaLifecycleSubscription implements LifecycleSubscription {
  _LegacyMediaLifecycleSubscription(this._media, this._listener);

  final web.MediaQueryList _media;
  final web.EventListener _listener;
  bool _cancelled = false;

  @override
  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
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
  return _readDocumentVisibility(property);
}

DocumentVisibility _readDocumentVisibility(String property) {
  final hidden = _readBooleanProperty(web.document as JSObject, property);
  if (hidden == null) return DocumentVisibility.unknown;
  return hidden ? DocumentVisibility.hidden : DocumentVisibility.visible;
}

LifecycleSubscription watchDocumentVisibility(void Function(DocumentVisibility value) callback) {
  return observeDocumentVisibility(callback).subscription ?? _noopSubscription;
}

LifecycleObservation<DocumentVisibility> observeDocumentVisibility(
  void Function(DocumentVisibility value) callback,
) {
  final property = _visibilityProperty;
  final eventType = property == null ? null : _visibilityEvent(property);
  if (eventType == null) {
    return const LifecycleObservation(DocumentVisibility.unknown, _noopSubscription);
  }
  final listener = ((web.Event _) {
    callback(_readDocumentVisibility(property!));
  }).toJS;
  web.document.addEventListener(eventType, listener);
  return LifecycleObservation(
    _readDocumentVisibility(property!),
    _EventLifecycleSubscription(web.document, eventType, listener),
  );
}

PreferredColorScheme readPreferredColorScheme() {
  final media = _preferredColorMediaQuery();
  if (media == null) return PreferredColorScheme.unknown;
  return _readPreferredColorScheme(media);
}

LifecycleSubscription watchPreferredColorScheme(void Function(PreferredColorScheme value) callback) {
  return observePreferredColorScheme(callback).subscription ?? _noopSubscription;
}

LifecycleObservation<PreferredColorScheme> observePreferredColorScheme(
  void Function(PreferredColorScheme value) callback,
) {
  final media = _preferredColorMediaQuery();
  if (media == null) {
    return const LifecycleObservation(PreferredColorScheme.unknown, _noopSubscription);
  }
  final subscription = _watchMedia(media, () => callback(_readPreferredColorScheme(media)));
  return LifecycleObservation(_readPreferredColorScheme(media), subscription);
}

MediaQueryMatch readMediaQuery(String query) {
  final media = _mediaQuery(query);
  if (media == null) return MediaQueryMatch.unknown;
  return _readMediaQuery(media);
}

LifecycleSubscription watchMediaQuery(String query, void Function(MediaQueryMatch value) callback) {
  return observeMediaQuery(query, callback).subscription ?? _noopSubscription;
}

LifecycleObservation<MediaQueryMatch> observeMediaQuery(
  String query,
  void Function(MediaQueryMatch value) callback,
) {
  final media = _mediaQuery(query);
  if (media == null) {
    return const LifecycleObservation(MediaQueryMatch.unknown, _noopSubscription);
  }
  final subscription = _watchMedia(media, () => callback(_readMediaQuery(media)));
  return LifecycleObservation(_readMediaQuery(media), subscription);
}

LifecycleSubscription _watchMedia(web.MediaQueryList media, void Function() callback) {
  final listener = ((web.Event _) => callback()).toJS;
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
  return _mediaQuery('(prefers-color-scheme: dark)');
}

web.MediaQueryList? _mediaQuery(String query) {
  final window = web.window as JSObject;
  if (!_hasFunction(window, 'matchMedia')) return null;
  try {
    return web.window.matchMedia(query);
  } catch (_) {
    return null;
  }
}

PreferredColorScheme _readPreferredColorScheme(web.MediaQueryList media) {
  final matches = _readBooleanProperty(media as JSObject, 'matches');
  if (matches == null) return PreferredColorScheme.unknown;
  return matches ? PreferredColorScheme.dark : PreferredColorScheme.light;
}

MediaQueryMatch _readMediaQuery(web.MediaQueryList media) {
  final matches = _readBooleanProperty(media as JSObject, 'matches');
  if (matches == null) return MediaQueryMatch.unknown;
  return matches ? MediaQueryMatch.matches : MediaQueryMatch.doesNotMatch;
}
