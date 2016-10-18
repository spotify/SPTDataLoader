# Change Log
All notable changes to this project will be documented in this file. SPTDataLoader adheres to [Semantic Versioning](http://semver.org/).

--

## [1.1.1](https://github.com/spotify/SPTDataLoader/releases/tag/1.1.1)
_Released on 2016-02-20._

### Added
* Added support for SSL pinning.
* Added iOS 10 support.

### Fixed
* Fixed nil URLs in the rate limiter causing a crash.
* Fixed requests executing after they have been cancelled due to a race condition.
* Fixed unique identifiers incrementing by 2 on every request made.

### Removed
* Removed iOS 7.0 support.

## [1.1.0](https://github.com/spotify/SPTDataLoader/releases/tag/1.1.0)
_Released on 2016-02-15._

### Added
* Added support for watchOS and tvOS.
* Added error handling when a chunked request is made without the delegate supporting chunks.

### Fixed
* Fixed HTTP errors not being correctly reported if they are not above the 400 HTTP status codes.
* Fixed a bug allowing infinite retries of requests.

### Removed
* Removed the non-optional status of cancellation callbacks in the delegate.

### Changed
* Changed Accept-Language values to be publically accessible.
* Changed blanket HTTPS certificate accepting a runtime variable rather than a preprocessor macro.
* Changed the name of SPTCancellationToken to SPTDataLoaderCancellationToken.

## [1.0.1](https://github.com/spotify/SPTDataLoader/releases/tag/1.0.1)
_Released on 2015-12-22._

### Added
* Added an option to skip NSURLCache.
* Added absolute timeouts regardless of retries.
* Added a build flag option that can allow SPTDataLoader to ignore valid HTTPS certificates.
* Added source identifiers to request objects (for view based tracking of HTTP usage).
* Added support for custom URL protocols.
* Added clang module support.
* Added Accept-Language headers to all requests.
* Added redirection limit.
* Added sending the response rather than the request in the SPTDataLoaderConsumer protocol.

### Fixed
* Fixed a crash that can occur occasionally when copying data from NSURLSession.
* Fixed Xcode 6.2 project warnings.
* Fixed retry timeouts from firing constantly when certain conditions are met.
* Fixed Xcode 6.3 project warnings.
* Fixed crashes that can occur when calling SPTDataLoader from multiple threads.
* Fixed swallowing 401s if retrying is not possible.
* Fixed Xcode 7 warnings.
* Fixed HTTP redirects not working.

## [1.0.0](https://github.com/spotify/SPTDataLoader/releases/tag/1.0.0)
_Released on 2015-02-01._

### Added
* Initial release of SPTDataLoader.
