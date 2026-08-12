import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_content/components/sidebar.dart';
import 'package:jaspr_content/components/sidebar_toggle_button.dart';
import 'package:jaspr_content/components/theme_toggle.dart';
import 'package:jaspr_content/jaspr_content.dart';
import 'package:jaspr_content/theme.dart';

import '../hook_catalog.dart';

/// Header used by the documentation layout.
class DocsHeader extends StatelessComponent {
  const DocsHeader({super.key});

  @override
  Component build(BuildContext context) {
    return Component.fragment(<Component>[
      Document.head(children: <Component>[Style(styles: _styles)]),
      header(classes: 'jaspr-hooks-header', <Component>[
        const SidebarToggleButton(),
        a(
          classes: 'jaspr-hooks-brand',
          href: './',
          attributes: const <String, String>{'aria-label': 'jaspr_hooks home'},
          <Component>[
            img(src: 'images/jaspr_hooks_mascot_192.png', alt: 'Original fishing-dog mascot for jaspr_hooks'),
            span(<Component>[const Component.text('jaspr_hooks')]),
          ],
        ),
        nav(
          classes: 'jaspr-hooks-header-links',
          attributes: const <String, String>{'aria-label': 'Primary navigation'},
          <Component>[
            a(href: 'guides/getting-started', <Component>[const Component.text('Guide')]),
            a(href: 'hooks', <Component>[const Component.text('Hooks')]),
            a(
              href: 'https://pub.dev/packages/jaspr_hooks',
              attributes: const <String, String>{'target': '_blank', 'rel': 'noreferrer'},
              <Component>[const Component.text('pub.dev')],
            ),
            const ThemeToggle(),
          ],
        ),
      ]),
    ]);
  }

  static final List<StyleRule> _styles = <StyleRule>[
    css('.jaspr-hooks-header').styles(
      display: Display.flex,
      height: Unit.rem(4),
      padding: Padding.symmetric(horizontal: Unit.rem(1), vertical: Unit.rem(0.25)),
      margin: Margin.symmetric(horizontal: Unit.auto),
      border: Border.only(
        bottom: BorderSide(color: const Color('#0000000d'), width: Unit.pixels(1)),
      ),
      alignItems: AlignItems.center,
      gap: Gap.column(Unit.rem(1)),
      backgroundColor: ContentColors.background,
    ),
    css('.jaspr-hooks-brand').styles(
      display: Display.inlineFlex,
      alignItems: AlignItems.center,
      gap: Gap.column(Unit.rem(0.75)),
      flex: const Flex(basis: Unit.rem(17)),
      fontWeight: FontWeight.w700,
      textDecoration: TextDecoration.none,
    ),
    css('.jaspr-hooks-brand img').styles(width: Unit.rem(2.65), height: Unit.rem(2.65)),
    css('.jaspr-hooks-header-links').styles(
      display: Display.flex,
      alignItems: AlignItems.center,
      justifyContent: JustifyContent.end,
      gap: Gap.column(Unit.rem(0.4)),
      flex: const Flex(grow: 1),
    ),
    css('.jaspr-hooks-header-links > a').styles(
      padding: Padding.symmetric(horizontal: Unit.rem(0.65), vertical: Unit.rem(0.5)),
      radius: BorderRadius.circular(Unit.rem(0.45)),
      textDecoration: TextDecoration.none,
    ),
    css('.jaspr-hooks-header-links > a:hover').styles(
      backgroundColor: const Color('color-mix(in srgb, currentColor 6%, transparent)'),
    ),
    css.media(MediaQuery.all(maxWidth: Unit.pixels(640)), <StyleRule>[
      css('.jaspr-hooks-header-links > a').styles(display: Display.none),
    ]),
  ];
}

/// Sidebar whose relative links honor the GitHub Pages base path.
class DocsSidebar extends StatelessComponent {
  const DocsSidebar({super.key});

  @override
  Component build(BuildContext context) {
    final String rawRoute = context.page.url.replaceFirst(RegExp(r'^/'), '');
    final String currentRoute = rawRoute.isEmpty ? './' : rawRoute;

    return Sidebar(
      currentRoute: currentRoute,
      groups: <SidebarGroup>[
        const SidebarGroup(
          links: <SidebarLink>[
            SidebarLink(text: 'Overview', href: './'),
            SidebarLink(text: 'Hook catalog', href: 'hooks'),
          ],
        ),
        SidebarGroup(
          title: 'Guides',
          links: <SidebarLink>[
            for (final ({String title, String href}) guide in guideCatalog)
              SidebarLink(text: guide.title, href: guide.href),
          ],
        ),
        for (final HookCategory category in HookCategory.values)
          SidebarGroup(
            title: category.label,
            links: <SidebarLink>[
              for (final HookDoc hook in hookCatalog.where((HookDoc hook) => hook.category == category))
                SidebarLink(text: hook.name, href: hook.href),
            ],
          ),
      ],
    );
  }
}

/// Attribution shown beneath every documentation page.
class DocsFooter extends StatelessComponent {
  const DocsFooter({super.key});

  @override
  Component build(BuildContext context) {
    return footer(<Component>[
      p(<Component>[
        const Component.text('Built for native Jaspr. Runtime design substantially adapted from '),
        a(
          href: 'https://github.com/rrousselGit/flutter_hooks',
          attributes: const <String, String>{'target': '_blank', 'rel': 'noreferrer'},
          <Component>[const Component.text('flutter_hooks')],
        ),
        const Component.text(' under the MIT License.'),
      ]),
    ]);
  }
}
