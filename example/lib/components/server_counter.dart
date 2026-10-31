import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_hooks/jaspr_hooks.dart';

/// A client island nested inside a server component.
@client
class ServerCounter extends StatefulHookComponent {
  const ServerCounter({required this.idScope, super.key});

  final String idScope;

  @override
  State<ServerCounter> createState() => _ServerCounterState();
}

class _ServerCounterState extends State<ServerCounter> {
  @override
  Component build(BuildContext context) {
    final count = useState(0);
    return HookIdScope(
      seed: component.idScope,
      child: HookBuilder(
        builder: (_) {
          final id = useId(prefix: 'nested-counter');
          return button(
            id: id,
            attributes: {'data-server-counter': component.idScope},
            onClick: () => count.value++,
            [Component.text('Nested count: ${count.value}')],
          );
        },
      ),
    );
  }
}
