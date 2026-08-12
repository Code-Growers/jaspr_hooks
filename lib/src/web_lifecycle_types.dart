/// Whether the browser document is currently visible.
enum DocumentVisibility { unknown, visible, hidden }

/// The browser's preferred light or dark color scheme.
enum PreferredColorScheme { unknown, light, dark }

/// Callback invoked after an established document visibility value changes.
typedef DocumentVisibilityCallback =
    void Function(
      DocumentVisibility previous,
      DocumentVisibility current,
    );

/// Callback invoked after an established preferred color scheme changes.
typedef PreferredColorSchemeCallback =
    void Function(
      PreferredColorScheme previous,
      PreferredColorScheme current,
    );
