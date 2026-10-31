import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_hooks/jaspr_hooks.dart';

/// Receives a list of server components and can unmount them once.
@client
class ServerCompositionControls extends HookComponent {
  const ServerCompositionControls({required this.cards, super.key});

  final List<Component> cards;

  @override
  Component build(BuildContext context) {
    final mounted = useState(true);
    return div(
      attributes: {'data-server-composition': 'demo'},
      [
        button(
          attributes: {if (!mounted.value) 'disabled': ''},
          onClick: () => mounted.value = false,
          [const Component.text('Remove cards')],
        ),
        if (mounted.value) ...cards else const Component.text('Cards removed. Reload the page to restore them.'),
      ],
    );
  }
}
