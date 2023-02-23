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
