import 'dart:collection';

import 'package:jaspr/jaspr.dart';

import 'framework.dart';
import 'primitives.dart';

/// Mutable boolean state returned by [useToggle].
abstract interface class ToggleController {
  /// The current boolean value.
  bool get value;

  /// Replaces [value] when it differs from the current value.
  void setValue(bool value);

  /// Inverts [value].
  void toggle();

  /// Restores the value passed to [useToggle].
  void reset();
}

/// Creates stable boolean state with toggle and reset operations.
ToggleController useToggle([bool initialValue = false]) {
  return use(_ToggleHook(initialValue));
}

final class _ToggleHook extends Hook<ToggleController> {
  const _ToggleHook(this.initialValue);

  final bool initialValue;

  @override
  _ToggleHookState createState() => _ToggleHookState();
}

final class _ToggleHookState extends HookState<ToggleController, _ToggleHook> implements ToggleController {
  late final bool _initialValue;
  late bool _value;

  @override
  void initHook() {
    _initialValue = hook.initialValue;
    _value = _initialValue;
  }

  @override
  bool get value => _value;

  @override
  void setValue(bool value) {
    _ensureMounted();
    if (_value == value) {
      return;
    }
    setState(() => _value = value);
  }

  @override
  void toggle() {
    _ensureMounted();
    setState(() => _value = !_value);
  }

  @override
  void reset() => setValue(_initialValue);

  @override
  ToggleController build(BuildContext context) => this;

  void _ensureMounted() {
    if (!mounted) {
      throw StateError('ToggleController used after its hook was disposed.');
    }
  }
}

/// Mutable integer state returned by [useCounter].
abstract interface class CounterController {
  /// The current counter value.
  int get value;

  /// Adds [amount] to [value].
  void increment([int amount = 1]);

  /// Subtracts [amount] from [value].
  void decrement([int amount = 1]);

  /// Replaces [value] when it differs from the current value.
  void setValue(int value);

  /// Restores the value passed to [useCounter].
  void reset();
}

/// Creates stable integer state with increment, decrement, and reset operations.
CounterController useCounter([int initialValue = 0]) {
  return use(_CounterHook(initialValue));
}

final class _CounterHook extends Hook<CounterController> {
  const _CounterHook(this.initialValue);

  final int initialValue;

  @override
  _CounterHookState createState() => _CounterHookState();
}

final class _CounterHookState extends HookState<CounterController, _CounterHook> implements CounterController {
  late final int _initialValue;
  late int _value;

  @override
  void initHook() {
    _initialValue = hook.initialValue;
    _value = _initialValue;
  }

  @override
  int get value => _value;

  @override
  void increment([int amount = 1]) {
    _ensureMounted();
    if (amount == 0) {
      return;
    }
    setState(() => _value += amount);
  }

  @override
  void decrement([int amount = 1]) {
    _ensureMounted();
    if (amount == 0) {
      return;
    }
    setState(() => _value -= amount);
  }

  @override
  void setValue(int value) {
    _ensureMounted();
    if (_value == value) {
      return;
    }
    setState(() => _value = value);
  }

  @override
  void reset() => setValue(_initialValue);

  @override
  CounterController build(BuildContext context) => this;

  void _ensureMounted() {
    if (!mounted) {
      throw StateError('CounterController used after its hook was disposed.');
    }
  }
}

/// Mutable list state returned by [useList].
abstract interface class ListController<T> {
  /// An unmodifiable live view of the current values.
  List<T> get value;

  /// Appends [item].
  void add(T item);

  /// Appends [items], skipping the update when [items] is empty.
  void addAll(Iterable<T> items);

  /// Inserts [item] at [index].
  void insert(int index, T item);

  /// Inserts [items] at [index], skipping the update when [items] is empty.
  void insertAll(int index, Iterable<T> items);

  /// Replaces the value at [index] when it differs from [item].
  void setAt(int index, T item);

  /// Removes the first occurrence of [item] and reports whether it was found.
  bool remove(T item);

  /// Removes and returns the value at [index].
  T removeAt(int index);

  /// Replaces all values when their ordered contents differ.
  void replaceAll(Iterable<T> items);

  /// Removes every value, skipping the update when already empty.
  void clear();
}

/// Creates stable list state initialized with a snapshot of [initialValue].
ListController<T> useList<T>([Iterable<T> initialValue = const <Never>[]]) {
  return use(_ListHook<T>(initialValue));
}

