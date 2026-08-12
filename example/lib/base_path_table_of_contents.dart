import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_content/jaspr_content.dart';

final class BasePathTableOfContentsExtension implements PageExtension {
  const BasePathTableOfContentsExtension({this.maxHeaderDepth = 3});

  final int maxHeaderDepth;

  static final RegExp _header = RegExp(r'^h(\d)$', caseSensitive: false);

  @override
  Future<List<Node>> apply(Page page, List<Node> nodes) async {
    final List<_Entry> toc = <_Entry>[];
    final List<_Entry> stack = <_Entry>[];
    final List<Node> toVisit = <Node>[...nodes.reversed];

    while (toVisit.isNotEmpty) {
      final Node node = toVisit.removeLast();
      if (node is! ElementNode) continue;
      final String? depth = _header.firstMatch(node.tag)?.group(1);
      if (depth == null) {
        toVisit.addAll(node.children?.reversed ?? const <Node>[]);
        continue;
      }

      final int level = int.parse(depth) - 2;
      if (level < 0 || level > maxHeaderDepth - 2) continue;
      final String? id = node.attributes['id'];
      if (id == null || (node.attributes['class']?.contains('no_toc') ?? false)) continue;

      final _Entry entry = _Entry(node.innerText, id);
      while (level < stack.length) {
        stack.removeLast();
      }
      if (level > stack.length) continue;
      if (stack.isEmpty) {
        toc.add(entry);
      } else {
        stack.last.children.add(entry);
      }
      stack.add(entry);
    }

    page.apply(data: <String, Object?>{'toc': _BasePathTableOfContents(page.url, toc)});
    return nodes;
  }
}

final class _BasePathTableOfContents extends TableOfContents {
  const _BasePathTableOfContents(this.pageUrl, this.baseEntries) : super(const <TocEntry>[]);

  final String pageUrl;
  final List<_Entry> baseEntries;

  @override
  Component build() => ul(<Component>[..._build(baseEntries)]);

  Iterable<Component> _build(List<_Entry> entries, [int indent = 0]) sync* {
    final String relativePage = pageUrl.replaceFirst(RegExp(r'^/'), '');
    for (final _Entry entry in entries) {
      yield li(
        styles: Styles(padding: Padding.only(left: (0.75 * indent).em)),
        <Component>[
          a(href: '$relativePage#${entry.id}', <Component>[Component.text(entry.text)]),
        ],
      );
      if (entry.children.isNotEmpty) yield* _build(entry.children, indent + 1);
    }
  }
}

final class _Entry {
  _Entry(this.text, this.id);

  final String text;
  final String id;
  final List<_Entry> children = <_Entry>[];
}
