import 'dart:js_interop';

import 'package:web/web.dart' as web;

Future<bool> copyTextToClipboard(String value) async {
  try {
    await web.window.navigator.clipboard.writeText(value).toDart;
    return true;
  } catch (_) {
    return _copyWithTextArea(value);
  }
}

bool _copyWithTextArea(String value) {
  final web.HTMLElement? body = web.document.body;
  if (body == null) return false;

  final web.HTMLTextAreaElement textArea = web.HTMLTextAreaElement()
    ..value = value
    ..setAttribute('readonly', '')
    ..setAttribute('aria-hidden', 'true');
  textArea.style
    ..setProperty('position', 'fixed')
    ..setProperty('inset', '0 auto auto -9999px')
    ..setProperty('opacity', '0');
  body.append(textArea);
  textArea.select();
  try {
    return web.document.execCommand('copy');
  } finally {
    textArea.remove();
  }
}
