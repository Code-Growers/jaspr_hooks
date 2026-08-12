@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:jaspr/jaspr.dart';
import 'package:jaspr_hooks/jaspr_hooks.dart';
import 'package:jaspr_test/client_test.dart';
import 'package:web/web.dart' as web;

import 'support/harness.dart';

void main() {
  testClient('media and motion values synchronize after hydration', (tester) async {
    final media = <MediaQueryMatch>[];
    final motion = <PreferredMotion>[];
    var mediaChanges = 0;
    var motionChanges = 0;

    tester.pumpComponent(
      HookBuilder(
        builder: (context) {
          media.add(useMediaQuery('(min-width: 0px)'));
          motion.add(usePreferredMotion());
          useOnMediaQueryChange('(min-width: 0px)', (previous, current) => mediaChanges++);
          useOnPreferredMotionChange((previous, current) => motionChanges++);
          return const Component.empty();
        },
      ),
    );

    expect(media.first, MediaQueryMatch.unknown);
    expect(motion.first, PreferredMotion.unknown);
    await pumpEventQueue();
    expect(media.last, MediaQueryMatch.matches);
    expect(motion.last, anyOf(PreferredMotion.reduce, PreferredMotion.noPreference));
    expect(mediaChanges, 0);
    expect(motionChanges, 0);
  });

  testClient('media query changes use fresh callbacks and replace listeners', (tester) async {
    final harness = TestHarnessController();
    final first = _FakeMediaQuery(false);
    final second = _FakeMediaQuery(true);
    var matchMediaCalls = 0;
    final restoreMatchMedia = _overrideJsProperty(
      web.window as JSObject,
      'matchMedia',
      ((JSString query) {
        matchMediaCalls++;
        return query.toDart == 'first' ? first.object : second.object;
      }).toJS,
    );
    addTearDown(restoreMatchMedia);
    var query = 'first';
    var callbackVersion = 1;
    final values = <MediaQueryMatch>[];
    final changes = <String>[];

    tester.pumpComponent(
      TestHarness(
        controller: harness,
        builder: () => HookBuilder(
          builder: (context) {
            values.add(useMediaQuery(query));
            useOnMediaQueryChange(query, (previous, current) {
              changes.add('$callbackVersion:$previous->$current');
            });
            return const Component.empty();
          },
        ),
      ),
    );

    await pumpEventQueue();
    expect(values.last, MediaQueryMatch.doesNotMatch);
    expect(first.listeners, hasLength(2));
    expect(matchMediaCalls, 2, reason: 'each hook samples the same media source it subscribed to');

    callbackVersion = 2;
    harness.rebuild();
    await pumpEventQueue();
    expect(first.listeners, hasLength(2));
    expect(matchMediaCalls, 2);
    first.emit(true);
    await pumpEventQueue();
    expect(values.last, MediaQueryMatch.matches);
    expect(
      changes,
      <String>['2:MediaQueryMatch.doesNotMatch->MediaQueryMatch.matches'],
    );

    query = 'second';
    final valuesBeforeSwitch = values.length;
    harness.rebuild();
    await pumpEventQueue();
    expect(
      values.skip(valuesBeforeSwitch),
      contains(MediaQueryMatch.unknown),
    );
    expect(values.last, MediaQueryMatch.matches);
    expect(first.listeners, isEmpty);
    expect(second.listeners, hasLength(2));
    expect(matchMediaCalls, 4);
    expect(changes, hasLength(1));

    harness.unmountChild();
    await pumpEventQueue();
    expect(second.listeners, isEmpty);
  });
}

final class _FakeMediaQuery {
  _FakeMediaQuery(bool matches) {
    object
      ..setProperty('matches'.toJS, matches.toJS)
      ..setProperty(
        'addEventListener'.toJS,
        ((JSString _, JSFunction listener) => listeners.add(listener)).toJS,
      )
      ..setProperty(
        'removeEventListener'.toJS,
        ((JSString _, JSFunction listener) => listeners.remove(listener)).toJS,
      );
  }

  final JSObject object = JSObject();
  final List<JSFunction> listeners = <JSFunction>[];

  void emit(bool matches) {
    object.setProperty('matches'.toJS, matches.toJS);
    for (final listener in listeners.toList(growable: false)) {
      listener.callAsFunction(object, web.Event('change'));
    }
  }
}

@JS('Object.defineProperty')
external JSObject _defineProperty(JSObject target, JSString property, JSObject descriptor);

@JS('Object.getOwnPropertyDescriptor')
external JSObject? _getOwnPropertyDescriptor(JSObject target, JSString property);

VoidCallback _overrideJsProperty(JSObject target, String property, JSAny? value) {
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