final class _ListHook<T> extends Hook<ListController<T>> {
  const _ListHook(this.initialValue);

  final Iterable<T> initialValue;

  @override
  _ListHookState<T> createState() => _ListHookState<T>();
}

final class _ListHookState<T> extends HookState<ListController<T>, _ListHook<T>> implements ListController<T> {
  late final List<T> _items;
  late final List<T> _view;

  @override
  void initHook() {
    _items = List<T>.of(hook.initialValue);
    _view = UnmodifiableListView<T>(_items);
  }

  @override
  List<T> get value => _view;

  @override
  void add(T item) {
    _ensureMounted();
    setState(() => _items.add(item));
  }

  @override
  void addAll(Iterable<T> items) {
    _ensureMounted();
    final additions = List<T>.of(items);
    if (additions.isEmpty) {
      return;
    }
    setState(() => _items.addAll(additions));
  }

  @override
  void insert(int index, T item) {
    _ensureMounted();
    setState(() => _items.insert(index, item));
  }

  @override
  void insertAll(int index, Iterable<T> items) {
    _ensureMounted();
    final additions = List<T>.of(items);
    if (additions.isEmpty) {
      return;
    }
    setState(() => _items.insertAll(index, additions));
  }

  @override
  void setAt(int index, T item) {
    _ensureMounted();
    if (_items[index] == item) {
      return;
    }
    setState(() => _items[index] = item);
  }

  @override
  bool remove(T item) {
    _ensureMounted();
    final index = _items.indexOf(item);
    if (index == -1) {
      return false;
    }
    setState(() => _items.removeAt(index));
    return true;
  }

  @override
  T removeAt(int index) {
    _ensureMounted();
    final removed = _items[index];
    setState(() => _items.removeAt(index));
    return removed;
  }

  @override
  void replaceAll(Iterable<T> items) {
    _ensureMounted();
    final replacement = List<T>.of(items);
    if (_orderedEquals(_items, replacement)) {
      return;
    }
    setState(() {
      _items
        ..clear()
        ..addAll(replacement);
    });
  }

  @override
  void clear() {
    _ensureMounted();
    if (_items.isEmpty) {
      return;
    }
    setState(_items.clear);
  }

  @override
  ListController<T> build(BuildContext context) => this;

  void _ensureMounted() {
    if (!mounted) {
      throw StateError('ListController used after its hook was disposed.');
    }
  }
}

/// Mutable map state returned by [useMap].
abstract interface class MapController<K, V> {
  /// An unmodifiable live view of the current entries.
  Map<K, V> get value;

  /// Associates [key] with [value] when that entry differs.
  void setValue(K key, V value);

  /// Adds or replaces [entries], skipping the update when every entry matches.
  void setAll(Map<K, V> entries);

  /// Removes [key] and returns its previous value, or `null` when absent.
  V? remove(K key);

  /// Replaces all entries when their contents differ.
  void replaceAll(Map<K, V> entries);

  /// Removes every entry, skipping the update when already empty.
  void clear();
}

/// Creates stable map state initialized with a snapshot of [initialValue].
MapController<K, V> useMap<K, V>([Map<K, V> initialValue = const <Never, Never>{}]) {
  return use(_MapHook<K, V>(initialValue));
}

final class _MapHook<K, V> extends Hook<MapController<K, V>> {
  const _MapHook(this.initialValue);

  final Map<K, V> initialValue;

  @override
  _MapHookState<K, V> createState() => _MapHookState<K, V>();
}

final class _MapHookState<K, V> extends HookState<MapController<K, V>, _MapHook<K, V>> implements MapController<K, V> {
  late final Map<K, V> _items;
  late final Map<K, V> _view;

  @override
  void initHook() {
    _items = Map<K, V>.of(hook.initialValue);
    _view = UnmodifiableMapView<K, V>(_items);
  }

  @override
  Map<K, V> get value => _view;

  @override
  void setValue(K key, V value) {
    _ensureMounted();
    if (_items.containsKey(key) && _items[key] == value) {
      return;
    }
    setState(() => _items[key] = value);
  }

  @override
  void setAll(Map<K, V> entries) {
    _ensureMounted();
    if (entries.entries.every((entry) => _items.containsKey(entry.key) && _items[entry.key] == entry.value)) {
      return;
    }
    setState(() => _items.addAll(entries));
  }

