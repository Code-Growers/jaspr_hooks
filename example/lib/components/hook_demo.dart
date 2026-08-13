import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_content/theme.dart';
import 'package:jaspr_hooks/jaspr_hooks.dart';
import 'package:jaspr_hooks/web.dart' as hooks_web;
import 'package:universal_web/web.dart' as web;

@client
class HookDemo extends StatelessComponent {
  const HookDemo({required this.name, super.key});

  final String name;

  static const Set<String> supportedNames = <String>{
    'use',
    'useAbortController',
    'useActiveElement',
    'useAnimationFrame',
    'useAsyncAction',
    'useCallback',
    'useClipboard',
    'useContext',
    'useCounter',
    'useDebounced',
    'useDisposable',
    'useDocumentVisibility',
    'useEffect',
    'useEffectOnce',
    'useElementSize',
    'useEventListener',
    'useEvent',
    'useExternalStore',
    'useFuture',
    'useFocus',
    'useFocusWithin',
    'useHover',
    'useHistoryState',
    'useId',
    'useImperativeHandle',
    'useInherited',
    'useIntersection',
    'useInterval',
    'useIsMounted',
    'useLatest',
    'useList',
    'useListenable',
    'useListenableSelector',
    'useMap',
    'useMediaQuery',
    'useMemoized',
    'useMount',
    'useMutationObserver',
    'useNodeKey',
    'useOnClickOutside',
    'useOnDocumentVisibilityChange',
    'useOnListenableChange',
    'useOnMediaQueryChange',
    'useOnPreferredColorSchemeChange',
    'useOnPreferredMotionChange',
    'useOnStreamChange',
    'useOptimistic',
    'usePostFrameEffect',
    'usePreferredColorScheme',
    'usePreferredMotion',
    'usePrevious',
    'useQueue',
    'useReducer',
    'useRef',
    'useSet',
    'useState',
    'useStream',
    'useStreamController',
    'useTimeout',
    'useToggle',
    'useUnmount',
    'useUpdateEffect',
    'useValueChanged',
    'useValueListenable',
    'useValueNotifier',
    'useWindowSize',
  };

  @override
  Component build(BuildContext context) {
    return div(
      classes: 'hook-demo',
      attributes: <String, String>{'data-hook-demo': name},
      <Component>[
        div(classes: 'hook-demo-label', <Component>[Component.text('Interactive $name demo')]),
        HookBuilder(builder: (BuildContext context) => _buildDemo(name, context)),
      ],
    );
  }

  Component _buildDemo(String name, BuildContext context) {
    return switch (name) {
      'use' => _useDemo(),
      'useAbortController' => _useAbortControllerDemo(),
      'useActiveElement' => _useActiveElementDemo(),
      'useAnimationFrame' => _useAnimationFrameDemo(),
      'useAsyncAction' => _useAsyncActionDemo(),
      'useCallback' => _useCallbackDemo(),
      'useClipboard' => _useClipboardDemo(),
      'useContext' => _useContextDemo(),
      'useCounter' => _useCounterDemo(),
      'useDebounced' => _useDebouncedDemo(),
      'useDisposable' => _useDisposableDemo(),
      'useDocumentVisibility' => _useDocumentVisibilityDemo(),
      'useEffect' => _useEffectDemo(context),
      'useEffectOnce' => _useEffectOnceDemo(),
      'useElementSize' => _useElementSizeDemo(),
      'useEventListener' => _useEventListenerDemo(),
      'useEvent' => _useEventDemo(),
      'useExternalStore' => _useExternalStoreDemo(),
      'useFuture' => _useFutureDemo(context),
      'useFocus' => _useFocusDemo(),
      'useFocusWithin' => _useFocusWithinDemo(),
      'useHover' => _useHoverDemo(),
      'useHistoryState' => _useHistoryStateDemo(),
      'useId' => _useIdDemo(),
      'useImperativeHandle' => _useImperativeHandleDemo(),
      'useInherited' => _useInheritedDemo(),
      'useIntersection' => _useIntersectionDemo(),
      'useInterval' => _useIntervalDemo(),
      'useIsMounted' => _useIsMountedDemo(),
      'useLatest' => _useLatestDemo(),
      'useList' => _useListDemo(),
      'useListenable' => _useListenableDemo(),
      'useListenableSelector' => _useListenableSelectorDemo(),
      'useMap' => _useMapDemo(),
      'useMediaQuery' => _useMediaQueryDemo(),
      'useMemoized' => _useMemoizedDemo(),
      'useMount' => _useMountDemo(),
      'useMutationObserver' => _useMutationObserverDemo(),
      'useNodeKey' => _useNodeKeyDemo(),
      'useOnClickOutside' => _useOnClickOutsideDemo(),
      'useOnDocumentVisibilityChange' => _useOnDocumentVisibilityChangeDemo(),
      'useOnListenableChange' => _useOnListenableChangeDemo(),
      'useOnMediaQueryChange' => _useOnMediaQueryChangeDemo(),
      'useOnPreferredColorSchemeChange' => _useOnPreferredColorSchemeChangeDemo(),
      'useOnPreferredMotionChange' => _useOnPreferredMotionChangeDemo(),
      'useOnStreamChange' => _useOnStreamChangeDemo(context),
      'useOptimistic' => _useOptimisticDemo(),
      'usePostFrameEffect' => _usePostFrameEffectDemo(),
      'usePreferredColorScheme' => _usePreferredColorSchemeDemo(),
      'usePreferredMotion' => _usePreferredMotionDemo(),
      'usePrevious' => _usePreviousDemo(),
      'useQueue' => _useQueueDemo(),
      'useReducer' => _useReducerDemo(),
      'useRef' => _useRefDemo(),
      'useSet' => _useSetDemo(),
      'useState' => _useStateDemo(),
      'useStream' => _useStreamDemo(context),
      'useStreamController' => _useStreamControllerDemo(context),
      'useTimeout' => _useTimeoutDemo(),
      'useToggle' => _useToggleDemo(),
      'useUnmount' => _useUnmountDemo(),
      'useUpdateEffect' => _useUpdateEffectDemo(),
      'useValueChanged' => _useValueChangedDemo(),
      'useValueListenable' => _useValueListenableDemo(),
      'useValueNotifier' => _useValueNotifierDemo(),
      'useWindowSize' => _useWindowSizeDemo(),
      _ => _output('Unknown demo: $name'),
    };
  }

