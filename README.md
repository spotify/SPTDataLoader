<img alt="SPTDataLoader" src="banner@2x.png" width="100%" max-width="888">

[![Build Status](https://api.travis-ci.org/spotify/SPTDataLoader.svg)](https://travis-ci.org/spotify/SPTDataLoader)
[![Coverage Status](https://coveralls.io/repos/spotify/SPTDataLoader/badge.svg?branch=master&service=github)](https://coveralls.io/github/spotify/SPTDataLoader?branch=master)
[![Documentation](https://img.shields.io/cocoapods/metrics/doc-percent/SPTDataLoader.svg)](http://cocoadocs.org/docsets/SPTDataLoader/)
[![License](https://img.shields.io/github/license/spotify/SPTDataLoader.svg)](LICENSE)
[![Cocoapods](https://img.shields.io/cocoapods/v/SPTDataLoader.svg)](https://cocoapods.org/?q=SPTDataLoader)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Spotify FOSS Slack](https://slackin.spotify.com/badge.svg)](https://slackin.spotify.com)

Authentication and back-off logic is a pain, let's do it once and forget about it! This is a library that allows you to centralise this logic and forget about the ugly parts of making HTTP requests.

- [x] 📱 iOS 7.0+
- [x] 💻 OS X 10.8+
- [x] ⌚️ watchOS 2.0+
- [x] 📺 tvOS 9.0+

## Architecture :triangular_ruler:
`SPTDataLoader` is designed as an HTTP stack with 3 additional layers on top of `NSURLSession`.

- **The Application level**, which controls the rate limiting and back-off policies per service, respecting the “Retry-After” header and knowing when or not it should retry the request.
- **The User level**, which controls the authentication of the HTTP requests.
- **The View level**, which allows automatic cancellation of requests the view has made upon deallocation.

### Authentication :key:
The authentication in this case is abstract, allowing the creator of the SPTDataLoaderFactory to define their own semantics for token acquisition and injection. It allows for asynchronous token acquisition if the token is invalid that seamlessly integrates with the HTTP request-response pattern.

### Back-off policy :cop:
The data loader service allows rate limiting of URLs to be set explicitly or to be determined by the server using the “Retry-After” semantic. It allows back-off retrying by using a jittered exponential backoff to prevent the thundering hordes creating a request storm after a predictable exponential period has expired.

## Installation
SPTDataLoader can be installed in a variety of ways including traditional static libraries and dynamic frameworks. As well as using either of the dependency managers Cocoapods and Carthage.

### Static Library
Simply include `SPTDataLoader.xcodeproj` in your App’s Xcode project, and link your app with the library in the “Build Phases” section.

### CocoaPods
We are indexed on [CocoaPods](http://cocoapods.org), which can be installed using [Ruby gems](https://rubygems.org/):
```shell
$ gem install cocoapods
```
Then simply add `SPTDataLoader` to your `Podfile`.
```
pod 'SPTDataLoader', '~> 1.0'
```
Lastly let CocoaPods do it thing by running:
```shell
$ cocoapods update
```

### Carthage
We support [Carthage](https://github.con/Carthage/Carthage) and provide pre-built binary frameworks for all new releases. Start by making sure you have the latest version of Carthage installed, e.g. using [Homebrew](http://brew.sh/):
```shell
$ brew update
$ brew install carthage
```
You will also need to add `SPTDataLoader` to your `Cartfile`:
```
github 'spotify/SPTDataLoader' ~> 1.0
```
After that is all said and done, let Carthage pull in SPTDataLoader like so:
```shell
$ carthage update
```
Next up, you need to add the framework to the Xcode project of your App. Lastly link the framework with your App and copy it to the App’s Frameworks directory under the “Build Phases”.

## Usage example :eyes:
For an example of this framework's usage, see the demo application `SPTDataLoaderDemo` in `SPTDataLoader.xcodeproj`. Just follow the instructions in [`ClientKeys.h`](demo/ClientKeys.h).

## Background story :book:
At Spotify we have begun moving to a decentralised HTTP architecture, and in doing so have had some growing pains. Initially we had a data loader that would attempt to refresh the access token whenever it became invalid, but we immediately learned this was very hard to keep track of. We needed some way of injecting this authorisation data automatically into a HTTP request that didn't require our features to do any more heavy lifting than they were currently doing.

Thus we came up with a way to elegantly inject tokens in a Just-in-time manner for requests that require them. We also wanted to learn from our mistakes with our proprietary protocol, and bake in back-off policies early to avoid us DDOSing our own backends with huge amounts of eronious requests.

## Documentation :books:
See the [`SPTDataLoader` documentation](http://cocoadocs.org/docsets/SPTDataLoader) on [CocoaDocs.org](http://cocoadocs.org) for the full documentation.

You can also add it to [Dash](https://kapeli.com/dash) if you want to, using the following Dash feed:
```
dash-feed://http%3A%2F%2Fcocoadocs.org%2Fdocsets%2FSPTDataLoader%2FSPTDataLoader.xml
```

## Contributing :mailbox_with_mail:
Contributions are welcomed, have a look at the [CONTRIBUTING.md](CONTRIBUTING.md) document for more information.

## License :memo:
The project is available under the [Apache 2.0](http://www.apache.org/licenses/LICENSE-2.0) license.
