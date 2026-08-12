import 'dart:io';

const _required = <String>[
  'LICENSE',
  'README.md',
  'CHANGELOG.md',
  'THIRD_PARTY_NOTICES.md',
  'lib/jaspr_hooks.dart',
  'example/example.md',
  'screenshots/hook_gallery.png',
  'screenshots/hook_demo.png',
];

const _forbidden = <String>[
  'e2e',
  'node_modules',
  'playwright-report',
  'test-results',
  'example/build',
  'build',
];

void main() {
  final missing = _required.where((path) => !File(path).existsSync()).toList();
  final accidentallyIncluded = _forbidden.where(_isPublishablePath).toList();

  if (missing.isNotEmpty || accidentallyIncluded.isNotEmpty) {
    if (missing.isNotEmpty) stderr.writeln('Missing required package files: $missing');
    if (accidentallyIncluded.isNotEmpty) {
      stderr.writeln('Forbidden publish paths are not excluded: $accidentallyIncluded');
    }
    exitCode = 1;
    return;
  }
  stdout.writeln('Package layout contains all required files and exclusions.');
}

bool _isPublishablePath(String path) {
  if (!FileSystemEntity.isDirectorySync(path) && !FileSystemEntity.isFileSync(path)) {
    return false;
  }

  final ignored = _readIgnoreRules('.pubignore');
  return !ignored.any((rule) => path == rule || path.startsWith('$rule/'));
}

Set<String> _readIgnoreRules(String path) {
  final file = File(path);
  if (!file.existsSync()) return const {};
  return file
      .readAsLinesSync()
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty && !line.startsWith('#'))
      .map((line) => line.replaceFirst(RegExp(r'^/'), '').replaceFirst(RegExp(r'/$'), ''))
      .toSet();
}
