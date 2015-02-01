# SPTDataLoader

## DESCRIPTION
Authentication and back-off logic is a pain, let's do it once and forget about it! This is a library that allows you to centralise this logic and forget about the ugly parts of making HTTP requests.

## LICENSE
[Apache 2](http://www.apache.org/licenses/LICENSE-2.0)

## BACKGROUND
At Spotify we have begun moving to a decentralised HTTP architecture, and in doing so have had some growing pains. Initially we had a data loader that would attempt to refresh the access token whenever it became invalid, but we immediately learned this was very hard to keep track of. We needed some way of injecting this authorisation data automatically into a HTTP request that didn't require our features to do any more heavy lifting than they were currently doing. Thus we came up with a way to elegantly inject tokens in a Just-in-time manner for requests that require them. We also wanted to learn from our mistakes with our proprietary protocol, and bake in back-off policies early to avoid us DDOSing our own backends with huge amounts of eronious requests.

## ARCHITECTURE
SPTDataLoader is designed as an HTTP stack with 3 additional layers on top of NSURLSession.
* The Application level, which controls the rate limiting and back-off policies per service, respecting the "Retry-After" header and knowing when or not it should retry the request.
* The User level, which controls the authentication of the HTTP requests.
* The View level, which allows automatic cancellation of requests the view has made upon deallocation

## AUTHENTICATION
The authentication in this case is abstract, allowing the creator of the SPTDataLoaderFactory to define their own semantics for token acquisition and injection. It allows for asynchronous token acquisition if the token is invalid that seamlessly integrates with the HTTP request/response pattern.

## BACK-OFF POLICY
The data loader service allows rate limiting of URLs to be set explicitly or to be determined by the server using the "Retry-After" semantic. It allows back-off retrying by using a jittered exponential backoff to prevent the thundering hordes creating a request storm after a predictable exponential period has expired.

## USAGE
For an example of this frameworks usage, see the demo application location in the "demo" folder.

## CREDITS
* Will Sackfield
* Dmitry Ponomarev
