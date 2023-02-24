//
//  SPTDataLoaderCrashReporterMock.m
//  SPTDataLoaderTests
//
//  Created by Gabriel Andreatto on 2023-02-17.
//  Copyright © 2023 Spotify. All rights reserved.
//

#import "SPTDataLoaderCrashReporterMock.h"

@implementation SPTDataLoaderCrashReporterMock

- (void)leaveBreadcrumb:(nonnull NSString *)breadcrumb {
    self.numberOfCallsToLeaveBreadcrumb++;
}

@end