  Component _useDemo() {
    final _CustomCounter counter = use(const _CustomCounterHook());
    return _row(<Component>[
      _action('Increment custom hook', counter.increment),
      _output('Custom HookState value: ${counter.value}'),
    ]);
  }

  Component _useAsyncActionDemo() {
    final AsyncAction<int, int> action = useAsyncAction<int, int>(
      initialState: 0,
      action: (int state, int increment) async {
        await Future<void>.delayed(const Duration(milliseconds: 180));
        return state + increment;
      },
    );
    return _row(<Component>[
      _action('Run async +1', () => unawaited(action.dispatch(1))),
      _output(
        'State ${action.state} • ${action.isPending ? 'pending' : 'idle'}'
        '${action.error == null ? '' : ' • ${action.error}'}',
      ),
    ]);
  }

  Component _useAbortControllerDemo() {
    final ValueNotifier<int> generation = useState<int>(0);
    final web.AbortController? controller = hooks_web.useAbortController(<Object?>[generation.value]);
    return _row(<Component>[
      _action('Replace controller', () => generation.value++),
      _output('Generation ${generation.value} • controller ${controller == null ? 'waiting' : 'ready'}'),
    ]);
  }

  Component _useActiveElementDemo() {
    final GlobalNodeKey<web.HTMLButtonElement> key = hooks_web.useNodeKey<web.HTMLButtonElement>();
    final web.Element? active = hooks_web.useActiveElement();
    return _row(<Component>[
      _action('Focus this button', () => key.currentNode?.focus(), key: key),
      _output('Active element: ${active?.tagName.toLowerCase() ?? 'none'}'),
    ]);
  }

  Component _useAnimationFrameDemo() {
    final ToggleController running = useToggle(false);
    final ValueNotifier<int> frames = useState<int>(0);
    hooks_web.useAnimationFrame((timestamp) => frames.value++, enabled: running.value && frames.value < 12);
    return _row(<Component>[
      _action(running.value ? 'Pause frames' : 'Run frames', running.toggle),
      _output('Animation frames: ${frames.value}'),
    ]);
  }

  Component _useCallbackDemo() {
    final ValueNotifier<int> count = useState<int>(0);
    final ValueNotifier<int> calls = useState<int>(0);
    final VoidCallback increment = useCallback<VoidCallback>(() {
      count.value++;
      calls.value++;
    });
    return _row(<Component>[
      _action('Call stable callback', increment),
      _output('Count ${count.value} • callback calls ${calls.value}'),
    ]);
  }

  Component _useClipboardDemo() {
    final hooks_web.ClipboardController clipboard = hooks_web.useClipboard();
    return _row(<Component>[
      _action('Copy demo text', () {
        unawaited(clipboard.writeText('jaspr_hooks').catchError((_) {}));
      }),
      _output('Clipboard: ${clipboard.status.name}${clipboard.text == null ? '' : ' • ${clipboard.text}'}'),
    ]);
  }

  Component _useContextDemo() {
    useContext();
    return _output('Current hook BuildContext is available in this component.');
  }

