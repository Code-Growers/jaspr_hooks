import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_hooks/jaspr_hooks.dart';

/// An interactive wrapper whose content is supplied by the server.
@client
class ExpandableCard extends StatelessComponent {
  const ExpandableCard({required this.idScope, required this.title, required this.content, super.key});

  final String idScope;
  final String title;
  final Component content;

  @override
  Component build(BuildContext context) => HookIdScope(
    seed: idScope,
    child: _ExpandableCardBody(title: title, content: content),
  );
}

class _ExpandableCardBody extends HookComponent {
  const _ExpandableCardBody({required this.title, required this.content});

  final String title;
  final Component content;

  @override
  Component build(BuildContext context) {
    final expanded = useState(false);
    final headingId = useId(prefix: 'card-heading');
    final panelId = useId(prefix: 'card-panel');
    return section(
      attributes: {'data-server-card': title},
      [
        button(
          id: headingId,
          attributes: {'aria-expanded': '${expanded.value}', 'aria-controls': panelId},
          onClick: () => expanded.value = !expanded.value,
          [Component.text('${expanded.value ? 'Collapse' : 'Expand'} $title')],
        ),
        div(
          id: panelId,
          attributes: {'role': 'region', 'aria-labelledby': headingId, 'data-server-panel': title},
          styles: Styles(display: expanded.value ? Display.block : Display.none),
          [content],
        ),
      ],
    );
  }
}
