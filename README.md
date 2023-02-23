# Fetch Client

This package provides [package:http](https://pub.dev/packages/http) client based
on [Fetch API](https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API).

It's a drop-in solution for extensions with
[Manifest V3](https://developer.chrome.com/docs/extensions/mv3/intro/#introducing-manifest-v3).

## Features

* Cancel requests.
* Support data streaming:
  * Get response as `Stream`.
  * Optionally send `Stream` as request body. 
* Get access to redirect URL and status.
* Support non-`200` responses (fetch will only fail on network error).
* Simulate redirects responses via probe request and artificial `location`
  header.
