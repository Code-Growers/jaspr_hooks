import 'dart:async';

import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_hooks/jaspr_hooks.dart';

import '../ai_clipboard.dart';
import '../ai_install_prompt.dart';

/// Landing-page call to action that copies a complete coding-agent prompt.
@client
class AiInstallPrompt extends StatelessComponent {
  const AiInstallPrompt({super.key});

  @override
  Component build(BuildContext context) {
    return HookBuilder(
      builder: (BuildContext context) {
        final ValueNotifier<String> feedback = useState<String>('Copy AI install prompt');
        final IsMounted isMounted = useIsMounted();
        final bool copied = feedback.value.startsWith('Copied');

        void copyPrompt() {
          feedback.value = 'Copying AI install prompt';
          unawaited(
            copyTextToClipboard(aiInstallPrompt).then((bool success) {
              if (!isMounted()) return;
              feedback.value = success
                  ? 'Copied AI install prompt to clipboard'
                  : 'Copy failed — open the AI agent docs to copy the prompt';
            }),
          );
        }

        return aside(
          classes: 'ai-install-panel',
          attributes: const <String, String>{'aria-label': 'Install jaspr_hooks with an AI coding agent'},
          <Component>[
            div(classes: 'ai-install-copy', <Component>[
              div(classes: 'ai-install-eyebrow', <Component>[const Component.text('BUILD WITH AN AGENT')]),
              p(<Component>[
                const Component.text('Give your coding agent the install steps, hook rules, and SSR contracts.'),
              ]),
            ]),
            div(classes: 'ai-install-actions', <Component>[
              a(
                classes: 'ai-install-docs',
                href: 'guides/ai-agents',
                <Component>[
                  const Component.text('AI AGENT DOCS'),
                  span(
                    attributes: const <String, String>{'aria-hidden': 'true'},
                    <Component>[
                      const Component.text('→'),
                    ],
                  ),
                ],
              ),
              button(
                classes: 'ai-install-button',
                attributes: const <String, String>{
                  'type': 'button',
                  'data-testid': 'ai-install-prompt',
                  'aria-describedby': 'ai-install-feedback',
                },
                onClick: copyPrompt,
                <Component>[
                  span(
                    classes: 'ai-install-icon',
                    attributes: const <String, String>{'aria-hidden': 'true'},
                    <Component>[
                      Component.text(copied ? '✓' : '⧉'),
                    ],
                  ),
                  Component.text(copied ? 'COPIED' : 'COPY AI INSTALL PROMPT'),
                ],
              ),
              span(
                id: 'ai-install-feedback',
                classes: 'ai-install-feedback',
                attributes: const <String, String>{
                  'data-testid': 'ai-install-feedback',
                  'aria-live': 'polite',
                  'role': 'status',
                },
                <Component>[Component.text(feedback.value)],
              ),
            ]),
          ],
        );
      },
    );
  }

  @css
  static List<StyleRule> get styles => <StyleRule>[
    css('.ai-install-panel').styles(
      display: Display.flex,
      alignItems: AlignItems.center,
      justifyContent: JustifyContent.spaceBetween,
      gap: Gap.all(Unit.rem(1.25)),
      flexWrap: FlexWrap.wrap,
      padding: Padding.symmetric(horizontal: Unit.rem(1.4), vertical: Unit.rem(1.2)),
      margin: Margin.symmetric(vertical: Unit.rem(2)),
      border: Border.all(color: const Color('color-mix(in srgb, #5bd17b 55%, transparent)')),
      radius: BorderRadius.circular(Unit.rem(0.9)),
      backgroundColor: const Color('color-mix(in srgb, #5bd17b 7%, var(--background))'),
    ),
    css('.ai-install-copy').styles(
      flex: const Flex(grow: 1, basis: Unit.rem(17)),
    ),
    css('.ai-install-copy p').styles(
      margin: Margin.only(top: Unit.rem(0.3)),
      opacity: 0.82,
    ),
    css('.ai-install-eyebrow').styles(
      color: const Color('#5bd17b'),
      fontSize: Unit.rem(0.74),
      fontWeight: FontWeight.w700,
      letterSpacing: Unit.em(0.09),
    ),
    css('.ai-install-actions').styles(
      display: Display.flex,
      alignItems: AlignItems.center,
      gap: Gap.all(Unit.rem(0.85)),
      flexWrap: FlexWrap.wrap,
    ),
    css('.ai-install-docs, .ai-install-button').styles(
      display: Display.inlineFlex,
      alignItems: AlignItems.center,
      justifyContent: JustifyContent.center,
      gap: Gap.column(Unit.rem(0.6)),
      minHeight: Unit.rem(3.1),
      padding: Padding.symmetric(horizontal: Unit.rem(1.2), vertical: Unit.rem(0.7)),
      border: Border.all(color: const Color('#5bd17b'), width: Unit.pixels(1)),
      radius: BorderRadius.circular(Unit.rem(0.7)),
      fontWeight: FontWeight.w700,
      letterSpacing: Unit.em(0.025),
      textDecoration: TextDecoration.none,
      raw: const <String, String>{'cursor': 'pointer', 'transition': 'transform 140ms ease, box-shadow 140ms ease'},
    ),
    css('.ai-install-docs').styles(
      color: const Color('#07130b'),
      backgroundColor: const Color('#5bd17b'),
    ),
    css('.ai-install-button').styles(
      color: const Color('#5bd17b'),
      backgroundColor: Colors.transparent,
    ),
    css('.ai-install-docs:hover, .ai-install-button:hover').styles(
      raw: const <String, String>{
        'transform': 'translateY(-1px)',
        'box-shadow': '0 8px 24px color-mix(in srgb, #5bd17b 18%, transparent)',
      },
    ),
    css('.ai-install-icon').styles(
      fontSize: Unit.rem(1.05),
      raw: const <String, String>{'line-height': '1'},
    ),
    css('.ai-install-feedback').styles(
      raw: const <String, String>{
        'position': 'absolute',
        'width': '1px',
        'height': '1px',
        'padding': '0',
        'margin': '-1px',
        'overflow': 'hidden',
        'clip': 'rect(0, 0, 0, 0)',
        'white-space': 'nowrap',
        'border': '0',
      },
    ),
    css.media(MediaQuery.all(maxWidth: Unit.pixels(640)), <StyleRule>[
      css('.ai-install-actions').styles(width: Unit.percent(100)),
      css('.ai-install-docs, .ai-install-button').styles(
        flex: const Flex(grow: 1, basis: Unit.percent(100)),
      ),
    ]),
  ];
}
