/// Router-neutral guard registry. Apps call [canLeave] before route or dialog
/// changes and install their browser unload/history adapter at the app shell.
class FormNavigationGuard {
  final _blockers = <Object, bool Function()>{};
  bool get isBlocked => _blockers.values.any((blocked) => blocked());
  void Function() register(bool Function() blocked) {
    final token = Object();
    _blockers[token] = blocked;
    return () => _blockers.remove(token);
  }

  bool canLeave(bool Function() confirmDiscard) => !isBlocked || confirmDiscard();
}
