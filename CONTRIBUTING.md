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

All pub.dev releases are deliberately manual:

1. Make sure `repository`, `issue_tracker`, and `documentation` contain the
   real HTTPS URLs and that `repository` matches the `origin` remote.
2. Run every CI gate and `dart run tool/verify_publish_dry_run.dart` from a
   clean checkout.
3. Run `dart run tool/release_preflight.dart` immediately before publishing.
4. Publish manually with `dart pub publish` from the verified publisher
   account.
5. Create and push the matching `v<version>` tag only after pub.dev confirms
   the release.

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