  @override
  V? remove(K key) {
    _ensureMounted();
    if (!_items.containsKey(key)) {
      return null;
    }
    final removed = _items[key];
    setState(() => _items.remove(key));
    return removed;
  }

  @override
  void replaceAll(Map<K, V> entries) {
    _ensureMounted();
    if (_mapEquals(_items, entries)) {
      return;
    }
    final replacement = Map<K, V>.of(entries);
    setState(() {
      _items
        ..clear()
        ..addAll(replacement);
    });
  }

  @override
  void clear() {
    _ensureMounted();
    if (_items.isEmpty) {
      return;
    }
    setState(_items.clear);
  }

  @override
  MapController<K, V> build(BuildContext context) => this;

  void _ensureMounted() {
    if (!mounted) {
      throw StateError('MapController used after its hook was disposed.');
    }
  }
}

/// Mutable set state returned by [useSet].
abstract interface class SetController<T> {
  /// An unmodifiable live view of the current values.
  Set<T> get value;

  /// Adds [item] and reports whether the set changed.
  bool add(T item);

  /// Adds [items], skipping the update when every value already exists.
  void addAll(Iterable<T> items);

  /// Removes [item] and reports whether the set changed.
  bool remove(T item);

  /// Replaces all values when their contents differ.
  void replaceAll(Iterable<T> items);

  /// Removes every value, skipping the update when already empty.
  void clear();
}

/// Creates stable set state initialized with a snapshot of [initialValue].
SetController<T> useSet<T>([Iterable<T> initialValue = const <Never>[]]) {
  return use(_SetHook<T>(initialValue));
}

final class _SetHook<T> extends Hook<SetController<T>> {
  const _SetHook(this.initialValue);

  final Iterable<T> initialValue;

  @override
  _SetHookState<T> createState() => _SetHookState<T>();
}

final class _SetHookState<T> extends HookState<SetController<T>, _SetHook<T>> implements SetController<T> {
  late final Set<T> _items;
  late final Set<T> _view;

  @override
  void initHook() {
    _items = Set<T>.of(hook.initialValue);
    _view = UnmodifiableSetView<T>(_items);
  }

  @override
  Set<T> get value => _view;

  @override
  bool add(T item) {
    _ensureMounted();
    if (_items.contains(item)) {
      return false;
    }
    setState(() => _items.add(item));
    return true;
  }

  @override
  void addAll(Iterable<T> items) {
    _ensureMounted();
    final additions = Set<T>.of(items)..removeAll(_items);
    if (additions.isEmpty) {
      return;
    }
    setState(() => _items.addAll(additions));
  }

  @override
  bool remove(T item) {
    _ensureMounted();
    if (!_items.contains(item)) {
      return false;
    }
    setState(() => _items.remove(item));
    return true;
  }

  @override
  void replaceAll(Iterable<T> items) {
    _ensureMounted();
    final replacement = Set<T>.of(items);
    if (_setEquals(_items, replacement)) {
      return;
    }
    setState(() {
      _items
        ..clear()
        ..addAll(replacement);
    });
  }

  @override
  void clear() {
    _ensureMounted();
    if (_items.isEmpty) {
      return;
    }
    setState(_items.clear);
  }

  @override
  SetController<T> build(BuildContext context) => this;

  void _ensureMounted() {
    if (!mounted) {
      throw StateError('SetController used after its hook was disposed.');
    }
  }
}

/// Mutable first-in, first-out state returned by [useQueue].
abstract interface class QueueController<T> {
  /// An unmodifiable live view ordered from the front to the back.
  List<T> get value;

  /// The number of queued values.
  int get length;

  /// Whether the queue contains no values.
  bool get isEmpty;

  /// Whether the queue contains at least one value.
  bool get isNotEmpty;

  /// Adds [item] to the back of the queue.
  void enqueue(T item);

  /// Adds [items] to the back, skipping the update when [items] is empty.
  void enqueueAll(Iterable<T> items);

  /// Removes and returns the front value.
  ///
  /// Throws a [StateError] when the queue is empty.
  T dequeue();

  /// Replaces the queue when its ordered contents differ.
  void replaceAll(Iterable<T> items);

  /// Removes every value, skipping the update when already empty.
  void clear();
}

/// Creates stable queue state initialized with a snapshot of [initialValue].
QueueController<T> useQueue<T>([Iterable<T> initialValue = const <Never>[]]) {
  return use(_QueueHook<T>(initialValue));
}

