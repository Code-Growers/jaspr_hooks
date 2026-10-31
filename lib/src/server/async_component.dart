import 'dart:async';

import 'package:jaspr/server.dart';

import '../framework.dart';

/// An experimental server-only component that may call hooks across awaits.
///
/// Call hooks in a deterministic, sequential order directly in [build] or its
/// awaited helpers. Parallel branches, detached work, event handlers, and timer
/// callbacks must not call hooks. Closed builds reject escaped hook calls.
/// Effects remain inactive and live Future/Stream sources remain unsupported
/// on the server. State is local to this element and is not serialized.
///
/// Failed builds release their hook resources. Successful builds retain them
/// until unmount; HTTP response completion does not guarantee unmount. Manage
/// request resources and async cleanup explicitly with `try`/`finally`.
abstract class AsyncHookComponent extends AsyncStatelessComponent {
  /// Creates an async hook component. Do not annotate it with `@client`.
  const AsyncHookComponent({super.key});

  @override
  Element createElement() => _AsyncHookElement(this);

  /// Builds the server subtree, optionally calling hooks before and after await.
  @override
  @protected
  Future<Component> build(BuildContext context);

  Future<Component> _build(BuildContext context) => build(context);
}

/// An experimental callback-based [AsyncHookComponent].
class AsyncHookBuilder extends AsyncHookComponent {
  /// Creates a server-only async hook builder.
  const AsyncHookBuilder({required this.builder, super.key});

  /// Builds the subtree with sequential hooks and awaited server work.
  final Future<Component> Function(BuildContext context) builder;

  @override
  Future<Component> build(BuildContext context) => builder(context);
}

class _AsyncHookElement extends BuildableElement with HookElement {
  _AsyncHookElement(AsyncHookComponent super.component);

  Component _built = const Component.empty();
  Future<void>? _rebuilding;
  bool _rebuildAgain = false;

  @override
  bool get isAsyncHookElement => true;

  @override
  Component build() => _built;

  @override
  Future<void> performRebuild() {
    if (isHookUnmounted) return Future<void>.value();
    final rebuilding = _rebuilding;
    if (rebuilding != null) {
      _rebuildAgain = true;
      return rebuilding;
    }
    final completer = Completer<void>();
    _rebuilding = completer.future;
    unawaited(
      _driveRebuilds().then(
        (_) {
          _rebuilding = null;
          completer.complete();
        },
        onError: (Object error, StackTrace stackTrace) {
          _rebuilding = null;
          completer.completeError(error, stackTrace);
        },
      ),
    );
    return completer.future;
  }

  Future<void> _driveRebuilds() async {
    do {
      _rebuildAgain = false;
      try {
        final configuration = component as AsyncHookComponent;
        final built = await runAsyncHookBuild(() => configuration._build(this));
        if (isHookUnmounted) return;
        if (_rebuildAgain) continue;
        _built = built;
        super.performRebuild();
      } catch (error, stackTrace) {
        if (isHookUnmounted) return;
        // Reconcile to an empty subtree so a failed replacement also unmounts
        // previous children. Jaspr's failure helper only drops its child field.
        _built = const Component.empty();
        super.performRebuild();
        binding.reportBuildError(this, error, stackTrace);
        return;
      }
    } while (_rebuildAgain);
  }

  @override
  void didRebuild() {
    if (!isHookUnmounted) super.didRebuild();
  }
}
