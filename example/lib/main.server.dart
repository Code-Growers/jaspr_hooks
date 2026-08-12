/// Server/static entrypoint for the documentation site.
library;

import 'package:jaspr/server.dart';
import 'package:jaspr_content/components/callout.dart';
import 'package:jaspr_content/jaspr_content.dart';
import 'package:jaspr_content/theme.dart';

import 'base_path_table_of_contents.dart';
import 'components/docs_chrome.dart';
import 'components/hook_catalog_view.dart';
import 'components/hook_demo.dart';
import 'components/plain_code_block.dart';
import 'main.server.options.dart';

void main() {
  Jaspr.initializeApp(options: defaultServerOptions);

  runApp(
    ContentApp(
      templateEngine: MustacheTemplateEngine(),
      parsers: const <PageParser>[MarkdownParser()],
      extensions: <PageExtension>[
        const BasePathTableOfContentsExtension(),
      ],
      components: <CustomComponent>[
        Callout(),
        PlainCodeBlock(),
        CustomComponent(
          pattern: 'HookDemo',
          builder: (String _, Map<String, String> attributes, Component? _) {
            return HookDemo(name: attributes['name'] ?? 'unknown');
          },
        ),
        CustomComponent(
          pattern: 'HookCatalog',
          builder: (String _, Map<String, String> _, Component? _) => const HookCatalogView(),
        ),
      ],
      layouts: const <PageLayout>[
        DocsLayout(
          header: DocsHeader(),
          sidebar: DocsSidebar(),
          footer: DocsFooter(),
        ),
      ],
      theme: ContentTheme(
        primary: ThemeColor(ThemeColors.sky.$600, dark: ThemeColors.sky.$300),
        background: ThemeColor(ThemeColors.slate.$50, dark: ThemeColors.slate.$950),
        colors: <ColorToken>[
          ContentColors.quoteBorders.apply(
            ThemeColor(ThemeColors.sky.$300, dark: ThemeColors.sky.$700),
          ),
        ],
      ),
    ),
  );
}