final class _QueueHook<T> extends Hook<QueueController<T>> {
  const _QueueHook(this.initialValue);

  final Iterable<T> initialValue;

  @override
  _QueueHookState<T> createState() => _QueueHookState<T>();
}

final class _QueueHookState<T> extends HookState<QueueController<T>, _QueueHook<T>> implements QueueController<T> {
  late final List<T> _items;
  late final List<T> _view;

  @override
  void initHook() {
    _items = List<T>.of(hook.initialValue);
    _view = UnmodifiableListView<T>(_items);
  }

  @override
  List<T> get value => _view;

  @override
  int get length => _items.length;

  @override
  bool get isEmpty => _items.isEmpty;

  @override
  bool get isNotEmpty => _items.isNotEmpty;

  @override
  void enqueue(T item) {
    _ensureMounted();
    setState(() => _items.add(item));
  }

  @override
  void enqueueAll(Iterable<T> items) {
    _ensureMounted();
    final additions = List<T>.of(items);
    if (additions.isEmpty) {
      return;
    }
    setState(() => _items.addAll(additions));
  }

  @override
  T dequeue() {
    _ensureMounted();
    if (_items.isEmpty) {
      throw StateError('Cannot dequeue an empty queue.');
    }
    final removed = _items.first;
    setState(() => _items.removeAt(0));
    return removed;
  }

  @override
  void replaceAll(Iterable<T> items) {
    _ensureMounted();
    final replacement = List<T>.of(items);
    if (_orderedEquals(_items, replacement)) {
      return;
    }
    setState(() {
      _items
        ..clear()
        ..addAll(replacement);
    });
  }

  @override
  void clear() {
    _ensureMounted();
    if (_items.isEmpty) {
      return;
    }
    setState(_items.clear);
  }

  @override
  QueueController<T> build(BuildContext context) => this;

  void _ensureMounted() {
    if (!mounted) {
      throw StateError('QueueController used after its hook was disposed.');
    }
  }
}

/// Runs [effect] during the hook's first browser-client build.
///
/// The effect and its cleanup are skipped during server and static rendering.
void useEffectOnce(Dispose? Function() effect) {
  useEffect(effect, const <Object?>[]);
}

/// Runs [effect] during the hook's first browser-client build.
///
/// This is a cleanup-free form of [useEffectOnce]. It is skipped during server
/// and static rendering.
void useMount(VoidCallback effect) {
  useEffectOnce(() {
    effect();
    return null;
  });
}

/// Runs [effect] when the hook is removed from a browser-client component.
///
/// The latest supplied callback is used. The callback is skipped during server
/// and static rendering.
void useUnmount(VoidCallback effect) {
  final latestEffect = useRef(effect)..value = effect;
  useEffectOnce(() {
    return () => latestEffect.value();
  });
}

/// Runs [effect] during updates while skipping the initial client build.
///
/// With omitted [keys], it runs after every subsequent client build. With
/// keys, it runs when their ordered contents change. Effects and cleanups are
/// skipped during server and static rendering.
void useUpdateEffect(Dispose? Function() effect, [List<Object?>? keys]) {
  final isInitialBuild = useRef(true);
  useEffect(() {
    if (isInitialBuild.value) {
      isInitialBuild.value = false;
      return null;
    }
    return effect();
  }, keys);
}

/// Runs [effect] after a completed browser frame for updates, skipping the
/// frame that mounted the hook.
///
/// With omitted [keys], it runs after every later client frame. With keys, it
/// runs after the frame in which their ordered contents changed. Effects and
/// cleanups are skipped during server and static rendering.
void usePostFrameUpdateEffect(Dispose? Function() effect, [List<Object?>? keys]) {
  final isInitialRun = useRef(true);
  usePostFrameEffect(() {
    if (isInitialRun.value) {
      isInitialRun.value = false;
      return null;
    }
    return effect();
  }, keys);
}

bool _orderedEquals<T>(List<T> left, List<T> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}

bool _mapEquals<K, V>(Map<K, V> left, Map<K, V> right) {
  return left.length == right.length &&
      left.entries.every((entry) => right.containsKey(entry.key) && right[entry.key] == entry.value);
}

bool _setEquals<T>(Set<T> left, Set<T> right) {
  return left.length == right.length && left.containsAll(right);
}
