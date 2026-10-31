import 'dart:io';

import 'package:jaspr/dom.dart';
import 'package:jaspr/server.dart';
import 'package:jaspr_hooks/jaspr_hooks.dart';

import 'expandable_card.dart';
import 'server_composition_controls.dart';
import 'server_counter.dart';

/// File loading stays in server scope, outside the generated client bundle.
class ServerCompositionDemo extends AsyncStatelessComponent {
  const ServerCompositionDemo({super.key});

  @override
  Future<Component> build(BuildContext context) async {
    final message = await File('data/server-message.txt').readAsString();
    return ServerCompositionControls(
      cards: [
        for (final title in ['First card', 'Second card'])
          ExpandableCard(
            idScope: 'composition-$title',
            title: title,
            content: HookIdScope(
              seed: 'server-content-$title',
              child: HookBuilder(
                builder: (_) {
                  final formatted = useMemoized(() => message.trim());
                  final id = useId(prefix: 'server-message');
                  return div(
                    attributes: {'data-server-content': title},
                    [
                      p(id: id, [Component.text(formatted)]),
                      ServerCounter(idScope: 'nested-$title'),
                    ],
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
