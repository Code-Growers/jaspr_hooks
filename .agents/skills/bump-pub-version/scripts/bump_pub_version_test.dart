import 'dart:io';

import 'package:test/test.dart';

import 'bump_pub_version.dart' as bump;

void main() {
  test('dry run leaves every release reference unchanged', () {
    final fixture = _fixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    bump.runVersionBump(
      <String>['0.1.0-dev.2', '--dry-run'],
      workingDirectory: fixture,
    );

    expect(_read(fixture, 'pubspec.yaml'), contains('version: 0.1.0-dev.1'));
    expect(_read(fixture, 'README.md'), contains('jaspr_hooks: ^0.1.0-dev.1'));
  });

  test('updates every release reference exactly once', () {
    final fixture = _fixture();
    addTearDown(() => fixture.deleteSync(recursive: true));

    bump.runVersionBump(
      <String>['0.1.0-dev.2'],
      workingDirectory: fixture,
    );

    for (final path in <String>[
      'pubspec.yaml',
      'README.md',
      'example/content/guides/getting-started.md',
      'example/web/llms.txt',
    ]) {
      expect(_read(fixture, path), isNot(contains('0.1.0-dev.1')), reason: path);
      expect(_read(fixture, path), contains('0.1.0-dev.2'), reason: path);
    }
    expect(
      _read(fixture, 'CONTRIBUTING.md'),
      contains('publish `0.1.0-dev.1` manually'),
    );
  });

  test('promotes a preview without calling the stable release a preview', () {
    final fixture = _fixture(target: '0.1.0');
    addTearDown(() => fixture.deleteSync(recursive: true));

    bump.runVersionBump(<String>['0.1.0'], workingDirectory: fixture);

    expect(
      _read(fixture, 'README.md'),
      contains('> Current stable release: `0.1.0`.'),
    );
    expect(_read(fixture, 'README.md'), isNot(contains('0.1.0` is a preview')));
  });
}

Directory _fixture({String target = '0.1.0-dev.2'}) {
  final root = Directory.systemTemp.createTempSync('bump_pub_version_');
  _write(root, 'pubspec.yaml', 'version: 0.1.0-dev.1\n');
  _write(root, 'CHANGELOG.md', '# $target\n\n- Changes.\n');
  _write(
    root,
    'README.md',
    '> `0.1.0-dev.1` is a preview. The API is intentionally being validated in real\n'
        '> Jaspr applications before `0.1.0`.\n'
        'jaspr_hooks: ^0.1.0-dev.1\n',
  );
  _write(
    root,
    'CONTRIBUTING.md',
    'publish `0.1.0-dev.1` manually\n',
  );
  _write(
    root,
    'example/content/guides/getting-started.md',
    'jaspr_hooks: ^0.1.0-dev.1\n',
  );
  _write(
    root,
    'example/web/llms.txt',
    'Current package version: 0.1.0-dev.1\n'
        'jaspr_hooks: ^0.1.0-dev.1\n',
  );
  return root;
}

String _read(Directory root, String path) => File('${root.path}/$path').readAsStringSync();

void _write(Directory root, String path, String contents) {
  final file = File('${root.path}/$path')..parent.createSync(recursive: true);
  file.writeAsStringSync(contents);
}
