/*
 Copyright 2015-2023 Spotify AB

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import <Foundation/Foundation.h>

@class SPTDataLoaderResponse;

NS_ASSUME_NONNULL_BEGIN

/**
 The protocol an observer of the data loaders consumption must conform to
 */
@protocol SPTDataLoaderConsumptionObserver <NSObject>

/**
 Called when a request ends (either via cancel or receiving a server response
 @param response The response the request was ended with
 @param bytesDownloaded The amount of bytes downloaded
 @param bytesUploaded The amount of bytes uploaded
 */
- (void)endedRequestWithResponse:(SPTDataLoaderResponse *)response
                 bytesDownloaded:(int)bytesDownloaded
                   bytesUploaded:(int)bytesUploaded;

@end

NS_ASSUME_NONNULL_END