  Component _useCounterDemo() {
    final CounterController counter = useCounter(0);
    return _row(<Component>[
      _action('Increment counter', counter.increment),
      _secondaryAction('Reset', counter.reset),
      _output('Counter: ${counter.value}'),
    ]);
  }

  Component _useDebouncedDemo() {
    final ValueNotifier<int> input = useState<int>(0);
    final int? settled = useDebounced<int>(input.value, const Duration(milliseconds: 350));
    return _row(<Component>[
      _action('Change input', () => input.value++),
      _output('Input ${input.value} • settled ${settled ?? 'waiting…'}'),
    ]);
  }

  Component _useDisposableDemo() {
    final ValueNotifier<int> key = useState<int>(0);
    final ObjectRef<int> disposals = useRef<int>(0);
    final _DemoResource resource = useDisposable<_DemoResource>(
      () => _DemoResource(key.value + 1),
      (_) => disposals.value++,
      <Object?>[key.value],
    );
    return _row(<Component>[
      _action('Replace resource', () => key.value++),
      _output('Resource #${resource.id} • disposed ${disposals.value}'),
    ]);
  }

  Component _useDocumentVisibilityDemo() {
    final DocumentVisibility visibility = useDocumentVisibility();
    return _output('Document visibility: ${visibility.name}. Switch tabs to see it update.');
  }

  Component _useEffectDemo(BuildContext context) {
    final ValueNotifier<int> dependency = useState<int>(0);
    final ValueNotifier<int> runs = useState<int>(0);
    useEffect(() {
      final int completedRun = dependency.value + 1;
      context.binding.addPostFrameCallback(() {
        if (runs.value < completedRun) {
          runs.value = completedRun;
        }
      });
      return null;
    }, <Object?>[dependency.value]);
    return _row(<Component>[
      _action('Change dependency', () => dependency.value++),
      _output('Dependency ${dependency.value} • effect runs ${runs.value}'),
    ]);
  }

  Component _useEffectOnceDemo() {
    final ObjectRef<int> runs = useRef<int>(0);
    final ValueNotifier<int> rebuilds = useState<int>(0);
    useEffectOnce(() {
      runs.value++;
      return null;
    });
    return _row(<Component>[
      _action('Rebuild', () => rebuilds.value++),
      _output('Effect-once runs ${runs.value} • rebuilds ${rebuilds.value}'),
    ]);
  }

  Component _useElementSizeDemo() {
    final GlobalNodeKey<web.HTMLDivElement> key = hooks_web.useNodeKey<web.HTMLDivElement>(
      debugLabel: 'size-demo',
    );
    final hooks_web.ElementSize? size = hooks_web.useElementSize(key);
    return _row(<Component>[
      div(key: key, classes: 'hook-demo-measure-target', <Component>[Component.text('Measured target')]),
      _output(size == null ? 'Waiting for measurement…' : '${size.width.round()} × ${size.height.round()} px'),
    ]);
  }

  Component _useEventListenerDemo() {
    final ValueNotifier<int> clicks = useState<int>(0);
    hooks_web.useEventListener<web.PointerEvent>(
      'pointerdown',
      (_) => clicks.value++,
    );
    return _row(<Component>[
      _action('Dispatch pointer event', () {}),
      _output('Window pointer events: ${clicks.value}'),
    ]);
  }

  Component _useEventDemo() {
    final ValueNotifier<int> multiplier = useState<int>(2);
    final StableEventCallback<int, int> multiply = useEvent<int, int>((value) => value * multiplier.value);
    final ValueNotifier<int> result = useState<int>(0);
    return _row(<Component>[
      _action('Invoke latest handler', () {
        multiplier.value++;
        result.value = multiply(3);
      }),
      _output('Multiplier ${multiplier.value} • result ${result.value}'),
    ]);
  }

  Component _useExternalStoreDemo() {
    final _DemoExternalStore store = useDisposable<_DemoExternalStore>(
      _DemoExternalStore.new,
      (value) => value.dispose(),
    );
    final int value = useExternalStore<int>(
      store.subscribe,
      () => store.value,
      getServerSnapshot: () => 0,
    );
    return _row(<Component>[
      _action('Update external store', store.increment),
      _output('External snapshot: $value'),
    ]);
  }

  Component _useFutureDemo(BuildContext context) {
    final ValueNotifier<int> request = useState<int>(0);
    final Future<String>? future = useMemoized<Future<String>?>(() {
      if (!context.binding.isClient) return null;
      final int id = request.value;
      return Future<String>.delayed(const Duration(milliseconds: 250), () => 'response $id');
    }, <Object?>[request.value]);
    final AsyncSnapshot<String> snapshot = useFuture<String>(future, initialData: 'SSR-ready');
    return _row(<Component>[
      _action('Load again', () => request.value++),
      _output(
        '${snapshot.connectionState == ConnectionState.done ? 'done' : 'ready'}: '
        '${snapshot.data ?? snapshot.error ?? 'no data'}',
      ),
    ]);
  }

