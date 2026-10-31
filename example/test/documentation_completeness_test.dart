import 'dart:io';

import 'package:jaspr_hooks_example/ai_install_prompt.dart';
import 'package:jaspr_hooks_example/components/hook_demo.dart';
import 'package:jaspr_hooks_example/hook_catalog.dart';
import 'package:test/test.dart';

void main() {
  final Directory exampleRoot = _findExampleRoot();
  final Directory packageRoot = exampleRoot.parent;

  test('catalog, public API, and demo registry stay in sync', () {
    final Set<String> catalogNames = hookCatalog.map((HookDoc hook) => hook.name).toSet();

    expect(catalogNames, hasLength(hookCatalog.length), reason: 'Hook names must be unique.');
    expect(
      hookCatalog.map((HookDoc hook) => hook.slug).toSet(),
      hasLength(hookCatalog.length),
      reason: 'Hook slugs must be unique.',
    );
    expect(HookDemo.supportedNames, catalogNames);
    expect(_exportedUseApis(packageRoot), catalogNames);

    final String e2eCatalog = File(
      '${packageRoot.path}/e2e/tests/catalog.ts',
    ).readAsStringSync();
    final Map<String, String> e2ePages = <String, String>{
      for (final RegExpMatch match in RegExp(
        r"api:\s*'([^']+)'\s*,\s*slug:\s*'([^']+)'",
      ).allMatches(e2eCatalog))
        match.group(1)!: match.group(2)!,
    };
    expect(e2ePages, <String, String>{
      for (final HookDoc hook in hookCatalog) hook.name: hook.slug,
    });
  });

  for (final HookDoc hook in hookCatalog) {
    test('${hook.name} has a complete reference page', () {
      final File page = File(
        '${exampleRoot.path}/content/hooks/${hook.slug}.md',
      );
      expect(page.existsSync(), isTrue, reason: 'Missing ${page.path}.');

      final String markdown = page.readAsStringSync();
      expect(
        markdown,
        contains('title: ${hook.name}'),
        reason: 'DocsLayout turns the frontmatter title into the page h1.',
      );
      expect(markdown, contains('```dart'));
      expect(markdown, contains('<HookDemo name="${hook.name}"/>'));
      expect(markdown, contains('## Signature'), reason: '${hook.name} must document its public signature.');
      expect(
        markdown,
        anyOf(contains('## Ownership'), contains('## Lifecycle'), contains('## Rebasing')),
        reason: '${hook.name} must document ownership and cleanup.',
      );
      expect(markdown, contains('## Server rendering'));
      expect(markdown, contains('## Common mistakes'));
      expect(markdown, contains('## Related APIs'));
      expect(
        RegExp(r'^## ', multiLine: true).allMatches(markdown).length,
        greaterThanOrEqualTo(4),
        reason: 'Every API page should explain behavior, usage, SSR, and related APIs.',
      );

      final File semanticTest = File('${packageRoot.path}/${hook.testFile}');
      expect(
        semanticTest.existsSync(),
        isTrue,
        reason: '${hook.name} maps to missing semantic test file ${hook.testFile}.',
      );
      expect(
        semanticTest.readAsStringSync(),
        contains(hook.name),
        reason: '${hook.testFile} no longer mentions its mapped API ${hook.name}.',
      );
    });
  }

  test('every navigation guide has content', () {
    for (final ({String title, String href}) guide in guideCatalog) {
      final File page = File('${exampleRoot.path}/content/${guide.href}.md');
      expect(page.existsSync(), isTrue, reason: 'Missing ${page.path}.');
      final String markdown = page.readAsStringSync();
      expect(markdown, contains('title:'));
      expect(markdown.trim().split(RegExp(r'\s+')).length, greaterThan(35));
    }
  });

  test('AI agent documentation and llms.txt cover the complete public API', () {
    final File agentGuide = File(
      '${exampleRoot.path}/content/guides/ai-agents.md',
    );
    final File llmsFile = File('${exampleRoot.path}/web/llms.txt');

    expect(agentGuide.existsSync(), isTrue, reason: 'Missing ${agentGuide.path}.');
    expect(llmsFile.existsSync(), isTrue, reason: 'Missing ${llmsFile.path}.');

    final String guide = agentGuide.readAsStringSync();
    final String llms = llmsFile.readAsStringSync();
    final String readme = File('${packageRoot.path}/README.md').readAsStringSync();
    final String gettingStarted = File(
      '${exampleRoot.path}/content/guides/getting-started.md',
    ).readAsStringSync();
    final Map<String, String> pubspec = _releaseMetadata(
      File('${packageRoot.path}/pubspec.yaml').readAsLinesSync(),
    );
    const List<String> requiredUrls = <String>[
      'https://github.com/Code-Growers/jaspr_hooks',
      'https://code-growers.github.io/jaspr_hooks/',
      'https://pub.dev/packages/jaspr_hooks',
    ];

    for (final String url in requiredUrls) {
      expect(llms, contains(url), reason: 'llms.txt must reference $url.');
    }
    expect(
      guide,
      contains('https://code-growers.github.io/jaspr_hooks/llms.txt'),
    );
    expect(guide, contains('dart pub add jaspr_hooks'));
    expect(
      guide,
      contains(aiInstallPrompt.trim()),
      reason: 'The rendered prompt must match the exact text copied by the CTA.',
    );
    expect(llms, contains('Current package version: ${pubspec['version']}'));
    expect(llms, contains('Dart constraint: ${pubspec['sdk']}'));
    expect(llms, contains('Jaspr constraint: ${pubspec['jaspr']}'));
    expect(readme, contains('jaspr_hooks: ^${pubspec['version']}'));
    expect(readme, contains('package:jaspr_hooks/web.dart'));
    expect(gettingStarted, contains('jaspr_hooks: ^${pubspec['version']}'));
    expect(aiInstallPrompt, contains('Jaspr ${pubspec['jaspr']}'));
    expect(aiInstallPrompt, contains('Dart ${pubspec['sdk']}'));
    expect(aiInstallPrompt, contains('package:jaspr_hooks/web.dart'));
    expect(aiInstallPrompt, contains('package:universal_web/web.dart'));

    for (final HookDoc hook in hookCatalog) {
      expect(readme, contains('`${hook.name}`'), reason: 'README does not list ${hook.name}.');
      expect(
        llms,
        contains('### ${hook.name}\n'),
        reason: 'llms.txt does not document ${hook.name}.',
      );
      expect(
        RegExp('^### ${RegExp.escape(hook.name)}\$', multiLine: true).allMatches(llms),
        hasLength(1),
        reason: 'llms.txt must contain exactly one canonical ${hook.name} entry.',
      );
      expect(
        llms,
        contains('Docs: https://code-growers.github.io/jaspr_hooks/hooks/${hook.slug}/'),
      );
    }
  });

  test('site is GitHub Pages base-path safe', () {
    final String siteData = File(
      '${exampleRoot.path}/content/_data/site.yaml',
    ).readAsStringSync();
    expect(siteData, contains('base: /jaspr_hooks/'));

    final Iterable<File> markdownFiles =
        Directory(
              '${exampleRoot.path}/content',
            )
            .listSync(recursive: true)
            .whereType<File>()
            .where(
              (File file) => file.path.endsWith('.md'),
            );
    for (final File file in markdownFiles) {
      final String markdown = file.readAsStringSync();
      expect(
        RegExp(r'\]\(/').hasMatch(markdown),
        isFalse,
        reason: '${file.path} contains a root-relative Markdown link.',
      );
      expect(
        markdown.toLowerCase(),
        isNot(contains('jaspr dog')),
        reason: 'The mascot is original artwork, not an official Jaspr logo derivative.',
      );

      final RegExp markdownLink = RegExp(r'(?<!!)\[[^\]]+\]\(([^\s)]+)');
      for (final RegExpMatch match in markdownLink.allMatches(markdown)) {
        final String destination = match.group(1)!;
        final Uri uri = Uri.parse(destination);
        if (uri.hasScheme || destination.startsWith('#')) continue;

        expect(
          destination,
          isNot(startsWith('.')),
          reason: '${file.path} contains a document-relative link that escapes the configured base.',
        );

        final String route = destination.split('#').first;
        final bool targetExists =
            File('${exampleRoot.path}/content/$route.md').existsSync() ||
            File('${exampleRoot.path}/content/$route/index.md').existsSync();
        expect(
          targetExists,
          isTrue,
          reason: '${file.path} links to missing internal route "$route".',
        );
      }
    }
  });
}

