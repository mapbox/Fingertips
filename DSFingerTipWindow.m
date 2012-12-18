//
//  DSFingerTipWindow.m
//
//  Created by Justin R. Miller on 3/29/11.
//  Copyright 2011-2012 Development Seed. All rights reserved.
//

#import "DSFingerTipWindow.h"

// Turn this on to debug touches during development.
//
#ifdef TARGET_IPHONE_SIMULATOR
    #define DEBUG_FINGERTIP_WINDOW 0
#else
    #define DEBUG_FINGERTIP_WINDOW 0
#endif

@interface DSFingerTipView : UIImageView

@property (nonatomic, assign) NSTimeInterval timestamp;
@property (nonatomic, assign) BOOL shouldAutomaticallyRemoveAfterTimeout;
@property (nonatomic, assign, getter=isFadingOut) BOOL fadingOut;

@end

#pragma mark -

@interface DSFingerTipWindow ()

@property (nonatomic, strong) UIWindow *overlayWindow;
@property (nonatomic, assign) BOOL active;
@property (nonatomic, assign) BOOL fingerTipRemovalScheduled;

- (void)DSFingerTipWindow_commonInit;
- (BOOL)anyScreenIsMirrored;
- (void)updateFingertipsAreActive;
- (void)scheduleFingerTipRemoval;
- (void)cancelScheduledFingerTipRemoval;
- (void)removeInactiveFingerTips;
- (void)removeFingerTipWithHash:(NSUInteger)hash animated:(BOOL)animated;
- (BOOL)shouldAutomaticallyRemoveFingerTipForTouch:(UITouch *)touch;

@end

#pragma mark -

@implementation DSFingerTipWindow

@synthesize touchImage;
@synthesize touchAlpha;
@synthesize fadeDuration;
@synthesize overlayWindow;
@synthesize active;
@synthesize fingerTipRemovalScheduled;
@synthesize fillColor;
@synthesize strokeColor;

- (id)initWithCoder:(NSCoder *)decoder
{
    // This covers NIB-loaded windows.
    //
    self = [super initWithCoder:decoder];

    if (self != nil)
        [self DSFingerTipWindow_commonInit];
    
    return self;
}

- (id)initWithFrame:(CGRect)rect
{
    // This covers programmatically-created windows.
    //
    self = [super initWithFrame:rect];
    
    if (self != nil)
        [self DSFingerTipWindow_commonInit];
    
    return self;
}

- (void)DSFingerTipWindow_commonInit
{
    _strokeColor = [UIColor blackColor];
    _fillColor = [UIColor whiteColor];
    
    overlayWindow = [[UIWindow alloc] initWithFrame:self.frame];
    
    overlayWindow.userInteractionEnabled = NO;
    overlayWindow.windowLevel = UIWindowLevelStatusBar;
    overlayWindow.backgroundColor = [UIColor clearColor];
    overlayWindow.hidden = NO;

    touchAlpha   = 0.5;
    fadeDuration = 0.3;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(screenConnect:)
                                                 name:UIScreenDidConnectNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(screenDisconnect:)
                                                 name:UIScreenDidDisconnectNotification
                                               object:nil];

    // Set up active now, in case the screen was present before the window was created (or application launched).
    //
    [self updateFingertipsAreActive];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIScreenDidConnectNotification    object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIScreenDidDisconnectNotification object:nil];
}

#pragma mark -

- (UIImage *)touchImage
{
    if ( ! touchImage)
    {
        UIBezierPath *clipPath = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, 50.0, 50.0)];
        
        UIGraphicsBeginImageContextWithOptions(clipPath.bounds.size, NO, 0);

        UIBezierPath *drawPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(25.0, 25.0) 
                                                                radius:22.0
                                                            startAngle:0
                                                              endAngle:2 * M_PI
                                                             clockwise:YES];

        drawPath.lineWidth = 2.0;
        
        [_strokeColor setStroke];
        [_fillColor setFill];

        [drawPath stroke];
        [drawPath fill];
        
        [clipPath addClip];
        
        touchImage = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
    }
        
    return touchImage;
}

#pragma mark -
#pragma mark Screen notifications

- (void)screenConnect:(NSNotification *)notification
{
    [self updateFingertipsAreActive];
}

- (void)screenDisconnect:(NSNotification *)notification
{
    [self updateFingertipsAreActive];
}

- (BOOL)anyScreenIsMirrored
{
    if ( ! [UIScreen instancesRespondToSelector:@selector(mirroredScreen)])
        return NO;

    for (UIScreen *screen in [UIScreen screens])
    {
        if ([screen mirroredScreen] != nil)
            return YES;
    }

    return NO;
}

- (void)updateFingertipsAreActive;
{
#if DEBUG_FINGERTIP_WINDOW
    self.active = YES;
#else
    self.active = [self anyScreenIsMirrored];
#endif    
}

#pragma mark -
#pragma mark UIWindow overrides

