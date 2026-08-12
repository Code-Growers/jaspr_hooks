/// Whether the browser document is currently visible.
enum DocumentVisibility { unknown, visible, hidden }

/// The browser's preferred light or dark color scheme.
enum PreferredColorScheme { unknown, light, dark }

/// Whether the browser currently matches a CSS media query.
enum MediaQueryMatch { unknown, matches, doesNotMatch }

/// The browser's preferred animation and transition behavior.
enum PreferredMotion { unknown, reduce, noPreference }

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

/// Callback invoked after an established media-query result changes.
typedef MediaQueryCallback = void Function(MediaQueryMatch previous, MediaQueryMatch current);

/// Callback invoked after an established preferred-motion value changes.
typedef PreferredMotionCallback = void Function(PreferredMotion previous, PreferredMotion current);
