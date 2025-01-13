/*
 Copyright Spotify AB.
 SPDX-License-Identifier: Apache-2.0
 */

#import <UIKit/UIKit.h>

@class PlaylistsViewModel;

@interface PlaylistsViewController : UITableViewController

- (instancetype)initWithModel:(PlaylistsViewModel *)model;

@end
