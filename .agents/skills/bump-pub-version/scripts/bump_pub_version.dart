import 'dart:io';

void main(List<String> arguments) => runVersionBump(arguments);

void runVersionBump(
  List<String> arguments, {
  Directory? workingDirectory,
}) {
  final dryRun = arguments.contains('--dry-run');
  final positional = arguments.where((argument) => argument != '--dry-run').toList();
  if (positional.length != 1) {
    _fail(
      'Usage: dart run '
      '.agents/skills/bump-pub-version/scripts/bump_pub_version.dart '
      '<version> [--dry-run]',
    );
  }

  final root = workingDirectory ?? Directory.current;
  final pubspec = File('${root.path}/pubspec.yaml');
  if (!pubspec.existsSync()) {
    _fail('Run this script from the jaspr_hooks repository root.');
  }

  final pubspecText = pubspec.readAsStringSync();
  final currentMatch = RegExp(
    r'^version:\s*([^\s#]+)\s*$',
    multiLine: true,
  ).firstMatch(pubspecText);
  if (currentMatch == null) _fail('Could not read the package version.');

  final current = PackageVersion.parse(currentMatch.group(1)!);
  final target = PackageVersion.parse(positional.single);
  if (target.compareTo(current) <= 0) {
    _fail('Target $target must be newer than current version $current.');
  }

  final changelog = File('${root.path}/CHANGELOG.md').readAsStringSync();
  if (!changelog.startsWith('# $target\n\n')) {
    _fail('CHANGELOG.md must start with a # $target release section.');
  }

  final replacements = <VersionReplacement>[
    VersionReplacement('pubspec.yaml', 'version: $current', 'version: $target'),
    VersionReplacement(
      'README.md',
      _releaseNotice(current),
      _releaseNotice(target),
    ),
    VersionReplacement(
      'README.md',
      'jaspr_hooks: ^$current',
      'jaspr_hooks: ^$target',
    ),
    VersionReplacement(
      'example/content/guides/getting-started.md',
      'jaspr_hooks: ^$current',
      'jaspr_hooks: ^$target',
    ),
    VersionReplacement(
      'example/web/llms.txt',
      'Current package version: $current',
      'Current package version: $target',
    ),
    VersionReplacement(
      'example/web/llms.txt',
      'jaspr_hooks: ^$current',
      'jaspr_hooks: ^$target',
    ),
  ];

  final updatedFiles = <String>{};
  for (final replacement in replacements) {
    final file = File('${root.path}/${replacement.path}');
    if (!file.existsSync()) _fail('Missing ${replacement.path}.');
    final before = file.readAsStringSync();
    final occurrences = replacement.source.allMatches(before).length;
    if (occurrences != 1) {
      _fail(
        'Expected one ${replacement.source} occurrence in '
        '${replacement.path}, found $occurrences.',
      );
    }
    if (!dryRun) {
      file.writeAsStringSync(before.replaceFirst(replacement.source, replacement.target));
    }
    updatedFiles.add(replacement.path);
  }

  final action = dryRun ? 'Would bump' : 'Bumped';
  stdout.writeln('$action jaspr_hooks from $current to $target.');
  for (final path in updatedFiles) {
    stdout.writeln('- $path');
  }
}

final class VersionReplacement {
  const VersionReplacement(this.path, this.source, this.target);

  final String path;
  final String source;
  final String target;
}

final class PackageVersion implements Comparable<PackageVersion> {
  const PackageVersion(
    this.major,
    this.minor,
    this.patch,
    this.prerelease,
    this.source,
  );

  factory PackageVersion.parse(String source) {
    final match = RegExp(
      r'^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)'
      r'(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?'
      r'(?:\+[0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*)?$',
    ).firstMatch(source);
    if (match == null) _fail('Invalid semantic version: $source.');
    return PackageVersion(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
      match.group(4)?.split('.'),
      source,
    );
  }

  final int major;
  final int minor;
  final int patch;
  final List<String>? prerelease;
  final String source;

  String get stable => '$major.$minor.$patch';

  @override
  int compareTo(PackageVersion other) {
    for (final comparison in <int>[
      major.compareTo(other.major),
      minor.compareTo(other.minor),
      patch.compareTo(other.patch),
    ]) {
      if (comparison != 0) return comparison;
    }
    if (prerelease == null) return other.prerelease == null ? 0 : 1;
    if (other.prerelease == null) return -1;
    final sharedLength = prerelease!.length < other.prerelease!.length ? prerelease!.length : other.prerelease!.length;
    for (var index = 0; index < sharedLength; index++) {
      final comparison = _compareIdentifier(
        prerelease![index],
        other.prerelease![index],
      );
      if (comparison != 0) return comparison;
    }
    return prerelease!.length.compareTo(other.prerelease!.length);
  }

  int _compareIdentifier(String left, String right) {
    final leftNumber = int.tryParse(left);
    final rightNumber = int.tryParse(right);
    if (leftNumber != null && rightNumber != null) {
      return leftNumber.compareTo(rightNumber);
    }
    if (leftNumber != null) return -1;
    if (rightNumber != null) return 1;
    return left.compareTo(right);
  }

  @override
  String toString() => source;
}

String _releaseNotice(PackageVersion version) {
  if (version.prerelease == null) {
    return '> Current stable release: `$version`.';
  }
  return '> `$version` is a preview. The API is intentionally being validated in real\n'
      '> Jaspr applications before `${version.stable}`.';
}

Never _fail(String message) {
  stderr.writeln(message);
  exit(64);
}
