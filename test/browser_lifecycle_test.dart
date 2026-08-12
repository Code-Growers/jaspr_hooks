@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:jaspr/jaspr.dart';
import 'package:jaspr_hooks/jaspr_hooks.dart';
import 'package:jaspr_hooks/src/web_lifecycle_platform_web.dart' as platform;
import 'package:jaspr_test/client_test.dart';
import 'package:web/web.dart' as web;

import 'support/harness.dart';

void main() {
  testClient('document visibility synchronizes after the first frame', (
    tester,
  ) async {
    final history = <DocumentVisibility>[];
    var changes = 0;

    tester.pumpComponent(
      HookBuilder(
        builder: (context) {
          history.add(useDocumentVisibility());
          useOnDocumentVisibilityChange((previous, current) => changes++);
          return const Component.empty();
        },
      ),
    );

    expect(history.first, DocumentVisibility.unknown);
    await pumpEventQueue();
    expect(history.last, isNot(DocumentVisibility.unknown));
    expect(
      history.last,
      anyOf(DocumentVisibility.visible, DocumentVisibility.hidden),
    );
    expect(changes, 0, reason: 'initial browser synchronization is not a change');
  });

  testClient('preferred color scheme synchronizes after the first frame', (
    tester,
  ) async {
    final history = <PreferredColorScheme>[];
    var changes = 0;

    tester.pumpComponent(
      HookBuilder(
        builder: (context) {
          history.add(usePreferredColorScheme());
          useOnPreferredColorSchemeChange((previous, current) => changes++);
          return const Component.empty();
        },
      ),
    );

    expect(history.first, PreferredColorScheme.unknown);
    await pumpEventQueue();
    expect(history.last, isNot(PreferredColorScheme.unknown));
    expect(
      history.last,
      anyOf(PreferredColorScheme.light, PreferredColorScheme.dark),
    );
    expect(changes, 0, reason: 'initial browser synchronization is not a change');
  });

  testClient('browser lifecycle hooks dispose safely before later events', (
    tester,
  ) async {
    final harness = TestHarnessController();
    var visibilityChanges = 0;
    var colorChanges = 0;

    tester.pumpComponent(
      TestHarness(
        controller: harness,
        builder: () => HookBuilder(
          builder: (context) {
            useDocumentVisibility();
            usePreferredColorScheme();
            useOnDocumentVisibilityChange(
              (previous, current) => visibilityChanges++,
            );
            useOnPreferredColorSchemeChange(
              (previous, current) => colorChanges++,
            );
            return const Component.empty();
          },
        ),
      ),
    );

    await pumpEventQueue();
    harness.unmountChild();
    await pumpEventQueue();

    expect(visibilityChanges, 0);
    expect(colorChanges, 0);
  });

  test('visibility uses a valid vendor property and its matching event', () {
    final document = web.document as JSObject;
    final restoreHidden = _overrideJsProperty(document, 'hidden', null);
    final restoreWebkitHidden = _overrideJsProperty(
      document,
      'webkitHidden',
      false.toJS,
    );
    final changes = <DocumentVisibility>[];
    final subscription = platform.watchDocumentVisibility(changes.add);

    try {
      expect(
        platform.readDocumentVisibility(),
        DocumentVisibility.visible,
      );

      document.setProperty('webkitHidden'.toJS, true.toJS);
      web.document.dispatchEvent(web.Event('visibilitychange'));
      expect(changes, isEmpty, reason: 'the invalid standard property is not watched');

      web.document.dispatchEvent(web.Event('webkitvisibilitychange'));
      expect(changes, <DocumentVisibility>[DocumentVisibility.hidden]);
    } finally {
      subscription.cancel();
      restoreWebkitHidden();
      restoreHidden();
    }
  });

  test('missing visibility APIs return unknown with a safe no-op watcher', () {
    final document = web.document as JSObject;
    final restores = <VoidCallback>[
      for (final property in const <String>[
        'hidden',
        'webkitHidden',
        'mozHidden',
        'msHidden',
      ])
        _overrideJsProperty(document, property, null),
    ];

    try {
      expect(
        platform.readDocumentVisibility(),
        DocumentVisibility.unknown,
      );
      final subscription = platform.watchDocumentVisibility((_) {
        fail('an unsupported browser must not register a live callback');
      });
      for (final eventType in const <String>[
        'visibilitychange',
        'webkitvisibilitychange',
        'mozvisibilitychange',
        'msvisibilitychange',
      ]) {
        web.document.dispatchEvent(web.Event(eventType));
      }
      subscription.cancel();
    } finally {
      for (final restore in restores.reversed) {
        restore();
      }
    }
  });

  test('missing matchMedia returns unknown with a safe no-op watcher', () {
    final restoreMatchMedia = _overrideJsProperty(
      web.window as JSObject,
      'matchMedia',
      null,
    );

    try {
      expect(
        platform.readPreferredColorScheme(),
        PreferredColorScheme.unknown,
      );
      final subscription = platform.watchPreferredColorScheme((_) {
        fail('an unsupported browser must not register a live callback');
      });
      subscription.cancel();
    } finally {
      restoreMatchMedia();
    }
  });

  test('preferred color scheme falls back to legacy media listeners', () {
    final media = JSObject();
    final listeners = <JSFunction>[];
    media
      ..setProperty('matches'.toJS, false.toJS)
      ..setProperty(
        'addListener'.toJS,
        ((JSFunction listener) => listeners.add(listener)).toJS,
      )
      ..setProperty(
        'removeListener'.toJS,
        ((JSFunction listener) => listeners.remove(listener)).toJS,
      );
    final restoreMatchMedia = _overrideJsProperty(
      web.window as JSObject,
      'matchMedia',
      ((JSString _) => media).toJS,
    );
    final changes = <PreferredColorScheme>[];

    try {
      expect(
        platform.readPreferredColorScheme(),
        PreferredColorScheme.light,
      );
      final subscription = platform.watchPreferredColorScheme(changes.add);
      expect(listeners, hasLength(1));

      media.setProperty('matches'.toJS, true.toJS);
      listeners.single.callAsFunction(media, web.Event('change'));
      expect(changes, <PreferredColorScheme>[PreferredColorScheme.dark]);

      subscription.cancel();
      expect(listeners, isEmpty);
    } finally {
      restoreMatchMedia();
    }
  });
}

@JS('Object.defineProperty')
external JSObject _defineProperty(
  JSObject target,
  JSString property,
  JSObject descriptor,
);

@JS('Object.getOwnPropertyDescriptor')
external JSObject? _getOwnPropertyDescriptor(
  JSObject target,
  JSString property,
);

VoidCallback _overrideJsProperty(
  JSObject target,
  String property,
  JSAny? value,
) {
  final previous = _getOwnPropertyDescriptor(target, property.toJS);
  final descriptor = JSObject()
    ..setProperty('configurable'.toJS, true.toJS)
    ..setProperty('writable'.toJS, true.toJS)
    ..setProperty('value'.toJS, value);
  _defineProperty(target, property.toJS, descriptor);
  return () {
    if (previous == null) {
      target.delete(property.toJS);
    } else {
      _defineProperty(target, property.toJS, previous);
    }
  };
}