  Component _useFocusDemo() {
    final GlobalNodeKey<web.HTMLButtonElement> key = hooks_web.useNodeKey<web.HTMLButtonElement>();
    final hooks_web.FocusController focus = hooks_web.useFocus(key);
    return _row(<Component>[
      button(key: key, classes: 'hook-demo-action hook-demo-action-secondary', [Component.text('Focus target')]),
      _action('Request focus', focus.focus),
      _output('Focused: ${focus.hasFocus ?? 'waiting'}'),
    ]);
  }

  Component _useFocusWithinDemo() {
    final GlobalNodeKey<web.HTMLDivElement> key = hooks_web.useNodeKey<web.HTMLDivElement>();
    final bool? focusedWithin = hooks_web.useFocusWithin(key);
    return _row(<Component>[
      div(key: key, [
        button(classes: 'hook-demo-action hook-demo-action-secondary', [Component.text('Nested focus target')]),
      ]),
      _output('Focus within: ${focusedWithin ?? 'waiting'}'),
    ]);
  }

  Component _useHoverDemo() {
    final GlobalNodeKey<web.HTMLDivElement> key = hooks_web.useNodeKey<web.HTMLDivElement>();
    final bool? hovering = hooks_web.useHover(key);
    return _row(<Component>[
      div(key: key, classes: 'hook-demo-hover-target', <Component>[Component.text('Hover me')]),
      _output(hovering == null ? 'Waiting for browser…' : 'Hovering: $hovering'),
    ]);
  }

  Component _useHistoryStateDemo() {
    final hooks_web.HistoryController? history = hooks_web.useHistoryState();
    final ValueNotifier<int> step = useState<int>(0);
    return _row(<Component>[
      _action('Replace history state', () {
        step.value++;
        history?.replace(
          Uri(path: web.window.location.pathname, queryParameters: <String, String>{'demoStep': '${step.value}'}),
        );
      }),
      _output('History: ${history?.entry.uri.queryParameters['demoStep'] ?? 'waiting'}'),
    ]);
  }

  Component _useIdDemo() {
    final String id = useId(prefix: 'demo');
    final ValueNotifier<int> rebuilds = useState<int>(0);
    return _row(<Component>[
      _action('Rebuild with same id', () => rebuilds.value++),
      _output('ID $id • rebuilds ${rebuilds.value}'),
    ]);
  }

  Component _useImperativeHandleDemo() {
    final ObjectRef<_DemoHandle?> target = useRef<_DemoHandle?>(null);
    final ValueNotifier<int> key = useState<int>(0);
    useImperativeHandle<_DemoHandle>(target, () => _DemoHandle(key.value + 1), <Object?>[key.value]);
    return _row(<Component>[
      _action('Replace handle', () => key.value++),
      _output('Exposed handle #${target.value?.id ?? 'none'}'),
    ]);
  }

  Component _useInheritedDemo() {
    useInherited<_DemoInherited>();
    return _output('Typed inherited-component lookup is active.');
  }

  Component _useIntersectionDemo() {
    final GlobalNodeKey<web.HTMLDivElement> key = hooks_web.useNodeKey<web.HTMLDivElement>();
    final hooks_web.IntersectionSnapshot? snapshot = hooks_web.useIntersection(key);
    return _row(<Component>[
      div(key: key, classes: 'hook-demo-measure-target', <Component>[Component.text('Observed target')]),
      _output(
        snapshot == null
            ? 'Waiting for intersection…'
            : 'Visible ${snapshot.isIntersecting} • ${(snapshot.ratio * 100).round()}%',
      ),
    ]);
  }

  Component _useIntervalDemo() {
    final ValueNotifier<int> ticks = useState<int>(0);
    final ToggleController running = useToggle(false);
    useInterval(() => ticks.value++, running.value ? const Duration(milliseconds: 500) : null);
    return _row(<Component>[
      _action(running.value ? 'Pause interval' : 'Start interval', running.toggle),
      _output('Interval ticks: ${ticks.value}'),
    ]);
  }

  Component _useIsMountedDemo() {
    final IsMounted isMounted = useIsMounted();
    return _output('Mounted now: ${isMounted()}');
  }

  Component _useLatestDemo() {
    final ValueNotifier<int> value = useState<int>(0);
    final ObjectRef<int> latest = useLatest<int>(value.value);
    return _row(<Component>[
      _action('Update latest value', () => value.value++),
      _output('Stable reference contains ${latest.value}'),
    ]);
  }

  Component _useListDemo() {
    final ListController<int> list = useList<int>(<int>[1]);
    return _row(<Component>[
      _action('Append item', () => list.add(list.value.length + 1)),
      _secondaryAction('Clear', list.clear),
      _output('List: ${list.value.join(', ')}'),
    ]);
  }

