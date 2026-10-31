@TestOn('browser')
library;

import 'package:jaspr/jaspr.dart';
import 'package:jaspr_hooks/web.dart';
import 'package:jaspr_test/client_test.dart';
import 'package:universal_web/web.dart' as web;

void main() {
  testClient('reassembly preserves the node key, DOM node and state without duplicate handlers', (tester) async {
    final events = <String>[];
    var version = 1;
    late GlobalNodeKey<web.Element> key;
    late ValueNotifier<int> count;
    tester.pumpComponent(
      HookBuilder(
        builder: (_) {
          key = useNodeKey<web.Element>();
          count = useState(0);
          final captured = version;
          useEffect(() {
            events.add('effect:$captured');
            return () => events.add('cleanup:$captured');
          }, const []);
          return Component.element(
            tag: 'button',
            key: key,
            events: {'click': (_) => count.value++},
            children: [
              Component.text('${count.value}'),
            ],
          );
        },
      ),
    );
    final originalKey = key;
    final originalNode = key.currentNode!;
    originalNode.dispatchEvent(web.MouseEvent('click'));
    await pumpEventQueue();
    expect(count.value, 1);

    version = 2;
    tester.binding.rootElement!.visitChildren((element) {
      // ignore: invalid_use_of_protected_member
      element.reassemble();
    });
    await pumpEventQueue();
    expect(key, same(originalKey));
    expect(key.currentNode, same(originalNode));
    expect(count.value, 1);
    originalNode.dispatchEvent(web.MouseEvent('click'));
    await pumpEventQueue();
    expect(count.value, 2);
    expect(events, ['effect:1', 'cleanup:1', 'effect:2']);
    tester.binding.detachRootComponent();
    expect(events, ['effect:1', 'cleanup:1', 'effect:2', 'cleanup:2']);
    // Jaspr must remove the old DOM event handler along with the component.
    originalNode.dispatchEvent(web.MouseEvent('click'));
  });
}
