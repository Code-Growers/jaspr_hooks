---
name: bump-pub-version
description: Prepare and validate a jaspr_hooks pub.dev release by reviewing changes, selecting the next SemVer version, updating every package-version reference, refreshing resolved dependencies, checking the changelog, and running release gates. Use when asked to bump, release, publish, tag, or prepare a new jaspr_hooks package version.
---

# Bump Pub Version

Prepare a release from the repository root. Keep version selection, human-facing release notes, generated dependency state, and publication checks consistent.

## Review the release delta

1. Read `pubspec.yaml`, `CHANGELOG.md`, `CONTRIBUTING.md`, and `tool/release_preflight.dart`.
2. Inspect `git status`, the diff, recent commits, and tags. Never discard unrelated user changes.
3. Summarize user-visible changes before choosing a version.
4. Query `dart pub outdated` in both the root and `example/`. Upgrade only mutually compatible dependencies and preserve the documented Jaspr compatibility range unless the user explicitly expands it.

## Select the version

- Increment the prerelease counter for fixes, docs, tests, or release tooling while the package remains a preview, such as `0.1.0-dev.1` to `0.1.0-dev.2`.
- Increment the minor version for backward-compatible public API additions after stable release.
- Increment the patch version for backward-compatible stable fixes.
- Increment the major version for breaking stable API or semantic changes.
- Promote a validated preview to its matching stable version only when the user explicitly approves promotion.

Explain the choice. Do not silently promote a preview to stable.

## Apply the bump

1. Add a new top section to `CHANGELOG.md` for the target version. Describe only changes introduced since the previous version.
2. Preview deterministic replacements:

   ```sh
   dart run .agents/skills/bump-pub-version/scripts/bump_pub_version.dart <version> --dry-run
   ```

3. Apply them:

   ```sh
   dart run .agents/skills/bump-pub-version/scripts/bump_pub_version.dart <version>
   ```

4. Run `dart pub get` from `example/` so its committed lockfile records the path package's new version.
5. If the package has not been published yet, update the manual first-release version in `CONTRIBUTING.md`.
6. Search the repository for stale current-version references. Historical changelog entries and the recorded first manual release must remain unchanged.

## Validate the release

Run all applicable gates:

```sh
dart format --output=none --set-exit-if-changed .
dart analyze --fatal-infos
dart test --exclude-tags browser
dart test --platform chrome test/browser_lifecycle_test.dart
dart doc --validate-links
dart run tool/verify_package_layout.dart
dart run tool/verify_publish_dry_run.dart
cd example && dart test && jaspr build
cd ../e2e && npm ci && npm run typecheck && npm test
```

For a first publication, also run:

```sh
dart run tool/release_preflight.dart --check-name-available
```

All releases are published manually with `dart pub publish`. Create the matching
`v<pubspec version>` tag only after pub.dev confirms the release.

## Hand off safely

- Show the final version, changelog entry, dependency changes, validation results, and remaining external publication requirements.
- Check commit messages for `Co-authored-by:` trailers and never add them.
- Do not publish, tag, or push unless the user explicitly requested that external action.
