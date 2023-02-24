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

NS_ASSUME_NONNULL_BEGIN

/// Optional class to be provided to SPTDataLoaderService in order to add more infomation into crash logs.
@protocol SPTDataLoaderCrashReporter <NSObject>

/// Add a message to the breadcrumbs list.
- (void)leaveBreadcrumb:(NSString *)breadcrumb;

@end

NS_ASSUME_NONNULL_END