- (void)sendEvent:(UIEvent *)event
{
    if (self.active)
    {
        NSSet *allTouches = [event allTouches];
        
        for (UITouch *touch in [allTouches allObjects])
        {
            switch (touch.phase)
            {
                case UITouchPhaseBegan:
                case UITouchPhaseMoved:
                case UITouchPhaseStationary:
                {
                    DSFingerTipView *touchView = (DSFingerTipView *)[self.overlayWindow viewWithTag:touch.hash];

                    if (touch.phase != UITouchPhaseStationary && touchView != nil && [touchView isFadingOut])
                    {
                        [touchView removeFromSuperview];
                        touchView = nil;
                    }
                    
                    if (touchView == nil && touch.phase != UITouchPhaseStationary)
                    {
                        touchView = [[DSFingerTipView alloc] initWithImage:self.touchImage];
                        [self.overlayWindow addSubview:touchView];
                    }
            
                    if ( ! [touchView isFadingOut])
                    {
                        touchView.alpha = self.touchAlpha;
                        touchView.center = [touch locationInView:self.overlayWindow];
                        touchView.tag = touch.hash;
                        touchView.timestamp = touch.timestamp;
                        touchView.shouldAutomaticallyRemoveAfterTimeout = [self shouldAutomaticallyRemoveFingerTipForTouch:touch];
                    }
                    break;
                }

                case UITouchPhaseEnded:
                case UITouchPhaseCancelled:
                {
                    [self removeFingerTipWithHash:touch.hash animated:YES];
                    break;
                }
            }
        }
    }
        
    [super sendEvent:event];

    [self scheduleFingerTipRemoval]; // We may not see all UITouchPhaseEnded/UITouchPhaseCancelled events.
}

#pragma mark -
#pragma mark Private

- (void)scheduleFingerTipRemoval
{
    if (self.fingerTipRemovalScheduled)
        return;
    
    self.fingerTipRemovalScheduled = YES;
    [self performSelector:@selector(removeInactiveFingerTips) withObject:nil afterDelay:0.1];
}

- (void)cancelScheduledFingerTipRemoval
{
    self.fingerTipRemovalScheduled = YES;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(removeInactiveFingerTips) object:nil];
}

- (void)removeInactiveFingerTips
{
    self.fingerTipRemovalScheduled = NO;

    NSTimeInterval now = [[NSProcessInfo processInfo] systemUptime];
    const CGFloat REMOVAL_DELAY = 0.2;

    for (DSFingerTipView *touchView in [self.overlayWindow subviews])
    {
        NSAssert([touchView isKindOfClass:[DSFingerTipView class]], @"Unexpected touch view.");
        
        if (touchView.shouldAutomaticallyRemoveAfterTimeout && now > touchView.timestamp + REMOVAL_DELAY)
            [self removeFingerTipWithHash:touchView.tag animated:YES];
    }

    if ([[self.overlayWindow subviews] count] > 0)
        [self scheduleFingerTipRemoval];
}

- (void)removeFingerTipWithHash:(NSUInteger)hash animated:(BOOL)animated;
{
    DSFingerTipView *touchView = (DSFingerTipView *)[self.overlayWindow viewWithTag:hash];
    if (touchView == nil)
        return;
    
    NSAssert([touchView isKindOfClass:[DSFingerTipView class]], @"Unexpected touch view.");
    
    if ([touchView isFadingOut])
        return;
        
    BOOL animationsWereEnabled = [UIView areAnimationsEnabled];

    if (animated)
    {
        [UIView setAnimationsEnabled:YES];
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:self.fadeDuration];
    }

    touchView.frame = CGRectMake(touchView.center.x - touchView.frame.size.width, 
                                 touchView.center.y - touchView.frame.size.height, 
                                 touchView.frame.size.width  * 2, 
                                 touchView.frame.size.height * 2);
    
    touchView.alpha = 0.0;

    if (animated)
    {
        [UIView commitAnimations];
        [UIView setAnimationsEnabled:animationsWereEnabled];
    }
    
    touchView.fadingOut = YES;
    [touchView performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:self.fadeDuration];
}

- (BOOL)shouldAutomaticallyRemoveFingerTipForTouch:(UITouch *)touch;
{
    // We don't reliably get UITouchPhaseEnded or UITouchPhaseCancelled
    // events via -sendEvent: for certain touch events. Known cases
    // include swipe-to-delete on a table view row, and tap-to-cancel
    // swipe to delete. We automatically remove their associated
    // fingertips after a suitable timeout.
    //
    // It would be much nicer if we could remove all touch events after
    // a suitable time out, but then we'll prematurely remove touch and
    // hold events that are picked up by gesture recognizers (since we
    // don't use UITouchPhaseStationary touches for those. *sigh*). So we
    // end up with this more complicated setup.

    UIView *view = [touch view];
    view = [view hitTest:[touch locationInView:view] withEvent:nil];

    while (view != nil)
    {
        if ([view isKindOfClass:[UITableViewCell class]])
        {
            for (UIGestureRecognizer *recognizer in [touch gestureRecognizers])
            {
                if ([recognizer isKindOfClass:[UISwipeGestureRecognizer class]])
                    return YES;
            }
        }

        if ([view isKindOfClass:[UITableView class]])
        {
            if ([[touch gestureRecognizers] count] == 0)
                return YES;
        }

        view = view.superview;
    }

    return NO;
}

@end

#pragma mark -

@implementation DSFingerTipView

@synthesize timestamp;
@synthesize shouldAutomaticallyRemoveAfterTimeout;
@synthesize fadingOut;

@end
