import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:jaspr/dom.dart';
import 'package:jaspr/server.dart';
import 'package:jaspr_hooks/server.dart';
import 'package:jaspr_hooks_example/components/expandable_card.dart';
import 'package:jaspr_hooks_example/components/server_counter.dart';
import 'package:jaspr_hooks_example/main.server.options.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';

import '../../../test/support/pending_child.dart';

// A loopback-only HTTP fixture. Generated options and production client assets
// come from the documentation build; no handwritten hydration adapters are used.
Future<void> main() async {
  Jaspr.initializeApp(options: defaultServerOptions);
  final records = <String, _RequestRecord>{};
  final webRoot = Platform.environment['JASPR_HOOKS_E2E_WEB']!;
  final handler = ServerApp.createTestHandler((request, render) async {
    final token = request.url.queryParameters['token'] ?? 'default';
    if (request.url.path == '__health') return Response.ok('ready');
    if (request.url.path.startsWith('__')) {
      final record = records[token];
      if (record == null) return Response.notFound('unknown token');
      switch (request.url.path) {
        case '__release':
          final phase = int.parse(request.url.queryParameters['phase']!);
          if (!record.gates[phase]!.isCompleted) record.gates[phase]!.complete();
        case '__reject':
          if (!record.gates[1]!.isCompleted) record.gates[1]!.completeError(StateError('late loader failure'));
        case '__late':
          if (!record.late.isCompleted) record.late.complete();
          await record.lateResult;
        case '__unmount':
          record.pending.unmount();
        case '__dispose':
          record.binding?.detachRootComponent();
          record.binding = null;
        case '__state':
          break;
        default:
          return Response.notFound('unknown control');
      }
      return Response.ok(jsonEncode(record.snapshot), headers: {'content-type': 'application/json'});
    }
    final record = _RequestRecord(token, request.url.queryParameters['hold'] == 'true');
    records[token] = record;
    return render((binding) {
      record.binding = binding;
      binding.initializeOptions(defaultServerOptions);
      binding.attachRootComponent(
        Document(
          title: 'Async hooks E2E',
          base: '/',
          body: HookIdScope(
            seed: 'request-$token',
            child: PendingChild(
              controller: record.pending,
              child: _RequestPage(record, request.url.queryParameters['fail']),
            ),
          ),
        ),
      );
    });
  }, fileHandler: createStaticHandler(webRoot));
  final port = int.parse(Platform.environment['E2E_ASYNC_PORT'] ?? '4174');
  await shelf_io.serve(handler, InternetAddress.loopbackIPv4, port);
  stdout.writeln('Async hook HTTP fixture listening on 127.0.0.1:$port');
}

class _RequestRecord {
  _RequestRecord(this.token, this.hold);

  final String token;
  final bool hold;
  final events = <String>[];
  final gates = {1: Completer<void>(), 2: Completer<void>()};
  final late = Completer<void>();
  final pending = PendingChildController();
  ServerAppBinding? binding;
  Future<void>? lateResult;
  String? lateError;
  var effects = 0;
  var contextMatches = true;

  Future<void> wait(int phase) async {
    events.add('await:$phase');
    if (hold) {
      try {
        await gates[phase]!.future;
      } catch (_) {
        events.add('loader-error:$phase');
        rethrow;
      }
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  }

  Map<String, Object?> get snapshot => {
    'events': events,
    'effects': effects,
    'contextMatches': contextMatches,
    'lateError': lateError,
  };
}

class _RequestPage extends AsyncHookComponent {
  const _RequestPage(this.record, this.failure);

  final _RequestRecord record;
  final String? failure;

  @override
  Future<Component> build(BuildContext context) async {
    final token = useRef(record.token);
    final originalContext = useContext();
    final before = useMemoized(() => 'before:${token.value}');
    useDisposable(() => 'before', (value) => record.events.add('dispose:$value'));
    useEffect(() {
      record.effects++;
      return null;
    });
    record.lateResult = record.late.future.then((_) {
      try {
        useRef('escaped');
      } catch (error) {
        record.lateError = error.toString();
      }
    });
    if (failure == 'before') throw StateError('fixture failure before await');

    await record.wait(1);
    try {
      record.contextMatches = record.contextMatches && identical(originalContext, useContext());
    } catch (error) {
      record.events.add('cancelled-hook-rejected');
      rethrow;
    }
    final middle = useRef(record.token);
    useDisposable(() => 'after', (value) => record.events.add('dispose:$value'));
    if (failure == 'after') throw StateError('fixture failure after await');
    if (failure == 'source') useFuture(Future<int>.value(1));
    if (failure == 'state') useState(0).value = 1;
    await record.wait(2);
    record.contextMatches = record.contextMatches && identical(context, useContext());
    final after = useMemoized(() => 'after:${middle.value}:${useContext().binding.currentUrl}');
    usePostFrameEffect(() {
      record.effects++;
      return null;
    });
    record.events.add('complete');

    return ExpandableCard(
      idScope: 'card-${token.value}',
      title: token.value,
      content: HookIdScope(
        seed: 'child-${token.value}',
        child: AsyncHookBuilder(
          builder: (nestedContext) async {
            final child = useRef('nested:${token.value}');
            await Future<void>.value();
            final id = useId(prefix: 'async-content');
            record.contextMatches =
                record.contextMatches &&
                identical(nestedContext, useContext()) &&
                !identical(originalContext, useContext());
            return div(
              id: id,
              attributes: {'data-async-content': token.value},
              [
                p([Component.text('$before|$after|${child.value}')]),
                HookBuilder(
                  builder: (syncContext) {
                    record.contextMatches = record.contextMatches && identical(syncContext, useContext());
                    return Component.text(useMemoized(() => 'sync:${token.value}'));
                  },
                ),
                ServerCounter(idScope: 'counter-${token.value}'),
              ],
            );
          },
        ),
      ),
    );
  }
}
