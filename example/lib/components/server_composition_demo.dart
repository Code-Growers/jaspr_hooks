import 'dart:io';

import 'package:jaspr/dom.dart';
import 'package:jaspr/server.dart';
import 'package:jaspr_hooks/server.dart';

import 'expandable_card.dart';
import 'server_composition_controls.dart';
import 'server_counter.dart';

/// File loading stays in server scope, outside the generated client bundle.
class ServerCompositionDemo extends AsyncHookComponent {
  const ServerCompositionDemo({super.key});

  @override
  Future<Component> build(BuildContext context) async {
    final source = useRef('data/server-message.txt');
    final message = await File(source.value).readAsString();
    final formatted = useMemoized(() => message.trim(), [message]);
    return ServerCompositionControls(
      cards: [
        for (final title in ['First card', 'Second card'])
          ExpandableCard(
            idScope: 'composition-$title',
            title: title,
            content: HookIdScope(
              seed: 'server-content-$title',
              child: AsyncHookBuilder(
                builder: (_) async {
                  final content = useRef(formatted);
                  await Future<void>.value();
                  final id = useId(prefix: 'server-message');
                  return div(
                    attributes: {'data-server-content': title},
                    [
                      p(id: id, [Component.text(content.value)]),
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
