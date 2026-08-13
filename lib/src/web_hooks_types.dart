import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

/// Resolves an event target after the browser has rendered the current frame.
typedef WebEventTargetResolver = web.EventTarget? Function();

/// Receives DOM mutations observed for a keyed node.
typedef WebMutationCallback = void Function(List<web.MutationRecord> records);

/// Receives the high-resolution timestamp for a browser animation frame.
typedef AnimationFrameCallback = void Function(Duration timestamp);

/// The current browser history entry.
@immutable
final class HistoryEntry {
  /// Creates a history entry snapshot.
  const HistoryEntry({required this.uri, this.state});

  /// The current document URI.
  final Uri uri;

  /// The structured-clone-compatible state associated with the entry.
  final Object? state;

  @override
  bool operator ==(Object other) => other is HistoryEntry && other.uri == uri && other.state == state;

  @override
  int get hashCode => Object.hash(uri, state);
}

/// Controls and observes the browser's same-document session history.
abstract interface class HistoryController {
  /// The current entry.
  HistoryEntry get entry;

  /// Adds a same-document history entry.
  void push(Uri uri, {Object? state});

  /// Replaces the current same-document history entry.
  void replace(Uri uri, {Object? state});

  /// Navigates backward by one entry.
  void back();

  /// Navigates forward by one entry.
  void forward();

  /// Navigates by [delta] entries.
  void go(int delta);
}

/// The latest clipboard operation performed by [ClipboardController].
enum ClipboardStatus { idle, reading, writing, success, error }

/// Reads and writes plain text through the browser Clipboard API.
abstract interface class ClipboardController {
  /// Whether the Clipboard API is available in the current browser context.
  bool get isSupported;

  /// The current operation status.
  ClipboardStatus get status;

  /// The most recently read or written text.
  String? get text;

  /// The most recent operation error.
  Object? get error;

  /// Reads plain text from the clipboard.
  Future<String> readText();

  /// Writes [value] to the clipboard.
  Future<void> writeText(String value);
}

/// The box measured by [web.ResizeObserver].
enum ResizeObserverBox { contentBox, borderBox, devicePixelContentBox }

/// A measured element size in the units reported for the selected observer box.
@immutable
final class ElementSize {
  /// Creates an element-size value.
  const ElementSize(this.width, this.height);

  /// The horizontal size.
  final double width;

  /// The vertical size.
  final double height;

  @override
  bool operator ==(Object other) => other is ElementSize && other.width == width && other.height == height;

  @override
  int get hashCode => Object.hash(width, height);

  @override
  String toString() => 'ElementSize(width: $width, height: $height)';
}

/// The browser viewport size in CSS pixels.
@immutable
final class WindowSize {
  /// Creates a viewport-size value.
  const WindowSize(this.width, this.height);

  /// The viewport width.
  final double width;

  /// The viewport height.
  final double height;

  @override
  bool operator ==(Object other) => other is WindowSize && other.width == width && other.height == height;

  @override
  int get hashCode => Object.hash(width, height);

  @override
  String toString() => 'WindowSize(width: $width, height: $height)';
}

/// Configuration for viewport-size updates.
@immutable
final class WindowSizeOptions {
  /// Creates viewport-size options.
  const WindowSizeOptions({this.debounce});

  /// Delays resize updates until browser events have settled.
  final Duration? debounce;

  @override
  bool operator ==(Object other) => other is WindowSizeOptions && other.debounce == debounce;

  @override
  int get hashCode => debounce.hashCode;
}

/// The latest intersection state for a keyed element.
@immutable
final class IntersectionSnapshot {
  /// Creates an intersection snapshot.
  const IntersectionSnapshot({required this.isIntersecting, required this.ratio});

  /// Whether the target currently intersects its root.
  final bool isIntersecting;

  /// The visible proportion of the target from zero to one.
  final double ratio;

