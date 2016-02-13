<img alt="SPTDataLoader" src="banner@2x.png" width="100%" max-width="888">

[![Build Status](https://api.travis-ci.org/spotify/SPTDataLoader.svg)](https://travis-ci.org/spotify/SPTDataLoader)
[![Coverage Status](https://coveralls.io/repos/spotify/SPTDataLoader/badge.svg?branch=master&service=github)](https://coveralls.io/github/spotify/SPTDataLoader?branch=master)
[![Documentation](https://img.shields.io/cocoapods/metrics/doc-percent/SPTDataLoader.svg)](http://cocoadocs.org/docsets/SPTDataLoader/)
[![License](https://img.shields.io/github/license/spotify/SPTDataLoader.svg)](LICENSE)
[![CocoaPods](https://img.shields.io/cocoapods/v/SPTDataLoader.svg)](https://cocoapods.org/?q=SPTDataLoader)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Spotify FOSS Slack](https://slackin.spotify.com/badge.svg)](https://slackin.spotify.com)
[![Readme Score](http://readme-score-api.herokuapp.com/score.svg?url=https://github.com/spotify/sptdataloader)](http://clayallsopp.github.io/readme-score?url=https://github.com/spotify/sptdataloader)

Authentication and back-off logic is a pain, let's do it once and forget about it! This is a library that allows you to centralise this logic and forget about the ugly parts of making HTTP requests.

- [x] 📱 iOS 7.0+
- [x] 💻 OS X 10.9+
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
SPTDataLoader can be installed in a variety of ways including traditional static libraries and dynamic frameworks. As well as using either of the dependency managers CocoaPods and Carthage.

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

### Creating the SPTDataLoaderService
In your app you should only have 1 instance of SPTDataLoaderService, ideally you would construct this in something similar to an AppDelegate. It takes in a rate limiter, resolver, user agent and an array of NSURLProtocols. The rate limiter allows objects outside the service to change the rate limiting for different endpoints, the resolver allows overriding of host names, and the array of NSURLProtocols allows support for protocols other than http/s.
```objc
SPTDataLoaderRateLimiter *rateLimiter = [SPTDataLoaderRateLimiter rateLimiterWithDefaultRequestsPerSecond:10.0];
SPTDataLoaderResolver *resolver = [SPTDataLoaderResolver new];
self.service = [SPTDataLoaderService dataLoaderServiceWithUserAgent:@"Spotify-Demo"
                                                        rateLimiter:rateLimiter
                                                           resolver:resolver
                                           customURLProtocolClasses:nil];
```
Note that you can provide all these as nils if you are so inclined, it may be for the best to use nils until you identify a need for these different configuration options.

### Defining your own SPTDataLoaderAuthoriser
If you don't need to authenticate your requests you can skip this. In order to authenticate your requests against a backend, you are required to create an implementation of the SPTDataLoaderAuthoriser, the demo project has an example in its SPTDataLoaderAuthoriserOAuth class. In this example we are checking if the request is for the domain which we are attempting to authenticate for, and then performing the authentication (in this case we are injecting an Auth Token into the HTTP header). This interface is asynchronous to allow you to perform token refreshes while a request is in flight in order to hold it until it is ready to be authenticated. Once you have a valid token you can call the delegate (which in this case will be the factory) in order to inform it that the request has been authenticated. Alternatively if you are unable to authenticate the request tell the delegate about the error.

### Creating the SPTDataLoaderFactory
Your app should ideally only create an SPTDataLoaderFactory once your user has logged in or if you require no authentication for your calls. The factory controls the authorisation of the different requests against authoriser objects that you construct.
```objc
id<SPTDataLoaderAuthoriser> oauthAuthoriser = [[SPTDataLoaderAuthoriserOAuth alloc] initWithDictionary:oauthTokenDictionary];
self.oauthFactory = [self.service createDataLoaderFactoryWithAuthorisers:@[ oauthAuthoriser ]];
```
What we are doing here is using an implementation of an authoriser to funnel all the requests created by this factory into these authorisers.

### Creating the SPTDataLoader
Your app should create an SPTDataLoader object per view that wants to make requests (e.g. it is best not too share these between classes). This is so when your view model is deallocated the requests made by your view model will also be cancelled.
```objc
SPTDataLoader *dataLoader = [self.oauthFactory createDataLoader];
```
Note that this data loader will only authorise requests that are made available by the authorisers supplied to its factory.

### Creating the SPTDataLoaderRequest
In order to create a request the only information you will need is the URL and where the request came from. For more advanced requests see the properties on SPTDataLoaderRequest which let you change the method, timeouts, retries and whether to stream the results.
```objc
SPTDataLoaderRequest *request = [SPTDataLoaderRequest requestWithURL:meURL
                                                    sourceIdentifier:@"playlists"];
[self.dataLoader performRequest:request];
```
After you have made the request your data loader will call its delegate regarding results of the requests.

### Handling Streamed Requests
Sometimes you will want to process HTTP requests as they come in packet by packet rather than receive a large callback at the end, this works better for memory and certain forms of media. For Spotify's purpose, it works for streaming MP3 previews of our songs. An example of using the streaming API:
```objc
void AudioSampleListener(void *, AudioFileStreamID, AudioFileStreamPropertyID, UInt32 *);
void AudioSampleProcessor(void *, UInt32, UInt32, const void *, AudioStreamPacketDescription *);

- (void)load
{
    NSURL *URL = [NSURL URLWithString:@"http://i.spotify.com/mp3_preview"];
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest requestWithURL:URL sourceIdentifier:@"preview"];
    request.chunks = YES;
    [self.dataLoader performRequest:request];
}

- (void)dataLoader:(SPTDataLoader *)dataLoader
didReceiveDataChunk:(NSData *)data
       forResponse:(SPTDataLoaderResponse *)response
{
    void *mp3Data = calloc(data.length, 1);
    memcpy(mp3Data, data.bytes, data.length);
    AudioFileStreamParseBytes(_audioFileStream, data.length, mp3Data, 0);
    free(mp3Data);
}

- (void)dataLoader:(SPTDataLoader *)dataLoader didReceiveInitialResponse:(SPTDataLoaderResponse *)response
{
    AudioFileStreamOpen((__bridge void *)self,
                        AudioSampleListener,
                        AudioSampleProcessor,
                        kAudioFileMP3Type,
                        &_audioFileStream);
}

- (BOOL)dataLoaderShouldSupportChunks:(SPTDataLoader *)dataLoader
{
    return YES;
}
```
Be sure to render YES in your delegate to tell the data loader that you support chunks, and to set the requests chunks property to YES.

### Rate limiting specific endpoints
If you specify a rate limiter in your service, you can give it a default requests per second metric which it applies to all requests coming out your app. (See “[Creating the `SPTDataLoaderService`](#creating-the-sptdataloaderservice)”). However, you can also specify rate limits for specific HTTP endpoints, which may be useful if you want to forcefully control the rate at which clients can make requests to a backend that does large amounts of work.
```objc
SPTDataLoaderRateLimiter *rateLimiter = [SPTDataLoaderRateLimiter rateLimiterWithDefaultRequestsPerSecond:10.0];
NSURL *URL = [NSURL URLWithString:@"http://www.spotify.com/thing/thing"];
[rateLimiter setRequestsPerSecond:1 forURL:URL];
```
It should be noted that when you set the requests per second for a URL, it takes the host, and the first component of the URL and rate limits everything that fits that description.

### Switching Hosts for all requests
The SPTDataLoaderService takes in a resolver object as one of its arguments. If you choose to make this non-nil, then you can switch the hosts of different requests as they come in. At Spotify we have a number of DNS matches our requests can go through, giving us backups and failsafes in case one of these machines go down. These operations happen in the SPTDataLoaderResolver, where you can specify a number of alternative addresses for the host. An example of Spotify specifying alternative endpoints for its hosts could be:
```objc
SPTDataLoaderResolver *resolver = [SPTDataLoaderResolver new];
NSArray *alternativeAddresses = @[ @"spotify.com",
                                   @"backup.spotify.com",
                                   @"backup2.spotify.com",
                                   @"backup3.spotify.com",
                                   @"192.168.0.1",
                                   @"final.spotify.com" ];
[resolver setAddresses:alternativeAddresses forHost:@"spotify.com"];
```
This allows any request made to spotify.com to use any one of these other addresses (in this order) if spotify.com becomes unreachable.

### Using the jittered exponential timer
This library contains a class called SPTDataLoaderExponentialTimer which it uses internally to perform backoffs with retries. The reason it is jittered is to prevent the "predictable thundering hoardes" from hammering our services if one of them happens to go down. In order to make use of this class, there are some do's and don'ts. For example, do not initialise the class like so:
```objc
SPTDataLoaderExponentialTimer *timer = [SPTDataLoaderExponentialTimer exponentialTimerWithInitialTime:0.0
                                                                                              maxTime:10.0];
NSTimeInterval backoffTime = 0.0;
for (int i = 0; i < 1000; ++i) {
    backoffTime = timer.timeIntervalAndCalculateNext;
}
```
This will result in the backoffTime remaining at 0. Why? Because 0.0 multiplied by an exponential number is still 0. A good initial time might be 0.5 or 1.0 seconds. You will also notice that the backoffTime will get further away from the raw exponential time the more times you calculate the next interval:
```objc
SPTDataLoaderExponentialTimer *timer = [SPTDataLoaderExponentialTimer exponentialTimerWithInitialTime:1.0
                                                                                              maxTime:1000.0];
NSTimeInterval backoffTime = 0.0;
for (int i = 0; i < 1000; ++i) {
    backoffTime = timer.timeIntervalAndCalculateNext;
}
```
This will result in a backoffTime that has drifted far away from its vanilla exponential calculation. Why? Because we add a random jitter to the calculations in order to prevent clients from connecting at the same time, in order to spread the load out evenly when experiencing a reconnect storm. The jitter gets greater along with the exponent.

### Consumption observation
SPTDataLoaderService allows you to add a consumption observer whose purpose is to monitor the data consumption of the service for both uploads and downloads. This object must conform to the SPTDataLoaderConsumptionObserver protocol. This is quite easy considering it is a single method like so:
```objc
- (void)load
{
    [self.service addConsumptionObserver:self];
}

- (void)unload
{
    [self.service removeConsumptionObserver:self];
}

- (void)endedRequestWithResponse:(SPTDataLoaderResponse *)response
                 bytesDownloaded:(int)bytesDownloaded
                   bytesUploaded:(int)bytesUploaded
{
    NSLog(@"Bytes Downloaded: %d", bytesDownloaded);
    NSLog(@"Bytes Uploaded: %d", bytesUploaded);
}
```
Also note that this isn't just the payload, it also includes the headers.

### Creating a custom authoriser
The SPTDataLoader architecture is designed to centralise authentication around the user level (in this case represented by the factory). In order to do that you must inject an authoriser you made yourself into the factory when it is created. An authoriser in most cases will be injecting an Authorisation header into any request it wants to authorise. An example below shows how a standard authoriser might be constructed for an OAuth flow.
```objc
@synthesize delegate = _delegate;

- (NSString *)identifier
{
    return @"OAuth";
}

- (BOOL)requestRequiresAuthorisation:(SPTDataLoaderRequest *)request
{
    // Here we check the hostname to see if it one of the hostnames we authorise against
    // It is also advisable to check whether we are using HTTPS, if we are not we should not inject our Authorisation
    // header in order to keep it secret from prying eyes
    return [request.URL.host isEqualToString:@"myauth.com"] && [request.URL.scheme isEqualToString:@"https"];
}

- (void)authoriseRequest:(SPTDataLoaderRequest *)request
{
    [request addValue:@"My Token" forHeader:@"Authorization"];
    [self.delegate dataLoaderAuthoriser:self authorisedRequest:request];
}

- (void)requestFailedAuthorisation:(SPTDataLoaderRequest *)request
{
    // This tells us that the server returned a 400 error code indicating that the authorisation did not work
    // Commonly this means you should attempt to get another authorisation token
}

- (void)refresh
{
    // Forces a refresh of the authorisation token
}
```
As you can see all we are doing here is playing with the headers. It should be noted that if you receive an authoriseRequest: call the rest of the request will not execute until you have either sent the delegate a signal telling it the request has been authorised or failed to be authorised.

## Background story :book:
At Spotify we have begun moving to a decentralised HTTP architecture, and in doing so have had some growing pains. Initially we had a data loader that would attempt to refresh the access token whenever it became invalid, but we immediately learned this was very hard to keep track of. We needed some way of injecting this authorisation data automatically into a HTTP request that didn't require our features to do any more heavy lifting than they were currently doing.

Thus we came up with a way to elegantly inject tokens in a Just-in-time manner for requests that require them. We also wanted to learn from our mistakes with our proprietary protocol, and bake in back-off policies early to avoid us DDOSing our own backends with huge amounts of eronious requests.

### Why no block interface?
We had some block interfaces on our proprietary protocol library, and what we noticed was that it was easy to miss the weakification of the variables used in the blocks, which caused view models to be held around in memory far longer than they should have been.
Another problem was whether we should use one block or multiple blocks for failures/successes, and what we learned from our old API was that developers could tend to miss failure states from a single block interface (e.g. handle an NSError passed in). Good examples of are animation blocks on UIView that do not take into account the failed BOOL passed in. This makes it necessary to use multiple blocks, however we wanted a contract where the developer was guaranteed to get a callback from the data loader on any of its ending states (even if they put in a nil to the request blocks). The way we achieved this was the use of the delegate pattern.
Unfortunately the block pattern is useful in a number of different scenarios, however it is far from our main use case at Spotify. To support this we would like to point out that someone can give the userInfo of a request a block and then call that block on the delegate callback if they were so inclined (we have one or two examples of this on our codebase).
```objc
- (void)load
{
    UILabel *label = [self findLabel];
    NSURL *URL = [NSURL URLWithString:@"https://www.spotify.com"];
    SPTDataLoaderRequest *request = [SPTDataLoaderRequest requestWithURL:URL sourceIdentifier:@"spotify"];
    dispatch_block_t block = ^ {
        label.text = @"Loaded";
    };
    request.userInfo = @{ @"block" : block };
    [self.dataLoader performRequest:request];
}

- (void)dataLoader:(SPTDataLoader *)dataLoader didReceiveSuccessfulResponse:(SPTDataLoaderResponse *)response
{
    dispatch_block_t block = response.request.userInfo[@"block"];
    if (block) {
        block();
    }
}
```

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
