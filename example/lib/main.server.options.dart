// dart format off
// ignore_for_file: type=lint

// GENERATED FILE, DO NOT MODIFY
// Generated with jaspr_builder

import 'package:jaspr/server.dart';
import 'package:jaspr_content/components/callout.dart' as _callout;
import 'package:jaspr_content/components/sidebar_toggle_button.dart'
    as _sidebar_toggle_button;
import 'package:jaspr_content/components/theme_toggle.dart' as _theme_toggle;
import 'package:jaspr_hooks_example/components/ai_install_prompt.dart'
    as _ai_install_prompt;
import 'package:jaspr_hooks_example/components/expandable_card.dart'
    as _expandable_card;
import 'package:jaspr_hooks_example/components/hook_demo.dart' as _hook_demo;
import 'package:jaspr_hooks_example/components/server_composition_controls.dart'
    as _server_composition_controls;
import 'package:jaspr_hooks_example/components/server_counter.dart'
    as _server_counter;

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
    _ai_install_prompt.AiInstallPrompt:
        ClientTarget<_ai_install_prompt.AiInstallPrompt>('ai_install_prompt'),
    _expandable_card.ExpandableCard:
        ClientTarget<_expandable_card.ExpandableCard>(
          'expandable_card',
          params: __expandable_cardExpandableCard,
        ),
    _hook_demo.HookDemo: ClientTarget<_hook_demo.HookDemo>(
      'hook_demo',
      params: __hook_demoHookDemo,
    ),
    _server_composition_controls.ServerCompositionControls:
        ClientTarget<_server_composition_controls.ServerCompositionControls>(
          'server_composition_controls',
          params: __server_composition_controlsServerCompositionControls,
        ),
    _server_counter.ServerCounter: ClientTarget<_server_counter.ServerCounter>(
      'server_counter',
      params: __server_counterServerCounter,
    ),
  },
  styles: () => [
    ..._callout.Callout.styles,
    ..._theme_toggle.ThemeToggleState.styles,
    ..._ai_install_prompt.AiInstallPrompt.styles,
    ..._hook_demo.HookDemo.styles,
  ],
);

Map<String, Object?> __expandable_cardExpandableCard(
  _expandable_card.ExpandableCard c,
) => {'idScope': c.idScope, 'title': c.title, 'content': c.content};
Map<String, Object?> __hook_demoHookDemo(_hook_demo.HookDemo c) => {
  'name': c.name,
};
Map<String, Object?> __server_composition_controlsServerCompositionControls(
  _server_composition_controls.ServerCompositionControls c,
) => {'cards': c.cards};
Map<String, Object?> __server_counterServerCounter(
  _server_counter.ServerCounter c,
) => {'idScope': c.idScope};
