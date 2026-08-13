import 'package:jaspr/jaspr.dart';
import 'package:jaspr_hooks/web.dart';
import 'package:jaspr_test/server_test.dart';
import 'package:universal_web/web.dart' as web;

void main() {
  testComponents(
    'browser hooks stay inert and deterministic on the server',
    (tester) async {
      ElementSize? elementSize;
      WindowSize? windowSize;
      IntersectionSnapshot? intersection;
      bool? hovered;
      bool? focusWithin;
      FocusController? focus;
      web.Element? activeElement;
      web.AbortController? abortController;
      HistoryController? history;
      ClipboardController? clipboard;
      MediaQueryMatch? mediaQuery;
      PreferredMotion? motion;
      var resolverCalls = 0;
      var callbacks = 0;

      tester.pumpComponent(
        HookBuilder(
          builder: (context) {
            final nodeKey = useNodeKey<web.Element>();
            elementSize = useElementSize(nodeKey);
            windowSize = useWindowSize();
            intersection = useIntersection(nodeKey);
            hovered = useHover(nodeKey);
            final focusKey = useNodeKey<web.HTMLElement>();
            focus = useFocus(focusKey);
            focusWithin = useFocusWithin(focusKey);
            activeElement = useActiveElement();
            abortController = useAbortController();
            history = useHistoryState();
            clipboard = useClipboard();
            useAnimationFrame((timestamp) => callbacks++);
            mediaQuery = useMediaQuery('(min-width: 1px)');
            motion = usePreferredMotion();
            useOnMediaQueryChange('(min-width: 1px)', (previous, current) => callbacks++);
            useOnPreferredMotionChange((previous, current) => callbacks++);
            useEventListener<web.Event>(
              'test',
              (event) => callbacks++,
              target: () {
                resolverCalls++;
                return null;
              },
            );
            useOnClickOutside(nodeKey, (event) => callbacks++);
            useMutationObserver(nodeKey, (records) => callbacks++);
            return Component.element(tag: 'div', key: nodeKey);
          },
        ),
      );

      expect(elementSize, isNull);
      expect(windowSize, isNull);
      expect(intersection, isNull);
      expect(hovered, isNull);
      expect(focus!.hasFocus, isNull);
      expect(focusWithin, isNull);
      expect(activeElement, isNull);
      expect(abortController, isNull);
      expect(history, isNull);
      expect(clipboard!.isSupported, isFalse);
      expect(clipboard!.status, ClipboardStatus.idle);
      expect(mediaQuery, MediaQueryMatch.unknown);
      expect(motion, PreferredMotion.unknown);
      expect(resolverCalls, 0);
      expect(callbacks, 0);
    },
    isClient: false,
  );

  test('web hook option values use semantic equality', () {
    expect(
      const WindowSizeOptions(debounce: Duration(milliseconds: 10)),
      const WindowSizeOptions(debounce: Duration(milliseconds: 10)),
    );
    expect(
      const IntersectionOptions(thresholds: <double>[0, 0.5, 1]),
      const IntersectionOptions(thresholds: <double>[0, 0.5, 1]),
    );
    expect(
      const MutationObserverOptions(attributeFilter: <String>['aria-expanded']),
      const MutationObserverOptions(attributeFilter: <String>['aria-expanded']),
    );
    expect(const WebEventListenerOptions(capture: true), const WebEventListenerOptions(capture: true));
  });
}
