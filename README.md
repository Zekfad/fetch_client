# Fetch Client

[![pub package](https://img.shields.io/pub/v/fetch_client.svg)](https://pub.dev/packages/fetch_client)
[![package publisher](https://img.shields.io/pub/publisher/fetch_client.svg)](https://pub.dev/packages/fetch_client/publisher)

This package provides [package:http](https://pub.dev/packages/http) client based
on [Fetch API](https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API) with
WASM support.

It's a drop-in solution for extensions with
[Manifest V3](https://developer.chrome.com/docs/extensions/mv3/intro/#introducing-manifest-v3).

## Features

* WASM-ready internals.
* Cancel requests.
* Support data streaming:
  * Get response as `Stream`.
  * Optionally, send `Stream` as request body (supported only in Chromium 105+
    based browsers).
* Get access to redirect URL and status.
* Support non-`200` responses (`fetch` will only fail on network errors).
* Simulate redirects responses via probe request and artificial `location`
  header.

## Notes

### Large payload

This module maps `keepalive` to [`BaseRequest.persistentConnection`](https://pub.dev/documentation/http/latest/http/BaseRequest/persistentConnection.html)
which is **`true`** by default.

Fetch spec says that maximum request size with `keepalive` flag is 64KiB:

> __4.5. HTTP-network-or-cache fetch__
>
> > 8.10.5: If the sum of _contentLength_ and _inflightKeepaliveBytes_ is greater
> > than 64 kibibytes, then return a [network error](https://fetch.spec.whatwg.org/#concept-network-error).
> 
> _Source: [Fetch. Living Standard — Last Updated 19 June 2023](https://fetch.spec.whatwg.org/#http-network-or-cache-fetch)_

Therefore if your request is larger than 64KiB (this includes some other data,
such as headers) [`BaseRequest.persistentConnection`](https://pub.dev/documentation/http/latest/http/BaseRequest/persistentConnection.html)
will be ignored and treated as `false`.

### Request streaming

Request streaming is supported only in Chromium 105+ based browsers and
requires the server to use HTTP/2 or HTTP/3.

See [MDN compatibility chart](https://developer.mozilla.org/en-US/docs/Web/API/Request#browser_compatibility)
and [Chrome Developers' blog](https://developer.chrome.com/articles/fetch-streaming-requests/#doesnt-work-on-http1x) for more info.
