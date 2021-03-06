#import <UIKit/UIKit.h>

@interface MPUNowPlayingTitlesView : UIView
@end

@interface MPUMediaControlsTitlesView : MPUNowPlayingTitlesView
@end

@interface MPUMediaRemoteControlsView : UIView
@end

@interface MPULockScreenMediaControlsView : MPUMediaRemoteControlsView
- (void)handleGesticTouches:(UITapGestureRecognizer *)gesture;
- (void)handleGesticDrag:(UIPanGestureRecognizer *)gesture;
@end

@interface SBDashBoardScrollGestureController : NSObject
@end

@interface SBMediaController : NSObject
+ (instancetype)sharedInstance;
- (BOOL)togglePlayPause;
- (void)_changeVolumeBy:(float)vol;
- (BOOL)_sendMediaCommand:(unsigned)command;
@end

@interface VolumeControl : NSObject
+ (instancetype)sharedVolumeControl;
- (float)volumeStepDown;
- (float)volumeStepUp;
@end


static UIPanGestureRecognizer *gesticPan;
static UIView *gesticView;
static BOOL shouldLayoutSubviews = YES;

// Get a pan gesture as soon as we load since it's used in both the below init methods
%ctor {
    gesticPan = [UIPanGestureRecognizer new];
}

// Make sure our pan gesture recognizer gets touches before the lockscreen scroll view
%hook SBDashBoardScrollGestureController

- (id)initWithDashBoardView:(id)dbView systemGestureManager:(id)manager {
    self = %orig;
    
    UIGestureRecognizer *badGesture = [self valueForKey:@"_scrollViewGestureRecognizer"];
    [badGesture requireGestureRecognizerToFail:gesticPan];
    
    return self;
}

%end


%hook MPULockScreenMediaControlsView

- (id)initWithFrame:(CGRect)frame {
    self = %orig;
    
    [self setValue:NULL forKey:@"_transportControls"];
    
    UITapGestureRecognizer *oneTouch = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesticTouches:)];
    
    [gesticPan addTarget:self action:@selector(handleGesticDrag:)];
    
    gesticView = [[UIView alloc] initWithFrame:CGRectMake(0, 82, 366, 86)];
    [gesticView addGestureRecognizer:oneTouch];
    [gesticView addGestureRecognizer:gesticPan];
    
    [self addSubview:gesticView];
    
    return self;
}

%new
- (void)handleGesticTouches:(UITapGestureRecognizer *)gesture {
    CGPoint hitPoint = [gesture locationInView:self];
    CGFloat hitX = hitPoint.x;
    
    CGFloat const viewPOne = 122.0f;
    CGFloat const viewPTwo = 244.0f;
    
    VolumeControl *volControl = [objc_getClass("VolumeControl") sharedVolumeControl];
    SBMediaController *mediaControl = [objc_getClass("SBMediaController") sharedInstance];
    
    if (hitX < viewPOne) {
        [mediaControl _changeVolumeBy:-volControl.volumeStepDown];
    }
    
    if ((hitX > viewPOne) && (hitX < viewPTwo)) {
        SBMediaController *mediaControl = [objc_getClass("SBMediaController") sharedInstance];
        [mediaControl togglePlayPause];
    }
    
    if (hitX > viewPTwo) {
        [mediaControl _changeVolumeBy:volControl.volumeStepUp];
    }
}

%new
- (void)handleGesticDrag:(UIPanGestureRecognizer *)gesture {
    UIGestureRecognizerState gestState = gesture.state;
    
    if (gestState == UIGestureRecognizerStateBegan) {
        shouldLayoutSubviews = NO;
    }
    if (shouldLayoutSubviews) {
        return;
    }
    
    CGPoint translation = [gesture translationInView:gesticView];
    CGFloat newOX = translation.x;
    
    MPUMediaControlsTitlesView *titles = [self valueForKey:@"_titlesView"];
    
    CGRect resetFrame = CGRectMake(0, 102, 366, 46);
    BOOL gestCancelled = (gestState == UIGestureRecognizerStateCancelled);
    
    if ((gestState == UIGestureRecognizerStateEnded) || gestCancelled) {
        shouldLayoutSubviews = YES;
        
        __weak __typeof(self) weakself = self;
        void (^layoutSubviewsCompl)(UIViewAnimatingPosition finalPosition) = ^(UIViewAnimatingPosition finalPosition) {
            [weakself layoutSubviews];
        };
        
        BOOL back = (newOX < -232);
        BOOL skip = (newOX > 232);
        if ((back || skip) && !gestCancelled) {
            SBMediaController *mediaControl = [objc_getClass("SBMediaController") sharedInstance];
            [mediaControl _sendMediaCommand:(back ? 4 : 5)];
            
            CGRect skipFrame = resetFrame;
            skipFrame.origin.x = -400;
            CGRect backFrame = resetFrame;
            backFrame.origin.x = 424;
            
            [UIViewPropertyAnimator runningPropertyAnimatorWithDuration:0.075 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                titles.frame = back ? skipFrame : backFrame;
            } completion:^(UIViewAnimatingPosition finalPosition) {
                titles.frame = back ? backFrame : skipFrame;
                [UIViewPropertyAnimator runningPropertyAnimatorWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                    titles.frame = resetFrame;
                } completion:layoutSubviewsCompl];
            }];
        } else {
            [UIViewPropertyAnimator runningPropertyAnimatorWithDuration:(0.002 * ABS(newOX)) delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                titles.frame = resetFrame;
            } completion:layoutSubviewsCompl];
        }
    } else {
        resetFrame.origin.x = newOX;
        titles.frame = resetFrame;
    }
}

// Lower the title/author view down to about the middle
- (void)layoutSubviews {
    if (shouldLayoutSubviews) {
        %orig;
        
        MPUMediaControlsTitlesView *titles = [self valueForKey:@"_titlesView"];
        CGRect patchFrame = titles.frame;
        patchFrame.origin.y = 102;
        titles.frame = patchFrame;
    }
}

%end
