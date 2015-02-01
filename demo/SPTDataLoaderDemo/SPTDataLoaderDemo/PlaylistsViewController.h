#import <UIKit/UIKit.h>

@class PlaylistsViewModel;

@interface PlaylistsViewController : UITableViewController

- (instancetype)initWithModel:(PlaylistsViewModel *)model;

@end
