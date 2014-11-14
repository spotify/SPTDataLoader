#import <UIKit/UIKit.h>

@class SPTDataLoaderService;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong, readonly) SPTDataLoaderService *service;

@end

