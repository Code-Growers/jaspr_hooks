// dart format off
// ignore_for_file: type=lint

// GENERATED FILE, DO NOT MODIFY
// Generated with jaspr_builder

import 'package:jaspr/client.dart';

import 'package:jaspr_content/components/sidebar_toggle_button.dart'
    deferred as _sidebar_toggle_button;
import 'package:jaspr_content/components/theme_toggle.dart'
    deferred as _theme_toggle;
import 'package:jaspr_hooks_example/components/ai_install_prompt.dart'
    deferred as _ai_install_prompt;
import 'package:jaspr_hooks_example/components/expandable_card.dart'
    deferred as _expandable_card;
import 'package:jaspr_hooks_example/components/hook_demo.dart'
    deferred as _hook_demo;
import 'package:jaspr_hooks_example/components/server_composition_controls.dart'
    deferred as _server_composition_controls;
import 'package:jaspr_hooks_example/components/server_counter.dart'
    deferred as _server_counter;

/// Default [ClientOptions] for use with your Jaspr project.
///
/// Use this to initialize Jaspr **before** calling [runApp].
///
/// Example:
/// ```dart
/// import 'main.client.options.dart';
///
/// void main() {
///   Jaspr.initializeApp(
///     options: defaultClientOptions,
///   );
///
///   runApp(...);
/// }
/// ```
ClientOptions get defaultClientOptions => ClientOptions(
  clients: {
    'jaspr_content:sidebar_toggle_button': ClientLoader(
      (p) => _sidebar_toggle_button.SidebarToggleButton(),
      loader: _sidebar_toggle_button.loadLibrary,
    ),
    'jaspr_content:theme_toggle': ClientLoader(
      (p) => _theme_toggle.ThemeToggle(),
      loader: _theme_toggle.loadLibrary,
    ),
    'ai_install_prompt': ClientLoader(
      (p) => _ai_install_prompt.AiInstallPrompt(),
      loader: _ai_install_prompt.loadLibrary,
    ),
    'expandable_card': ClientLoader(
      (p) => _expandable_card.ExpandableCard(
        idScope: p.get<String>('idScope'),
        title: p.get<String>('title'),
        content: p.mount(p.get<String>('content')),
      ),
      loader: _expandable_card.loadLibrary,
    ),
    'hook_demo': ClientLoader(
      (p) => _hook_demo.HookDemo(name: p.get<String>('name')),
      loader: _hook_demo.loadLibrary,
    ),
    'server_composition_controls': ClientLoader(
      (p) => _server_composition_controls.ServerCompositionControls(
        cards: p
            .get<List<Object?>>('cards')
            .cast<String>()
            .map((i) => p.mount(i))
            .toList(),
      ),
      loader: _server_composition_controls.loadLibrary,
    ),
    'server_counter': ClientLoader(
      (p) => _server_counter.ServerCounter(idScope: p.get<String>('idScope')),
      loader: _server_counter.loadLibrary,
    ),
  },
);
