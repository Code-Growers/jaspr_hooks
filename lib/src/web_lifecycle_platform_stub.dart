import 'web_lifecycle_types.dart';

abstract interface class LifecycleSubscription {
  void cancel();
}

final class LifecycleObservation<T> {
  const LifecycleObservation(this.value, this.subscription);

  final T value;
  final LifecycleSubscription? subscription;
}

DocumentVisibility readDocumentVisibility() => DocumentVisibility.unknown;

LifecycleSubscription? watchDocumentVisibility(void Function(DocumentVisibility value) callback) => null;

LifecycleObservation<DocumentVisibility> observeDocumentVisibility(
  void Function(DocumentVisibility value) callback,
) => const LifecycleObservation(DocumentVisibility.unknown, null);

PreferredColorScheme readPreferredColorScheme() => PreferredColorScheme.unknown;

LifecycleSubscription? watchPreferredColorScheme(void Function(PreferredColorScheme value) callback) => null;

LifecycleObservation<PreferredColorScheme> observePreferredColorScheme(
  void Function(PreferredColorScheme value) callback,
) => const LifecycleObservation(PreferredColorScheme.unknown, null);

MediaQueryMatch readMediaQuery(String query) => MediaQueryMatch.unknown;

LifecycleSubscription? watchMediaQuery(String query, void Function(MediaQueryMatch value) callback) => null;

LifecycleObservation<MediaQueryMatch> observeMediaQuery(
  String query,
  void Function(MediaQueryMatch value) callback,
) => const LifecycleObservation(MediaQueryMatch.unknown, null);
