## 1.1.1

- Bumped `fetch_api` to 2.1.0.
- Create internal shim for non-JS environments: you can now import package
  without conditional import and use enumerations in VM.
  This is makes it easier to use `FetchClient` in Flutter via `kIsWeb`.

## 1.1.0

> Requires Dart 3.3

- Migrate to [`fetch_api`](https://pub.dev/packages/fetch_api) 2.0.0.
  This requires Dart 3.3, but makes package WASM ready.
- Update [`http`](https://pub.dev/packages/http) constraint to `^1.2.0`.
- **BREAKING**: `FetchResponse` `url` now is `Uri` instead of `String`.
- `FetchResponse` now implements `BaseResponseWithUrl`.
- Fix unclosed requests after client is closed in-between fetch request.
- Fix `HEAD` request in FireFox.
- Handle response length checks.
- Add `FetchRequest` class that wraps other `Request` to provide fetch options
  overrides.
- Removed `integrity` from `FetchClient` constructor as it wasn't used, use
  `FetchRequest.integrity` instead.


## 1.0.2

- Update docs to clarify compatibility restrictions.

## 1.0.1

- Update [`http`](https://pub.dev/packages/http) constraint
  to `>=0.13.5 <2.0.0`.
- Update test.

## 1.0.0

- Public stable release.
- Bumped `fetch_api` to 1.0.0.

## 1.0.0-dev.5

- Added `RedirectPolicy`, that will make it possible to partially emulate how
  redirects are returned on `io` platforms.
- Added `streamRequests` option to `FetchClient`. This allows you to use Fetch
  request body streaming utilizing half-duplex connection.
- Fixed dev dependencies versions to allow running on Dart 2.19.

## 1.0.0-dev.4

- Bumped `fetch_api` dependency to `^1.0.0-dev.4`.
- Added conformance test.
- Full conformance with http client (with exclusion of streamed requests and
  redirects, due to API limitations).
- `FetchResponse`
  - `isRedirect` now is always `false` (because with disabled redirects
    exception is throws on redirect, and browser always follows redirects
    otherwise)
  - Added `redirected` flag, that indicates whether request was redirected.
  - Added docs.

## 1.0.0-dev.3

- Bumped `fetch_api` dependency to `^1.0.0-dev.3`.
- Use `fetch_api.compatibility_layer` to support Dart 2.19.
- Fixed name of example file.

## 1.0.0-dev.2

- Bumped `fetch_api` dependency to `^1.0.0-dev.2`.
  - Downgraded `js` dependency to `^0.6.5`.

## 1.0.0-dev.1

- Initial version.
