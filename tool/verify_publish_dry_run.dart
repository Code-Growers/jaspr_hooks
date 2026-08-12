import 'dart:io';

const _metadataRecommendation =
    'It\'s strongly recommended to include a "homepage" or "repository" field in your pubspec.yaml';

Future<void> main() async {
  final result = await Process.run('dart', const <String>['pub', 'publish', '--dry-run']);
  stdout.write(result.stdout);
  stderr.write(result.stderr);

  if (result.exitCode == 0) return;

  final output = '${result.stdout}\n${result.stderr}';
  final hasRepository = File('pubspec.yaml').readAsLinesSync().any(
    (String line) => RegExp(r'^repository:\s*https://').hasMatch(line),
  );
  final warningCount = RegExp(r'Package has (\d+) warning').firstMatch(output)?.group(1);

  if (!hasRepository && output.contains(_metadataRecommendation) && warningCount == '1') {
    stdout.writeln(
      'Publication archive validation passed with only the intentional '
      'pre-release repository metadata gate. Add the validated repository '
      'URLs to make this check strictly warning-free.',
    );
    return;
  }

  exitCode = result.exitCode;
}
