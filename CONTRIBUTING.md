# Contributing to jaspr_hooks

Thanks for helping improve `jaspr_hooks`. Please discuss significant public API
or SSR semantic changes in an issue before opening a large pull request.

## Development setup

The reusable package supports Dart 3.8 and later. Use the latest stable Dart SDK
for normal development, then verify the lower bound before release.

```sh
dart pub get
dart format --output=none --set-exit-if-changed .
dart analyze
dart test
dart test -p chrome
```

To work on the documentation application:

```sh
cd example
dart pub get
jaspr serve
```

To exercise the production build:

```sh
cd example
jaspr build
cd ../e2e
npm ci
npx playwright test
```

## Release checklist

The first pub.dev release is deliberately manual. Before publishing it:

1. Add real `repository`, `issue_tracker`, and `documentation` HTTPS URLs to
   `pubspec.yaml`, and make sure the repository matches the `origin` remote.
2. Configure the package under a verified pub.dev publisher.
3. Recheck the package name immediately before publishing with
   `dart run tool/release_preflight.dart --check-name-available`.
4. Run every CI gate, `dart run tool/verify_publish_dry_run.dart`, and then
   publish `0.1.0-dev.1` manually with `dart pub publish`.
5. Validate the preview in multiple Jaspr applications before promoting it to
   `0.1.0`.

Only create a version tag after the first manual release. Tag builds require
the package to exist already and publish through the protected `pub.dev`
GitHub environment using OIDC.

## Hook changes

Every exported hook must include:

- API documentation describing keys, cleanup, and server/client behavior;
- deterministic component tests;
- browser or server tests where its environment contract differs;
- a page and interactive demo in the example catalog; and
- a changelog entry.

Hook calls are positional. Changes to preservation, ordering, disposal, effect
timing, or hydration behavior are public API changes even when function
signatures remain unchanged.

## Attribution

Substantially adapted upstream code must retain its source header and remain
covered by [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md). Do not add
Flutter SDK dependencies to the native package.
