const String aiAgentDocsUrl = 'https://code-growers.github.io/jaspr_hooks/llms.txt';

const String aiInstallPrompt =
    '''
Install and use jaspr_hooks in this Jaspr application.

Before changing code, read the complete AI-agent documentation at:
$aiAgentDocsUrl
The rendered AI-agent guide is available at:
https://code-growers.github.io/jaspr_hooks/guides/ai-agents/

Follow that document's hook rules, SSR/hydration contracts, ownership rules,
and per-hook API guidance. Use package:jaspr_hooks/jaspr_hooks.dart for the
universal API, or package:jaspr_hooks/web.dart with package:universal_web/web.dart
for DOM integrations. Do not import flutter_hooks or add Flutter. Confirm the
app uses Jaspr >=0.23.3 <0.24.0 and Dart >=3.8.0 <4.0.0, run
`dart pub add jaspr_hooks`, and validate the result with formatting, analysis,
and relevant tests. Summarize every file changed and any behavior that must
remain client-only.
''';