  Component _useListenableDemo() {
    final ValueNotifier<int> notifier = useValueNotifier<int>(0);
    useListenable<ValueNotifier<int>>(notifier);
    return _row(<Component>[
      _action('Notify listeners', () => notifier.value++),
      _output('Listenable value: ${notifier.value}'),
    ]);
  }

  Component _useListenableSelectorDemo() {
    final _SelectionModel model = useMemoized<_SelectionModel>(_SelectionModel.new);
    useEffect(() => model.dispose, <Object?>[model]);
    final int selected = useListenableSelector<int>(model, () => model.selected);
    return _row(<Component>[
      _action('Change selected value', model.changeSelected),
      _secondaryAction('Change ignored value', model.changeIgnored),
      _output('Selected $selected • ignored ${model.ignored}'),
    ]);
  }

  Component _useMapDemo() {
    final MapController<String, int> map = useMap<String, int>(<String, int>{'clicks': 0});
    return _row(<Component>[
      _action('Update entry', () => map.setValue('clicks', (map.value['clicks'] ?? 0) + 1)),
      _output('Map: ${map.value}'),
    ]);
  }

  Component _useMediaQueryDemo() {
    final MediaQueryMatch match = useMediaQuery('(min-width: 700px)');
    return _output('Minimum 700px: ${match.name}');
  }

  Component _useMemoizedDemo() {
    final ValueNotifier<int> key = useState<int>(0);
    final ObjectRef<int> creations = useRef<int>(0);
    final int resource = useMemoized<int>(() {
      creations.value++;
      return creations.value;
    }, <Object?>[key.value]);
    return _row(<Component>[
      _action('Change key', () => key.value++),
      _output('Key ${key.value} • memoized resource #$resource'),
    ]);
  }

  Component _useMountDemo() {
    final ObjectRef<int> mounts = useRef<int>(0);
    final ValueNotifier<int> rebuilds = useState<int>(0);
    useMount(() => mounts.value++);
    return _row(<Component>[
      _action('Rebuild', () => rebuilds.value++),
      _output('Mount callback ran ${mounts.value} time • rebuilds ${rebuilds.value}'),
    ]);
  }

  Component _useMutationObserverDemo() {
    final GlobalNodeKey<web.HTMLDivElement> key = hooks_web.useNodeKey<web.HTMLDivElement>();
    final ValueNotifier<int> mutations = useState<int>(0);
    final ValueNotifier<int> children = useState<int>(1);
    hooks_web.useMutationObserver(key, (records) => mutations.value += records.length);
    return _row(<Component>[
      div(
        key: key,
        <Component>[
          for (var index = 0; index < children.value; index++) span(<Component>[Component.text('•')]),
        ],
      ),
      _action('Mutate children', () => children.value++),
      _output('Observed mutation batches: ${mutations.value}'),
    ]);
  }

  Component _useNodeKeyDemo() {
    final GlobalNodeKey<web.HTMLDivElement> key = hooks_web.useNodeKey<web.HTMLDivElement>(
      debugLabel: 'node-key-demo',
    );
    final ValueNotifier<int> checks = useState<int>(0);
    return _row(<Component>[
      div(key: key, <Component>[Component.text('Keyed browser node')]),
      _action('Check node', () => checks.value++),
      _output('Node attached: ${key.currentNode != null} • checks ${checks.value}'),
    ]);
  }

  Component _useOnClickOutsideDemo() {
    final GlobalNodeKey<web.HTMLDivElement> key = hooks_web.useNodeKey<web.HTMLDivElement>();
    final ValueNotifier<int> outside = useState<int>(0);
    hooks_web.useOnClickOutside(key, (_) => outside.value++);
    return _row(<Component>[
      div(key: key, classes: 'hook-demo-hover-target', <Component>[Component.text('Inside area')]),
      _action('Click outside area', () {}),
      _output('Outside pointer events: ${outside.value}'),
    ]);
  }

  Component _useOnDocumentVisibilityChangeDemo() {
    final ValueNotifier<int> changes = useState<int>(0);
    final ObjectRef<String> transition = useRef<String>('No changes yet');
    useOnDocumentVisibilityChange((DocumentVisibility previous, DocumentVisibility current) {
      transition.value = '${previous.name} → ${current.name}';
      changes.value++;
    });
    return _output('Visibility changes ${changes.value} • ${transition.value}. Switch tabs to trigger it.');
  }

  Component _useOnListenableChangeDemo() {
    final ValueNotifier<int> source = useValueNotifier<int>(0);
    final ValueNotifier<int> calls = useState<int>(0);
    useOnListenableChange(source, () => calls.value++);
    return _row(<Component>[
      _action('Notify', () => source.value++),
      _output('Source ${source.value} • listener calls ${calls.value}'),
    ]);
  }

