//
//  DSFingerTipWindow.m
//
//  Created by Justin R. Miller on 3/29/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import "DSFingerTipWindow.h"

@interface DSFingerTipWindow (DSFingerTipWindowPrivate)

- (void)DSFingerTipWindow_commonInit;

@end

#pragma mark -

@implementation DSFingerTipWindow

@synthesize touchImage;
@synthesize touchAlpha;
@synthesize fadeDuration;

- (id)initWithCoder:(NSCoder *)decoder
{
    // this covers NIB-loaded windows
    //
    self = [super initWithCoder:decoder];

    if (self != nil)
        [self DSFingerTipWindow_commonInit];
    
    return self;
}

- (id)initWithFrame:(CGRect)rect
{
    // this covers programmatically-created windows
    //
    self = [super initWithFrame:rect];
    
    if (self != nil)
        [self DSFingerTipWindow_commonInit];
    
    return self;
}

- (void)DSFingerTipWindow_commonInit
{
    overlay = [[UIWindow alloc] initWithFrame:self.frame];
    
    overlay.userInteractionEnabled = NO;
    overlay.windowLevel = UIWindowLevelStatusBar;
    overlay.backgroundColor = [UIColor clearColor];
    
    [overlay makeKeyAndVisible];
    
    touches      = [[NSMutableDictionary dictionary] retain];
    active       = [[UIScreen screens] count] > 1 ? YES : NO;
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
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIScreenDidConnectNotification    object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIScreenDidDisconnectNotification object:nil];
    
    [overlay release];
    [touches release];
    [touchImage release];

    [super dealloc];
}

#pragma mark -

- (UIImage *)touchImage
{
    if ( ! touchImage)
    {
        UIBezierPath *clipPath = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, 50.0, 50.0)];
        
        UIGraphicsBeginImageContext(clipPath.bounds.size);

        UIBezierPath *drawPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(25.0, 25.0) 
                                                                radius:22.0
                                                            startAngle:0
                                                              endAngle:2 * M_PI
                                                             clockwise:YES];

        drawPath.lineWidth = 2.0;
        
        [[UIColor blackColor] setStroke];
        [[UIColor whiteColor] setFill];
        
        [drawPath stroke];
        [drawPath fill];
        
        [clipPath addClip];
        
        touchImage = [UIGraphicsGetImageFromCurrentImageContext() retain];
        
        UIGraphicsEndImageContext();
    }
        
    return touchImage;
}

#pragma mark -

- (void)screenConnect:(NSNotification *)notification
{
    active = YES;
}

- (void)screenDisconnect:(NSNotification *)notification
{
    active = [[UIScreen screens] count] > 1 ? YES : NO;
}

#pragma mark -

- (void)sendEvent:(UIEvent *)event
{
    if (active)
    {
        NSSet *allTouches = [event allTouches];
        
        for (UITouch *touch in [allTouches allObjects])
        {
            NSNumber *hash = [NSNumber numberWithUnsignedInteger:[touch hash]];
            
            if ([touches objectForKey:hash])
            {
                UIImageView *touchView = [touches objectForKey:hash];
                
                if ([touch phase] == UITouchPhaseEnded || [touch phase] == UITouchPhaseCancelled)
                {
                    [UIView beginAnimations:nil context:nil];
                    [UIView setAnimationDuration:self.fadeDuration];
                    
                    touchView.frame = CGRectMake(touchView.center.x - touchView.frame.size.width, 
                                                 touchView.center.y - touchView.frame.size.height, 
                                                 touchView.frame.size.width  * 2, 
                                                 touchView.frame.size.height * 2);

                    touchView.alpha = 0.0;
                    
                    [UIView commitAnimations];
                
                    [touchView performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:self.fadeDuration];
                    
                    [touches removeObjectForKey:hash];
                }
                else if ([touch phase] == UITouchPhaseMoved)
                {
                    touchView.center = [touch locationInView:overlay];
                }
            }
            else if ([touch phase] == UITouchPhaseBegan)
            {
                UIImageView *touchView = [[[UIImageView alloc] initWithImage:self.touchImage] autorelease];
                
                touchView.alpha = self.touchAlpha;
                
                [overlay addSubview:touchView];
                
                touchView.center = [touch locationInView:overlay];
                
                [touches setObject:touchView forKey:hash];
            }
        }
    }
    
    [super sendEvent:event];
}

@end
