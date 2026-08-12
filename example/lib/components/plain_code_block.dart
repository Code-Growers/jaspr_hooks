import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_content/jaspr_content.dart';

/// Deterministic fenced-code renderer used by the static documentation build.
///
/// `jaspr_content` 0.5.4's highlighting component starts an asynchronous
/// grammar initialization without awaiting it. Static rendering visits routes
/// concurrently, which can race and fail the build. This renderer deliberately
/// keeps code unhighlighted; the browser still gets selectable, copyable code
/// and the package can return to the built-in component after that upstream
/// race is fixed.
final class PlainCodeBlock extends CustomComponent {
  PlainCodeBlock() : super.base();

  @override
  Component? create(Node node, NodesBuilder builder) {
    if (node
        case ElementNode(
              tag: 'Code' || 'CodeBlock',
              :final children,
              :final attributes,
            ) ||
            ElementNode(
              tag: 'pre',
              children: <Node>[ElementNode(tag: 'code', :final children, :final attributes)],
            )) {
      String? language = attributes['language'];
      final String? className = attributes['class'];
      if (language == null && (className?.startsWith('language-') ?? false)) {
        language = className!.substring('language-'.length);
      }
      final String source = children?.map((Node child) => child.innerText).join(' ') ?? '';
      return pre(
        classes: 'code-block',
        <Component>[
          code(
            classes: language == null ? null : 'language-$language',
            <Component>[Component.text(source)],
          ),
        ],
      );
    }
    return null;
  }
}
