#import <Foundation/Foundation.h>

@class PlaylistsViewModel;
@class SPTDataLoader;

@protocol PlaylistsViewModelDelegate <NSObject>

- (void)playlistsViewModelDidLoad:(PlaylistsViewModel *)model;

@end

@interface PlaylistsViewModel : NSObject

@property (nonatomic, weak) id<PlaylistsViewModelDelegate> delegate;
@property (nonatomic, assign, readonly, getter = isLoaded) BOOL loaded;
@property (nonatomic, strong, readonly) NSArray *items;

- (instancetype)initWithDataLoader:(SPTDataLoader *)dataLoader;

- (void)load;

@end
