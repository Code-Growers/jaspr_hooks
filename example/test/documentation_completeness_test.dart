import 'dart:io';

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
  final File library = File('${packageRoot.path}/lib/jaspr_hooks.dart');
  final RegExp exportPattern = RegExp(r"export '([^']+)';");
  final RegExp declarationPattern = RegExp(
    r'^\S[^\n=;{}]*?\b(use(?:[A-Z][A-Za-z0-9_]*)?)'
    r'\s*(?:<[^>\n]*>)?\s*\(',
    multiLine: true,
  );

  final Set<String> names = <String>{};
  for (final RegExpMatch export in exportPattern.allMatches(library.readAsStringSync())) {
    final File source = File('${packageRoot.path}/lib/${export.group(1)}');
    for (final RegExpMatch declaration in declarationPattern.allMatches(source.readAsStringSync())) {
      names.add(declaration.group(1)!);
    }
  }
  return names;
}
