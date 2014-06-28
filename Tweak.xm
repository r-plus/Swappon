#import <ColorLog.h>
#import <UIKit/UIGestureRecognizerSubclass.h>

// interfaces {{{
@interface SpringBoard
- (BOOL)launchApplicationWithIdentifier:(id)arg1 suspended:(BOOL)arg2;
@end

@interface SBApplication
@end

@interface SBIcon : NSObject
- (void)launchFromLocation:(int)location;
- (BOOL)isFolderIcon;// iOS 4+
- (NSString *)applicationBundleID;
- (SBApplication *)application;
@end

@interface SBFolder : NSObject
- (SBIcon *)iconAtIndexPath:(NSIndexPath *)indexPath;
@end

@interface SBIconView : UIView
@property(retain, nonatomic) SBIcon *icon;// iOS 5+
@property(assign, getter = isHighlighted) BOOL highlighted;
@end

@interface SBFolderIcon : NSObject
- (SBFolder *)folder;
@end

@interface SBFolderIconView : SBIconView
- (SBFolderIcon *)folderIcon;
@end

@interface SBAppSliderController
@end

@interface SBUIController
+ (id)sharedInstance;
- (void)appSwitcher:(SBAppSliderController *)arg1 wantsToActivateApplication:(NSString *)arg2;
- (void)activateApplicationAnimatedFromIcon:(SBApplication *)arg1 fromLocation:(int)arg2;
- (void)activateApplicationAnimated:(SBApplication *)application;
@end

@interface SBIconController
- (void)openFolder:(id)arg1 animated:(_Bool)arg2;
@end
// }}}

@interface SWPSwipeGestureRecognizer : UISwipeGestureRecognizer// {{{
@end
@implementation SWPSwipeGestureRecognizer
- (BOOL)canBePreventedByGestureRecognizer:(UIGestureRecognizer *)preventingGestureRecognizer
{
    return NO;
}
@end
// }}}

// global vars {{{
static NSString * const kPrefPath = @"/var/mobile/Library/Preferences/jp.r-plus.Swappon.plist";
static CFStringRef const kNotificationName = CFSTR("jp.r-plus.Swappon.settingschanged");
static int swipeUpAppLocation;
static int swipeDownAppLocation;
static int swipeLeftAppLocation;
static int swipeRightAppLocation;
// }}}

// hooks {{{
%hook SBIconView 
- (void)setLocation:(int)location
{
    %orig;

    if ([self.icon isFolderIcon]) {
        SWPSwipeGestureRecognizer *swipe = [[SWPSwipeGestureRecognizer alloc] initWithTarget:self action:@selector(SWPSwipeGesture:)];
        swipe.direction = UISwipeGestureRecognizerDirectionUp;
        [self addGestureRecognizer:swipe];
        [swipe release];

        swipe = [[SWPSwipeGestureRecognizer alloc] initWithTarget:self action:@selector(SWPSwipeGesture:)];
        swipe.direction = UISwipeGestureRecognizerDirectionDown;
        [self addGestureRecognizer:swipe];
        [swipe release];

        swipe = [[SWPSwipeGestureRecognizer alloc] initWithTarget:self action:@selector(SWPSwipeGesture:)];
        swipe.direction = UISwipeGestureRecognizerDirectionLeft;
        [self addGestureRecognizer:swipe];
        [swipe release];

        swipe = [[SWPSwipeGestureRecognizer alloc] initWithTarget:self action:@selector(SWPSwipeGesture:)];
        swipe.direction = UISwipeGestureRecognizerDirectionRight;
        [self addGestureRecognizer:swipe];
        [swipe release];
    }
}

%new
- (void)SWPSwipeGesture:(SWPSwipeGestureRecognizer *)gesture
{
    int targetAppLocation = -1;
    switch (gesture.direction) {
        case UISwipeGestureRecognizerDirectionUp:
            targetAppLocation = swipeUpAppLocation;
            break;
        case UISwipeGestureRecognizerDirectionDown:
            targetAppLocation = swipeDownAppLocation;
            break;
        case UISwipeGestureRecognizerDirectionLeft:
            targetAppLocation = swipeLeftAppLocation;
            break;
        case UISwipeGestureRecognizerDirectionRight:
            targetAppLocation = swipeRightAppLocation;
            break;
    }
    if (targetAppLocation == -1)
        return;

    if (targetAppLocation == 100) {
        [[%c(SBIconController) sharedInstance] openFolder:((SBFolderIconView *)gesture.view).folderIcon.folder animated:YES];
    } else {
        SBIcon *targetIcon = [((SBFolderIconView *)gesture.view).folderIcon.folder iconAtIndexPath:[NSIndexPath indexPathForRow:targetAppLocation inSection:0]];
        [targetIcon launchFromLocation:0];
    }
    //[[%c(SBUIController) sharedInstance] activateApplicationAnimated:[targetIcon application]];
    //[[%c(SBUIController) sharedInstance] activateApplicationAnimatedFromIcon:[targetIcon application] fromLocation:0];
    //[(SpringBoard *)[%c(UIApplication) sharedApplication] launchApplicationWithIdentifier:[targetIcon applicationBundleID] suspended:NO];
    //SBUIController *c = [%c(SBUIController) sharedInstance];
    //SBAppSliderController *a = MSHookIvar<SBAppSliderController *>(c, "_switcherController");
    //[c appSwitcher:a wantsToActivateApplication:[targetIcon applicationBundleID]];
}
%end
// }}}
// LoadSettings {{{
static void LoadSettings()
{
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:kPrefPath];
    id swipeUpPref = [dict objectForKey:@"SwipeUp"];
    swipeUpAppLocation = swipeUpPref ? [swipeUpPref intValue] : 0;
    id swipeDownPref = [dict objectForKey:@"SwipeDown"];
    swipeDownAppLocation = swipeDownPref ? [swipeDownPref intValue] : 1;
    id swipeLeftPref = [dict objectForKey:@"SwipeLeft"];
    swipeLeftAppLocation = swipeLeftPref ? [swipeLeftPref intValue] : -1;
    id swipeRightPref = [dict objectForKey:@"SwipeRight"];
    swipeRightAppLocation = swipeRightPref ? [swipeRightPref intValue] : -1;
}

static void PostNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
    LoadSettings();
}

%ctor
{
    @autoreleasepool {
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PostNotification, kNotificationName, NULL, CFNotificationSuspensionBehaviorCoalesce);
        LoadSettings();
    }
}
// }}}