  Component _useOnMediaQueryChangeDemo() {
    final ValueNotifier<int> changes = useState<int>(0);
    final ObjectRef<String> transition = useRef<String>('No changes yet');
    useOnMediaQueryChange('(min-width: 700px)', (previous, current) {
      transition.value = '${previous.name} → ${current.name}';
      changes.value++;
    });
    return _output('Media changes ${changes.value} • ${transition.value}. Resize the window.');
  }

  Component _useOnPreferredColorSchemeChangeDemo() {
    final ValueNotifier<int> changes = useState<int>(0);
    final ObjectRef<String> transition = useRef<String>('No changes yet');
    useOnPreferredColorSchemeChange((PreferredColorScheme previous, PreferredColorScheme current) {
      transition.value = '${previous.name} → ${current.name}';
      changes.value++;
    });
    return _output('Scheme changes ${changes.value} • ${transition.value}. Change your OS theme to trigger it.');
  }

  Component _useOnPreferredMotionChangeDemo() {
    final ValueNotifier<int> changes = useState<int>(0);
    final ObjectRef<String> transition = useRef<String>('No changes yet');
    useOnPreferredMotionChange((previous, current) {
      transition.value = '${previous.name} → ${current.name}';
      changes.value++;
    });
    return _output('Motion changes ${changes.value} • ${transition.value}');
  }

  Component _useOnStreamChangeDemo(BuildContext context) {
    final StreamController<int> controller = useStreamController<int>(sync: true);
    final ValueNotifier<int> latest = useState<int>(0);
    // ignore: cancel_subscriptions, canceled by useOnStreamChange on disposal.
    useOnStreamChange<int>(
      context.binding.isClient ? controller.stream : null,
      onData: (int value) => latest.value = value,
    );
    return _row(<Component>[
      _action('Emit event', () => controller.add(latest.value + 1)),
      _output('Latest stream event: ${latest.value}'),
    ]);
  }

  Component _useOptimisticDemo() {
    final OptimisticState<int, int> optimistic = useOptimistic<int, int>(
      0,
      (state, update) => state + update,
    );
    return _row(<Component>[
      _action('Add optimistic +1', () {
        final handle = optimistic.add(1);
        Future<void>.delayed(const Duration(milliseconds: 350), () {
          if (handle.isPending) handle.commit(optimistic.value);
        });
      }),
      _secondaryAction('Rollback all', optimistic.reset),
      _output('Optimistic value ${optimistic.value} • pending ${optimistic.pendingCount}'),
    ]);
  }

  Component _usePostFrameEffectDemo() {
    final ValueNotifier<int> dependency = useState<int>(0);
    final ValueNotifier<int> runs = useState<int>(0);
    usePostFrameEffect(() {
      runs.value++;
      return null;
    }, <Object?>[dependency.value]);
    return _row(<Component>[
      _action('Schedule next frame', () => dependency.value++),
      _output('Dependency ${dependency.value} • completed post-frame runs ${runs.value}'),
    ]);
  }

  Component _usePreferredColorSchemeDemo() {
    final PreferredColorScheme scheme = usePreferredColorScheme();
    return _output('Preferred color scheme: ${scheme.name}');
  }

  Component _usePreferredMotionDemo() {
    final PreferredMotion motion = usePreferredMotion();
    return _output('Preferred motion: ${motion.name}');
  }

  Component _usePreviousDemo() {
    final ValueNotifier<int> current = useState<int>(0);
    final int? previous = usePrevious<int>(current.value);
    return _row(<Component>[
      _action('Advance value', () => current.value++),
      _output('Current ${current.value} • previous ${previous ?? 'none'}'),
    ]);
  }

  Component _useQueueDemo() {
    final QueueController<int> queue = useQueue<int>(<int>[1]);
    return _row(<Component>[
      _action('Enqueue', () => queue.enqueue(queue.length + 1)),
      _secondaryAction('Dequeue', () {
        if (queue.isNotEmpty) queue.dequeue();
      }),
      _output('Queue: ${queue.value.join(' → ')}'),
    ]);
  }

  Component _useReducerDemo() {
    final Store<int, int> store = useReducer<int, int>(
      (int state, int action) => state + action,
      initialState: 0,
      initialAction: 0,
    );
    return _row(<Component>[
      _action('Dispatch +1', () => store.dispatch(1)),
      _output('Reducer state: ${store.state}'),
    ]);
  }

  Component _useRefDemo() {
    final ObjectRef<int> ref = useRef<int>(0);
    final ValueNotifier<int> repaint = useState<int>(0);
    return _row(<Component>[
      _action('Mutate ref and repaint', () {
        ref.value++;
        repaint.value++;
      }),
      _output('Ref ${ref.value} • repaint ${repaint.value}'),
    ]);
  }

