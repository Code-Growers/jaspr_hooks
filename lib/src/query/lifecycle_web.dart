import 'dart:js_interop';

import 'package:web/web.dart' as web;

void Function() watchQueryLifecycle(void Function() focus, void Function() reconnect) {
  final onFocus = ((web.Event _) {
    if (web.document.visibilityState == 'visible') focus();
  }).toJS;
  final onOnline = ((web.Event _) => reconnect()).toJS;
  web.window.addEventListener('focus', onFocus);
  web.document.addEventListener('visibilitychange', onFocus);
  web.window.addEventListener('online', onOnline);
  return () {
    web.window.removeEventListener('focus', onFocus);
    web.document.removeEventListener('visibilitychange', onFocus);
    web.window.removeEventListener('online', onOnline);
  };
}
