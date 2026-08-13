@TestOn('browser')
library;

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_hooks/src/web_hooks_platform_web.dart' as platform;
import 'package:jaspr_hooks/web.dart';
import 'package:jaspr_test/client_test.dart';
import 'package:universal_web/web.dart' as web;

import 'support/harness.dart';

void main() {
  test('missing observer APIs are treated as unsupported', () {
    final restores = <VoidCallback>[
      _overrideJsProperty(globalContext, 'ResizeObserver', null),
      _overrideJsProperty(globalContext, 'IntersectionObserver', null),
      _overrideJsProperty(globalContext, 'MutationObserver', null),
    ];
    final element = web.document.createElement('div');

    try {
      expect(
        platform.watchElementSize(element, ResizeObserverBox.contentBox, (_) {}),
        isNull,
      );
      expect(
        platform.watchIntersection(element, null, const IntersectionOptions(), (_) {}),
        isNull,
      );
      expect(
        platform.watchMutations(element, const MutationObserverOptions(), (_) {}),
        isNull,
      );
    } finally {
      for (final restore in restores.reversed) {
        restore();
      }
    }
  });

  test('cancelled browser subscriptions stay silent', () async {
    final element = web.document.createElement('div');
    web.document.body!.append(element);
    var callbacks = 0;
    final subscriptions = <platform.BrowserSubscription?>[
      platform.watchElementSize(element, ResizeObserverBox.contentBox, (_) => callbacks++),
      platform.watchWindowSize(const WindowSizeOptions(), (_) => callbacks++),
      platform.watchIntersection(element, null, const IntersectionOptions(), (_) => callbacks++),
      platform.watchEvent(element, 'jaspr-hooks-cancelled', const WebEventListenerOptions(), (_) => callbacks++),
      platform.watchHover(element, (_) => callbacks++),
      platform.watchMutations(element, const MutationObserverOptions(), (_) => callbacks++),
    ];

    for (final subscription in subscriptions) {
      subscription?.cancel();
    }
    element
      ..setAttribute('style', 'width: 20px')
      ..append(web.document.createElement('span'))
      ..dispatchEvent(web.Event('jaspr-hooks-cancelled'))
      ..dispatchEvent(web.PointerEvent('pointerenter'));
    web.window.dispatchEvent(web.Event('resize'));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await pumpEventQueue();

    expect(callbacks, 0);
    element.remove();
  });

  test('invalid intersection configuration is surfaced', () {
    final element = web.document.createElement('div');

    expect(
      () => platform.watchIntersection(
        element,
        null,
        const IntersectionOptions(rootMargin: 'invalid'),
        (_) {},
      ),
      throwsA(anything),
    );
  });

  test('hover attachment rolls back when the second listener fails', () {
    final element = web.document.createElement('div');
    JSFunction? enteredListener;
    var removedEnter = false;
    final restoreAdd = _overrideJsProperty(
      element as JSObject,
      'addEventListener',
      ((JSString type, JSFunction listener) {
        if (type.toDart == 'pointerleave') throw StateError('listener rejected');
        enteredListener = listener;
      }).toJS,
    );
    final restoreRemove = _overrideJsProperty(
      element as JSObject,
      'removeEventListener',
      ((JSString type, JSFunction listener) {
        if (type.toDart == 'pointerenter' && listener == enteredListener) {
          removedEnter = true;
        }
      }).toJS,
    );

    try {
      expect(platform.watchHover(element, (_) {}), isNull);
      expect(removedEnter, isTrue);
    } finally {
      restoreRemove();
      restoreAdd();
    }
  });

  testClient('DOM hooks attach after the first frame and clean up', (tester) async {
    GlobalNodeKey<web.HTMLDivElement>? nodeKey;
    final elementSizes = <ElementSize?>[];
    final windowSizes = <WindowSize?>[];
    final intersections = <IntersectionSnapshot?>[];
    final hoverValues = <bool?>[];
    var nativeEvents = 0;
    var outsideEvents = 0;
    var mutations = 0;

    tester.pumpComponent(
      HookBuilder(
        builder: (context) {
          final key = useNodeKey<web.HTMLDivElement>();
          nodeKey = key;
          elementSizes.add(useElementSize(key));
          windowSizes.add(useWindowSize());
          intersections.add(useIntersection(key));
          hoverValues.add(useHover(key));
          useEventListener<web.Event>(
            'jaspr-hooks-test',
            (event) => nativeEvents++,
            target: () => key.currentNode,
          );
          useOnClickOutside(key, (event) => outsideEvents++);
          useMutationObserver(key, (records) => mutations += records.length);
          return div(
            const <Component>[],
            key: key,
            attributes: const <String, String>{
              'style': 'width: 120px; height: 40px; writing-mode: vertical-rl',
            },
          );
        },
      ),
    );

    expect(elementSizes.first, isNull);
    expect(windowSizes.first, isNull);
    expect(intersections.first, isNull);
    expect(hoverValues.first, isNull);
    await pumpEventQueue();

    final node = nodeKey!.currentNode!;
    node.dispatchEvent(web.Event('jaspr-hooks-test'));
    expect(nativeEvents, 1);

    node.dispatchEvent(web.PointerEvent('pointerenter'));
    await pumpEventQueue();
    expect(hoverValues.last, isTrue);

    node.dispatchEvent(web.PointerEvent('pointerdown', web.PointerEventInit(bubbles: true, composed: true)));
    expect(outsideEvents, 0);
    final outside = web.document.createElement('button');
    web.document.body!.append(outside);
    outside.dispatchEvent(web.PointerEvent('pointerdown', web.PointerEventInit(bubbles: true, composed: true)));
    expect(outsideEvents, 1);
    outside.remove();

    node.append(web.document.createElement('span'));
    await pumpEventQueue();
    expect(mutations, greaterThan(0));
    expect(windowSizes.last, isNotNull);

    await Future<void>.delayed(const Duration(milliseconds: 50));
    await pumpEventQueue();
    expect(elementSizes.last, isNotNull);
    expect(elementSizes.last!.width, closeTo(120, 0.5));
    expect(elementSizes.last!.height, closeTo(40, 0.5));
    expect(intersections.last, isNotNull);
  });

  testClient('hover ignores repeated equivalent pointer state', (tester) async {
    GlobalNodeKey<web.HTMLDivElement>? nodeKey;
    final values = <bool?>[];

    tester.pumpComponent(
      HookBuilder(
        builder: (context) {
          final key = useNodeKey<web.HTMLDivElement>();
          nodeKey = key;
          values.add(useHover(key));
          return div(const <Component>[], key: key);
        },
      ),
    );

    await pumpEventQueue();
    final node = nodeKey!.currentNode!;
    node.dispatchEvent(web.PointerEvent('pointerenter'));
    await pumpEventQueue();
    expect(values.last, isTrue);

    final buildCount = values.length;
    node.dispatchEvent(web.PointerEvent('pointerenter'));
    await pumpEventQueue();
    expect(values, hasLength(buildCount));
  });

  testClient('event subscriptions move when a keyed target changes', (tester) async {
    final harness = TestHarnessController();
    var firstTarget = true;
    GlobalNodeKey<web.HTMLDivElement>? firstKey;
    GlobalNodeKey<web.HTMLDivElement>? secondKey;
    var events = 0;

    tester.pumpComponent(
      TestHarness(
        controller: harness,
        builder: () => HookBuilder(
          builder: (context) {
            final first = useNodeKey<web.HTMLDivElement>();
            final second = useNodeKey<web.HTMLDivElement>();
            firstKey = first;
            secondKey = second;
            final active = firstTarget ? first : second;
            useEventListener<web.Event>(
              'jaspr-hooks-switch',
              (event) => events++,
              target: () => active.currentNode,
            );
            return div(const <Component>[], key: active);
          },
        ),
      ),
    );

    await pumpEventQueue();
    final oldNode = firstKey!.currentNode!;
    oldNode.dispatchEvent(web.Event('jaspr-hooks-switch'));
    expect(events, 1);

    firstTarget = false;
    harness.rebuild();
    await pumpEventQueue();
    final newNode = secondKey!.currentNode!;
    oldNode.dispatchEvent(web.Event('jaspr-hooks-switch'));
    newNode.dispatchEvent(web.Event('jaspr-hooks-switch'));
    expect(events, 2);

    harness.unmountChild();
    await pumpEventQueue();
    newNode.dispatchEvent(web.Event('jaspr-hooks-switch'));
    expect(events, 2);
  });

  testClient('observer options snapshot mutable filter lists', (tester) async {
    final harness = TestHarnessController();
    final attributeFilter = <String>['data-first'];
    final attributes = <String>[];
    GlobalNodeKey<web.HTMLDivElement>? nodeKey;

    tester.pumpComponent(
      TestHarness(
        controller: harness,
        builder: () => HookBuilder(
          builder: (context) {
            final key = useNodeKey<web.HTMLDivElement>();
            nodeKey = key;
            useMutationObserver(
              key,
              (records) => attributes.addAll(records.map((record) => record.attributeName).whereType<String>()),
              options: MutationObserverOptions(
                childList: false,
                attributes: true,
                attributeFilter: attributeFilter,
              ),
            );
            return div(const <Component>[], key: key);
          },
        ),
      ),
    );

    await pumpEventQueue();
    final node = nodeKey!.currentNode!;
    node.setAttribute('data-first', 'one');
    await pumpEventQueue();
    expect(attributes, <String>['data-first']);

    attributes.clear();
    attributeFilter[0] = 'data-second';
    harness.rebuild();
    await pumpEventQueue();
    node.setAttribute('data-first', 'two');
    node.setAttribute('data-second', 'one');
    await pumpEventQueue();

    expect(attributes, <String>['data-second']);
  });

  testClient('an explicit null event target stays detached', (tester) async {
    final harness = TestHarnessController();
    var attach = false;
    GlobalNodeKey<web.HTMLDivElement>? nodeKey;
    var events = 0;

    tester.pumpComponent(
      TestHarness(
        controller: harness,
        builder: () => HookBuilder(
          builder: (context) {
            final key = useNodeKey<web.HTMLDivElement>();
            nodeKey = key;
            useEventListener<web.Event>(
              'jaspr-hooks-null-target',
              (event) => events++,
              target: () => attach ? key.currentNode : null,
            );
            return div(const <Component>[], key: key);
          },
        ),
      ),
    );

    await pumpEventQueue();
    web.window.dispatchEvent(web.Event('jaspr-hooks-null-target'));
    expect(events, 0);

    attach = true;
    harness.rebuild();
    await pumpEventQueue();
    final node = nodeKey!.currentNode!;
    node.dispatchEvent(web.Event('jaspr-hooks-null-target'));
    expect(events, 1);

    attach = false;
    harness.rebuild();
    await pumpEventQueue();
    node.dispatchEvent(web.Event('jaspr-hooks-null-target'));
    expect(events, 1);
  });

  testClient('browser utility hooks activate, update, and dispose', (tester) async {
    final harness = TestHarnessController();
    GlobalNodeKey<web.HTMLDivElement>? regionKey;
    GlobalNodeKey<web.HTMLInputElement>? inputKey;
    FocusController? focus;
    bool? focusWithin;
    web.Element? activeElement;
    web.AbortController? abortController;
    HistoryController? history;
    ClipboardController? clipboard;
    var animationFrames = 0;
    var animate = true;

    final originalUri = Uri.parse(web.window.location.href);
    final originalState = web.window.history.state;
    final fakeClipboard = JSObject()
      ..setProperty(
        'readText'.toJS,
        (() => Future<JSString>.value('from clipboard'.toJS).toJS).toJS,
      )
      ..setProperty(
        'writeText'.toJS,
        ((JSString value) => Future<JSAny?>.value().toJS).toJS,
      );
    final restoreClipboard = _overrideJsProperty(
      web.window.navigator as JSObject,
      'clipboard',
      fakeClipboard,
    );

    try {
      tester.pumpComponent(
        TestHarness(
          controller: harness,
          builder: () => HookBuilder(
            builder: (context) {
              final region = useNodeKey<web.HTMLDivElement>();
              final inputNode = useNodeKey<web.HTMLInputElement>();
              regionKey = region;
              inputKey = inputNode;
              focus = useFocus(inputNode);
              focusWithin = useFocusWithin(region);
              activeElement = useActiveElement();
              abortController = useAbortController();
              history = useHistoryState();
              clipboard = useClipboard();
              useAnimationFrame((timestamp) => animationFrames++, enabled: animate);
              return div(key: region, [
                input(key: inputNode, id: 'hook-focus-target'),
              ]);
            },
          ),
        ),
      );

      await pumpEventQueue();

      expect(abortController, isNotNull);
      expect(history, isNotNull);
      expect(clipboard!.isSupported, isTrue);
      expect(animationFrames, greaterThan(0));

      focus!.focus();
      await pumpEventQueue();
      expect(focus!.hasFocus, isTrue);
      expect(focusWithin, isTrue);
      expect(activeElement, same(inputKey!.currentNode));

      focus!.blur();
      await pumpEventQueue();
      expect(focus!.hasFocus, isFalse);
      expect(focusWithin, isFalse);

      history!.push(
        Uri(path: '/hook-history', queryParameters: const {'step': '1'}),
        state: const {'step': 1},
      );
      expect(history!.entry.uri.path, '/hook-history');
      expect(history!.entry.uri.queryParameters['step'], '1');
      history!.replace(
        Uri(path: '/hook-history', fragment: 'done'),
        state: const {'step': 2},
      );
      expect(history!.entry.uri.fragment, 'done');

      await clipboard!.writeText('written');
      expect(clipboard!.text, 'written');
      expect(clipboard!.status, ClipboardStatus.success);
      expect(await clipboard!.readText(), 'from clipboard');
      expect(clipboard!.text, 'from clipboard');

      final framesBeforeDisable = animationFrames;
      animate = false;
      harness.rebuild();
      await pumpEventQueue();
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(animationFrames, lessThanOrEqualTo(framesBeforeDisable + 1));

      final ownedAbortController = abortController!;
      final ownedHistory = history!;
      final ownedClipboard = clipboard!;
      harness.unmountChild();
      await pumpEventQueue();
      expect(ownedAbortController.signal.aborted, isTrue);
      expect(() => ownedHistory.push(Uri(path: '/detached')), throwsStateError);
      expect(ownedClipboard.writeText('detached'), throwsStateError);
      expect(regionKey!.currentNode, isNull);
    } finally {
      web.window.history.replaceState(originalState, '', originalUri.toString());
      restoreClipboard();
    }
  });
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
