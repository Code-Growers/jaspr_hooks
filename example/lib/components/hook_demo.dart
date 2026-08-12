import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_content/theme.dart';
import 'package:jaspr_hooks/jaspr_hooks.dart';

@client
class HookDemo extends StatelessComponent {
  const HookDemo({required this.name, super.key});

  final String name;

  static const Set<String> supportedNames = <String>{
    'use',
    'useCallback',
    'useContext',
    'useDebounced',
    'useDocumentVisibility',
    'useEffect',
    'useFuture',
    'useIsMounted',
    'useListenable',
    'useListenableSelector',
    'useMemoized',
    'useOnDocumentVisibilityChange',
    'useOnListenableChange',
    'useOnPreferredColorSchemeChange',
    'useOnStreamChange',
    'usePostFrameEffect',
    'usePreferredColorScheme',
    'usePrevious',
    'useReducer',
    'useRef',
    'useState',
    'useStream',
    'useStreamController',
    'useValueChanged',
    'useValueListenable',
    'useValueNotifier',
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
      'useCallback' => _useCallbackDemo(),
      'useContext' => _useContextDemo(),
      'useDebounced' => _useDebouncedDemo(),
      'useDocumentVisibility' => _useDocumentVisibilityDemo(),
      'useEffect' => _useEffectDemo(context),
      'useFuture' => _useFutureDemo(context),
      'useIsMounted' => _useIsMountedDemo(),
      'useListenable' => _useListenableDemo(),
      'useListenableSelector' => _useListenableSelectorDemo(),
      'useMemoized' => _useMemoizedDemo(),
      'useOnDocumentVisibilityChange' => _useOnDocumentVisibilityChangeDemo(),
      'useOnListenableChange' => _useOnListenableChangeDemo(),
      'useOnPreferredColorSchemeChange' => _useOnPreferredColorSchemeChangeDemo(),
      'useOnStreamChange' => _useOnStreamChangeDemo(context),
      'usePostFrameEffect' => _usePostFrameEffectDemo(),
      'usePreferredColorScheme' => _usePreferredColorSchemeDemo(),
      'usePrevious' => _usePreviousDemo(),
      'useReducer' => _useReducerDemo(),
      'useRef' => _useRefDemo(),
      'useState' => _useStateDemo(),
      'useStream' => _useStreamDemo(context),
      'useStreamController' => _useStreamControllerDemo(context),
      'useValueChanged' => _useValueChangedDemo(),
      'useValueListenable' => _useValueListenableDemo(),
      'useValueNotifier' => _useValueNotifierDemo(),
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

  Component _useContextDemo() {
    useContext();
    return _output('Current hook BuildContext is available in this component.');
  }

  Component _useDebouncedDemo() {
    final ValueNotifier<int> input = useState<int>(0);
    final int? settled = useDebounced<int>(input.value, const Duration(milliseconds: 350));
    return _row(<Component>[
      _action('Change input', () => input.value++),
      _output('Input ${input.value} • settled ${settled ?? 'waiting…'}'),
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

  Component _useIsMountedDemo() {
    final IsMounted isMounted = useIsMounted();
    return _output('Mounted now: ${isMounted()}');
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

  Component _useOnPreferredColorSchemeChangeDemo() {
    final ValueNotifier<int> changes = useState<int>(0);
    final ObjectRef<String> transition = useRef<String>('No changes yet');
    useOnPreferredColorSchemeChange((PreferredColorScheme previous, PreferredColorScheme current) {
      transition.value = '${previous.name} → ${current.name}';
      changes.value++;
    });
    return _output('Scheme changes ${changes.value} • ${transition.value}. Change your OS theme to trigger it.');
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

  Component _usePreviousDemo() {
    final ValueNotifier<int> current = useState<int>(0);
    final int? previous = usePrevious<int>(current.value);
    return _row(<Component>[
      _action('Advance value', () => current.value++),
      _output('Current ${current.value} • previous ${previous ?? 'none'}'),
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

  Component _row(List<Component> children) => div(classes: 'hook-demo-row', children);

  Component _action(String label, VoidCallback onClick) {
    return button(
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
  ];
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
