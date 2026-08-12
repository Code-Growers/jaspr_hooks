// dart format off
// ignore_for_file: type=lint

// GENERATED FILE, DO NOT MODIFY
// Generated with jaspr_builder

import 'package:jaspr/server.dart';
import 'package:jaspr_content/components/callout.dart' as _callout;
import 'package:jaspr_content/components/sidebar_toggle_button.dart'
    as _sidebar_toggle_button;
import 'package:jaspr_content/components/theme_toggle.dart' as _theme_toggle;
import 'package:jaspr_hooks_example/components/hook_demo.dart' as _hook_demo;

/// Default [ServerOptions] for use with your Jaspr project.
///
/// Use this to initialize Jaspr **before** calling [runApp].
///
/// Example:
/// ```dart
/// import 'main.server.options.dart';
///
/// void main() {
///   Jaspr.initializeApp(
///     options: defaultServerOptions,
///   );
///
///   runApp(...);
/// }
/// ```
ServerOptions get defaultServerOptions => ServerOptions(
  clientId: 'main.client.dart.js',
  clients: {
    _sidebar_toggle_button.SidebarToggleButton:
        ClientTarget<_sidebar_toggle_button.SidebarToggleButton>(
          'jaspr_content:sidebar_toggle_button',
        ),
    _theme_toggle.ThemeToggle: ClientTarget<_theme_toggle.ThemeToggle>(
      'jaspr_content:theme_toggle',
    ),
    _hook_demo.HookDemo: ClientTarget<_hook_demo.HookDemo>(
      'hook_demo',
      params: __hook_demoHookDemo,
    ),
  },
  styles: () => [
    ..._callout.Callout.styles,
    ..._theme_toggle.ThemeToggleState.styles,
    ..._hook_demo.HookDemo.styles,
  ],
);

Map<String, Object?> __hook_demoHookDemo(_hook_demo.HookDemo c) => {
  'name': c.name,
};
