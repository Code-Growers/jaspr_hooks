import 'web_lifecycle_types.dart';

abstract interface class LifecycleSubscription {
  void cancel();
}

DocumentVisibility readDocumentVisibility() => DocumentVisibility.unknown;

LifecycleSubscription? watchDocumentVisibility(void Function(DocumentVisibility value) callback) => null;

PreferredColorScheme readPreferredColorScheme() => PreferredColorScheme.unknown;

LifecycleSubscription? watchPreferredColorScheme(void Function(PreferredColorScheme value) callback) => null;