  Component _useSetDemo() {
    final SetController<int> set = useSet<int>(<int>{1});
    return _row(<Component>[
      _action('Add unique value', () => set.add(set.value.length + 1)),
      _secondaryAction('Clear', set.clear),
      _output('Set: ${set.value.join(', ')}'),
    ]);
  }

  Component _useStateDemo() {
    final ValueNotifier<int> count = useState<int>(0);
    return _row(<Component>[
      _action('Increment', () => count.value++),
      _output('Count: ${count.value}'),
    ]);
  }

  Component _useStreamDemo(BuildContext context) {
    final StreamController<int> controller = useStreamController<int>(sync: true);
    final ValueNotifier<int> next = useState<int>(1);
    final AsyncSnapshot<int> snapshot = useStream<int>(
      context.binding.isClient ? controller.stream : null,
      initialData: 0,
    );
    return _row(<Component>[
      _action('Add stream value', () {
        controller.add(next.value);
        next.value++;
      }),
      _output('Latest stream value: ${snapshot.data}'),
    ]);
  }

  Component _useStreamControllerDemo(BuildContext context) {
    final StreamController<String> controller = useStreamController<String>(sync: true);
    final ValueNotifier<String> received = useState<String>('none');
    useOnStreamChange<String>(
      context.binding.isClient ? controller.stream : null,
      onData: (String event) => received.value = event,
    );
    return _row(<Component>[
      _action('Broadcast event', () => controller.add('event-${DateTime.now().millisecond}')),
      _output('Broadcast: ${controller.stream.isBroadcast} • received ${received.value}'),
    ]);
  }

  Component _useTimeoutDemo() {
    final ValueNotifier<int> generation = useState<int>(0);
    final ValueNotifier<String> status = useState<String>('scheduled');
    useTimeout(
      () => status.value = 'completed #${generation.value}',
      Duration(milliseconds: 600 + generation.value),
    );
    return _row(<Component>[
      _action('Restart timeout', () {
        generation.value++;
        status.value = 'scheduled #${generation.value}';
      }),
      _output('Timeout: ${status.value}'),
    ]);
  }

  Component _useToggleDemo() {
    final ToggleController toggle = useToggle();
    return _row(<Component>[
      _action('Toggle', toggle.toggle),
      _output('Toggle: ${toggle.value}'),
    ]);
  }

  Component _useUnmountDemo() {
    final ToggleController childMounted = useToggle(true);
    final ValueNotifier<int> cleanups = useState<int>(0);
    final IsMounted isMounted = useIsMounted();
    return _row(<Component>[
      _action(childMounted.value ? 'Unmount child' : 'Mount child', childMounted.toggle),
      if (childMounted.value)
        HookBuilder(
          builder: (context) {
            useUnmount(() {
              scheduleMicrotask(() {
                if (isMounted()) cleanups.value++;
              });
            });
            return Component.text('Child mounted');
          },
        ),
      _output('Unmount cleanups: ${cleanups.value}'),
    ]);
  }

  Component _useUpdateEffectDemo() {
    final ValueNotifier<int> dependency = useState<int>(0);
    final ObjectRef<int> runs = useRef<int>(0);
    useUpdateEffect(() {
      runs.value++;
      return null;
    }, <Object?>[dependency.value]);
    return _row(<Component>[
      _action('Change dependency', () => dependency.value++),
      _output('Dependency ${dependency.value} • update-only runs ${runs.value}'),
    ]);
  }

  Component _useValueChangedDemo() {
    final ValueNotifier<int> current = useState<int>(0);
    final String? result = useValueChanged<int, String>(
      current.value,
      (int oldValue, String? oldResult) => 'previous value was $oldValue',
    );
    return _row(<Component>[
      _action('Change value', () => current.value++),
      _output('Current ${current.value} • ${result ?? 'no previous value'}'),
    ]);
  }

  Component _useValueListenableDemo() {
    final ValueNotifier<int> notifier = useValueNotifier<int>(0);
    final int value = useValueListenable<int>(notifier);
    return _row(<Component>[
      _action('Update notifier', () => notifier.value++),
      _output('ValueListenable value: $value'),
    ]);
  }

  Component _useValueNotifierDemo() {
    final ValueNotifier<int> notifier = useValueNotifier<int>(0);
    final int value = useValueListenable<int>(notifier);
    return _row(<Component>[
      _action('Update owned notifier', () => notifier.value++),
      _output('Owned notifier value: $value'),
    ]);
  }

  Component _useWindowSizeDemo() {
    final hooks_web.WindowSize? size = hooks_web.useWindowSize();
    return _output(size == null ? 'Waiting for viewport…' : 'Viewport ${size.width.round()} × ${size.height.round()}');
  }