  @override
  bool operator ==(Object other) {
    return other is IntersectionSnapshot && other.isIntersecting == isIntersecting && other.ratio == ratio;
  }

  @override
  int get hashCode => Object.hash(isIntersecting, ratio);

  @override
  String toString() => 'IntersectionSnapshot(isIntersecting: $isIntersecting, ratio: $ratio)';
}

/// Configuration for an intersection observer.
@immutable
final class IntersectionOptions {
  /// Creates intersection options.
  const IntersectionOptions({
    this.root,
    this.rootMargin = '0px',
    this.thresholds = const <double>[0],
    this.freezeOnceVisible = false,
  });

  /// A keyed element used as the intersection root, or null for the viewport.
  final GlobalNodeKey<web.Element>? root;

  /// A CSS margin applied to the root bounds.
  final String rootMargin;

  /// Ratios at which the observer publishes changes.
  final List<double> thresholds;

  /// Stops observation after the target first becomes visible.
  final bool freezeOnceVisible;

  @override
  bool operator ==(Object other) {
    return other is IntersectionOptions &&
        identical(other.root, root) &&
        other.rootMargin == rootMargin &&
        _listsEqual(other.thresholds, thresholds) &&
        other.freezeOnceVisible == freezeOnceVisible;
  }

  @override
  int get hashCode => Object.hash(root, rootMargin, Object.hashAll(thresholds), freezeOnceVisible);
}

/// Native DOM event-listener options.
@immutable
final class WebEventListenerOptions {
  /// Creates event-listener options.
  const WebEventListenerOptions({this.capture = false, this.passive = false, this.once = false});

  /// Receives the event during the capture phase.
  final bool capture;

  /// Declares that the listener does not call `preventDefault`.
  final bool passive;

  /// Removes the native listener after its first event.
  final bool once;

  @override
  bool operator ==(Object other) {
    return other is WebEventListenerOptions &&
        other.capture == capture &&
        other.passive == passive &&
        other.once == once;
  }

  @override
  int get hashCode => Object.hash(capture, passive, once);
}

/// Configuration for a DOM mutation observer.
@immutable
final class MutationObserverOptions {
  /// Creates mutation-observer options.
  const MutationObserverOptions({
    this.childList = true,
    this.attributes = false,
    this.characterData = false,
    this.subtree = false,
    this.attributeOldValue = false,
    this.characterDataOldValue = false,
    this.attributeFilter,
  });

  /// Observes direct child additions and removals.
  final bool childList;

  /// Observes attribute changes.
  final bool attributes;

  /// Observes text-node changes.
  final bool characterData;

  /// Extends observation to descendants.
  final bool subtree;

  /// Includes the previous attribute value in mutation records.
  final bool attributeOldValue;

  /// Includes the previous text value in mutation records.
  final bool characterDataOldValue;

  /// Limits attribute observation to these names.
  final List<String>? attributeFilter;

  /// Whether the options observe at least one mutation category.
  bool get isValid {
    return childList ||
        attributes ||
        characterData ||
        attributeOldValue ||
        characterDataOldValue ||
        attributeFilter != null;
  }

  @override
  bool operator ==(Object other) {
    return other is MutationObserverOptions &&
        other.childList == childList &&
        other.attributes == attributes &&
        other.characterData == characterData &&
        other.subtree == subtree &&
        other.attributeOldValue == attributeOldValue &&
        other.characterDataOldValue == characterDataOldValue &&
        _nullableListsEqual(other.attributeFilter, attributeFilter);
  }

  @override
  int get hashCode {
    return Object.hash(
      childList,
      attributes,
      characterData,
      subtree,
      attributeOldValue,
      characterDataOldValue,
      attributeFilter == null ? null : Object.hashAll(attributeFilter!),
    );
  }
}

bool _listsEqual<T>(List<T> left, List<T> right) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

bool _nullableListsEqual<T>(List<T>? left, List<T>? right) {
  if (left == null || right == null) return left == right;
  return _listsEqual(left, right);
}
