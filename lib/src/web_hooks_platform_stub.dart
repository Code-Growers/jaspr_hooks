import 'package:universal_web/web.dart' as web;

import 'web_hooks_types.dart';

abstract interface class BrowserSubscription {
  void cancel();
}

web.EventTarget? get defaultEventTarget => null;

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