Map<String, String> _releaseMetadata(List<String> lines) {
  final Map<String, String> result = <String, String>{};
  String? section;
  for (final String line in lines) {
    if (line == 'environment:' || line == 'dependencies:') {
      section = line.substring(0, line.length - 1);
      continue;
    }
    if (line.isNotEmpty && !line.startsWith(' ')) section = null;

    final RegExpMatch? scalar = RegExp(r'''^([a-z_]+):\s*['"]?([^'"#]+?)['"]?\s*$''').firstMatch(line.trim());
    if (scalar == null) continue;
    final String key = scalar.group(1)!;
    final String value = scalar.group(2)!.trim();
    if (key == 'version' && section == null || key == 'sdk' && section == 'environment') {
      result[key] = value;
    } else if (key == 'jaspr' && section == 'dependencies') {
      result[key] = value;
    }
  }
  return result;
}

Directory _findExampleRoot() {
  final Directory current = Directory.current;
  if (File('${current.path}/pubspec.yaml').readAsStringSync().contains(
    'name: jaspr_hooks_example',
  )) {
    return current;
  }
  final Directory nested = Directory('${current.path}/example');
  if (File('${nested.path}/pubspec.yaml').existsSync()) {
    return nested;
  }
  throw StateError('Run this test from the package root or example directory.');
}

Set<String> _exportedUseApis(Directory packageRoot) {
  final RegExp exportPattern = RegExp(r"export '([^']+)'[^;]*;");
  final RegExp declarationPattern = RegExp(
    r'^\S[^\n=;{}]*?\b(use(?:[A-Z][A-Za-z0-9_]*)?)'
    r'\s*(?:<[^>\n]*>)?\s*\(',
    multiLine: true,
  );

  final Set<String> names = <String>{};
  for (final String entrypoint in <String>['jaspr_hooks.dart', 'web.dart', 'server.dart']) {
    final File library = File('${packageRoot.path}/lib/$entrypoint');
    for (final RegExpMatch export in exportPattern.allMatches(library.readAsStringSync())) {
      final File source = File('${packageRoot.path}/lib/${export.group(1)}');
      for (final RegExpMatch declaration in declarationPattern.allMatches(source.readAsStringSync())) {
        names.add(declaration.group(1)!);
      }
    }
  }
  return names;
}
