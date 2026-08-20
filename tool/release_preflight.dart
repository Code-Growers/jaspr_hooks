import 'dart:convert';
import 'dart:io';

const _requiredUrls = <String>['repository', 'issue_tracker', 'documentation'];

Future<void> main(List<String> arguments) async {
  final checkAvailable = arguments.contains('--check-name-available');

  final pubspec = File('pubspec.yaml');
  if (!pubspec.existsSync()) _fail('Run this command from the package root.');
  final fields = _topLevelScalars(pubspec.readAsLinesSync());
  final name = fields['name'];
  final version = fields['version'];
  if (name == null || version == null) {
    _fail('pubspec.yaml must contain top-level name and version fields.');
  }

  for (final field in _requiredUrls) {
    final value = fields[field];
    if (value == null || !value.startsWith('https://')) {
      _fail('pubspec.yaml must contain a real HTTPS $field URL before release.');
    }
  }

  final remote = await Process.run('git', const ['remote', 'get-url', 'origin']);
  if (remote.exitCode != 0) {
    _fail('A real Git origin remote is required before release.');
  }
  final repository = Uri.parse(fields['repository']!);
  final normalizedRemote = _normalizeGitRemote((remote.stdout as String).trim());
  final normalizedRepository = _normalizeGitRemote(repository.toString());
  if (normalizedRemote != normalizedRepository) {
    _fail(
      'pubspec repository ($normalizedRepository) does not match origin '
      '($normalizedRemote).',
    );
  }

  final expectedTag = 'v$version';
  final tag = Platform.environment['GITHUB_REF_NAME'];
  if (tag != null && tag != expectedTag) {
    _fail('Tag $tag does not match pubspec version $version ($expectedTag).');
  }

  if (checkAvailable) {
    final status = await _pubPackageStatus(name);
    if (status != HttpStatus.notFound) {
      _fail('$name is no longer available on pub.dev (HTTP $status).');
    }
  }

  stdout.writeln('Release preflight passed for $name $version.');
  stdout.writeln('Publish manually from the verified pub.dev publisher account.');
}

Map<String, String> _topLevelScalars(List<String> lines) {
  final result = <String, String>{};
  final scalar = RegExp(r'''^([a-z_]+):\s*['"]?([^'"#]+?)['"]?\s*$''');
  for (final line in lines) {
    final match = scalar.firstMatch(line);
    if (match != null) result[match.group(1)!] = match.group(2)!.trim();
  }
  return result;
}

String _normalizeGitRemote(String value) {
  var normalized = value.trim();
  final ssh = RegExp(r'^git@github\.com:(.+)$').firstMatch(normalized);
  if (ssh != null) normalized = 'https://github.com/${ssh.group(1)}';
  if (normalized.endsWith('.git')) {
    normalized = normalized.substring(0, normalized.length - 4);
  }
  return normalized.replaceFirst(RegExp(r'/$'), '');
}

Future<int> _pubPackageStatus(String name) async {
  final client = HttpClient()..userAgent = 'jaspr_hooks release preflight';
  try {
    final request = await client.getUrl(Uri.https('pub.dev', '/api/packages/$name'));
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    final response = await request.close();
    await response.transform(utf8.decoder).drain<void>();
    return response.statusCode;
  } finally {
    client.close(force: true);
  }
}

Never _fail(String message) {
  stderr.writeln('Release blocked: $message');
  exit(1);
}
