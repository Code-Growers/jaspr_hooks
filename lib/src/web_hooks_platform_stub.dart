import 'package:universal_web/web.dart' as web;

import 'web_hooks_types.dart';

abstract interface class BrowserSubscription {
  void cancel();
}

web.EventTarget? get defaultEventTarget => null;

web.AbortController? createAbortController() => null;

web.Element? readActiveElement() => null;

bool? readFocus(web.Element target, {required bool within}) => null;

BrowserSubscription? watchFocus(void Function(web.Element? value) callback) => null;

void focusElement(web.HTMLElement target, {required bool preventScroll}) {}

void blurElement(web.HTMLElement target) {}

BrowserSubscription? watchAnimationFrames(void Function(Duration timestamp) callback) => null;

HistoryEntry? readHistoryEntry() => null;

BrowserSubscription? watchHistory(void Function(HistoryEntry value) callback) => null;

void pushHistory(Uri uri, Object? state) => throw UnsupportedError('Browser history is unavailable.');

void replaceHistory(Uri uri, Object? state) => throw UnsupportedError('Browser history is unavailable.');

void historyBack() => throw UnsupportedError('Browser history is unavailable.');

void historyForward() => throw UnsupportedError('Browser history is unavailable.');

void historyGo(int delta) => throw UnsupportedError('Browser history is unavailable.');

bool get clipboardSupported => false;

Future<String> readClipboardText() => Future<String>.error(UnsupportedError('Clipboard API is unavailable.'));

Future<void> writeClipboardText(String value) => Future<void>.error(UnsupportedError('Clipboard API is unavailable.'));

BrowserSubscription? watchElementSize(
  web.Element target,
  ResizeObserverBox box,
  void Function(ElementSize value) callback,
) => null;

WindowSize? readWindowSize() => null;

BrowserSubscription? watchWindowSize(
  WindowSizeOptions options,
  void Function(WindowSize value) callback,
) => null;

BrowserSubscription? watchIntersection(
  web.Element target,
  web.Element? root,
  IntersectionOptions options,
  void Function(IntersectionSnapshot value) callback,
) => null;

BrowserSubscription? watchEvent(
  web.EventTarget target,
  String type,
  WebEventListenerOptions options,
  void Function(web.Event event) callback,
) => null;

bool? readHover(web.Element target) => null;

BrowserSubscription? watchHover(web.Element target, void Function(bool value) callback) => null;

bool eventOccurredOutside(web.Event event, Iterable<web.Node> targets) => false;

BrowserSubscription? watchMutations(
  web.Node target,
  MutationObserverOptions options,
  WebMutationCallback callback,
) => null;