  Component _row(List<Component> children) => div(classes: 'hook-demo-row', children);

  Component _action(String label, VoidCallback onClick, {Key? key}) {
    return button(
      key: key,
      classes: 'hook-demo-action',
      attributes: const <String, String>{'data-testid': 'hook-action'},
      onClick: onClick,
      <Component>[Component.text(label)],
    );
  }

  Component _secondaryAction(String label, VoidCallback onClick) {
    return button(
      classes: 'hook-demo-action hook-demo-action-secondary',
      attributes: const <String, String>{'data-testid': 'hook-secondary-action'},
      onClick: onClick,
      <Component>[Component.text(label)],
    );
  }

  Component _output(String value) {
    return div(
      classes: 'hook-demo-output',
      attributes: const <String, String>{'data-testid': 'hook-output', 'aria-live': 'polite'},
      <Component>[Component.text(value)],
    );
  }

  @css
  static List<StyleRule> get styles => <StyleRule>[
    css('.hook-demo').styles(
      padding: Padding.all(Unit.rem(1)),
      margin: Margin.symmetric(vertical: Unit.rem(1.5)),
      border: Border.all(color: ContentColors.primary, width: Unit.pixels(1)),
      radius: BorderRadius.circular(Unit.rem(0.75)),
      backgroundColor: const Color('color-mix(in srgb, var(--primary) 5%, transparent)'),
    ),
    css('.hook-demo-label').styles(
      margin: Margin.only(bottom: Unit.rem(0.75)),
      fontSize: Unit.rem(0.78),
      fontWeight: FontWeight.w700,
      letterSpacing: Unit.em(0.05),
      opacity: 0.7,
      raw: const <String, String>{'text-transform': 'uppercase'},
    ),
    css('.hook-demo-row').styles(
      display: Display.flex,
      alignItems: AlignItems.center,
      gap: Gap.all(Unit.rem(0.65)),
      flexWrap: FlexWrap.wrap,
    ),
    css('.hook-demo-action').styles(
      padding: Padding.symmetric(horizontal: Unit.rem(0.85), vertical: Unit.rem(0.55)),
      border: Border.all(color: ContentColors.primary, width: Unit.pixels(1)),
      radius: BorderRadius.circular(Unit.rem(0.5)),
      color: ContentColors.background,
      backgroundColor: ContentColors.primary,
      fontWeight: FontWeight.w700,
    ),
    css('.hook-demo-action-secondary').styles(
      color: ContentColors.primary,
      backgroundColor: Colors.transparent,
    ),
    css('.hook-demo-output').styles(
      minWidth: Unit.rem(14),
      padding: Padding.symmetric(horizontal: Unit.rem(0.75), vertical: Unit.rem(0.55)),
      border: Border.all(color: const Color('color-mix(in srgb, currentColor 18%, transparent)')),
      radius: BorderRadius.circular(Unit.rem(0.5)),
      backgroundColor: ContentColors.background,
    ),
    css('.hook-demo-measure-target, .hook-demo-hover-target').styles(
      padding: Padding.symmetric(horizontal: Unit.rem(0.75), vertical: Unit.rem(0.55)),
      border: Border.all(color: ContentColors.primary, width: Unit.pixels(1)),
      radius: BorderRadius.circular(Unit.rem(0.5)),
    ),
  ];
}

final class _DemoResource {
  const _DemoResource(this.id);

  final int id;
}

final class _DemoHandle {
  const _DemoHandle(this.id);

  final int id;
}

final class _DemoExternalStore extends ChangeNotifier {
  int value = 0;

  Dispose subscribe(VoidCallback listener) {
    addListener(listener);
    return () => removeListener(listener);
  }

  void increment() {
    value++;
    notifyListeners();
  }
}

final class _DemoInherited extends InheritedComponent {
  const _DemoInherited({required super.child});

  @override
  bool updateShouldNotify(covariant _DemoInherited oldComponent) => false;
}

abstract interface class _CustomCounter {
  int get value;

  void increment();
}

final class _CustomCounterHook extends Hook<_CustomCounter> {
  const _CustomCounterHook();

  @override
  _CustomCounterHookState createState() => _CustomCounterHookState();
}

final class _CustomCounterHookState extends HookState<_CustomCounter, _CustomCounterHook> implements _CustomCounter {
  int _value = 0;

  @override
  int get value => _value;

  @override
  void increment() => setState(() => _value++);

  @override
  _CustomCounter build(BuildContext context) => this;
}

final class _SelectionModel extends ChangeNotifier {
  int selected = 0;
  int ignored = 0;

  void changeSelected() {
    selected++;
    notifyListeners();
  }

  void changeIgnored() {
    ignored++;
    notifyListeners();
  }
}
