import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_content/theme.dart';

import '../hook_catalog.dart';

/// Renders the canonical hook catalog from Dart metadata.
class HookCatalogView extends StatelessComponent {
  const HookCatalogView({super.key});

  @override
  Component build(BuildContext context) {
    return Component.fragment(<Component>[
      Document.head(children: <Component>[Style(styles: _styles)]),
      div(classes: 'hook-catalog', <Component>[
        for (final HookCategory category in HookCategory.values)
          section(<Component>[
            h2(<Component>[Component.text(category.label)]),
            div(classes: 'hook-catalog-grid', <Component>[
              for (final HookDoc hook in hookCatalog.where((HookDoc hook) => hook.category == category))
                a(classes: 'hook-catalog-card', href: hook.href, <Component>[
                  code(<Component>[Component.text(hook.name)]),
                  p(<Component>[Component.text(hook.summary)]),
                ]),
            ]),
          ]),
      ]),
    ]);
  }

  static final List<StyleRule> _styles = <StyleRule>[
    css('.hook-catalog-grid').styles(
      display: Display.grid,
      gap: Gap.all(Unit.rem(0.75)),
      raw: const <String, String>{'grid-template-columns': 'repeat(auto-fit, minmax(15rem, 1fr))'},
    ),
    css('.hook-catalog-card').styles(
      display: Display.block,
      padding: Padding.all(Unit.rem(1)),
      border: Border.all(color: const Color('color-mix(in srgb, currentColor 15%, transparent)')),
      radius: BorderRadius.circular(Unit.rem(0.65)),
      color: ContentColors.text,
      backgroundColor: ContentColors.background,
      textDecoration: TextDecoration.none,
    ),
    css('.hook-catalog-card:hover').styles(
      border: Border.all(color: ContentColors.primary),
      transform: Transform.translate(y: Unit.pixels(-2)),
    ),
    css('.hook-catalog-card code').styles(color: ContentColors.primary, fontWeight: FontWeight.w700),
    css('.hook-catalog-card p').styles(
      margin: Margin.only(top: Unit.rem(0.5), bottom: Unit.zero),
    ),
  ];
}
