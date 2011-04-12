//
//  DSFingerTipWindow.h
//
//  Created by Justin R. Miller on 3/29/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DSFingerTipWindow : UIWindow
{
    UIWindow *overlayWindow;
    BOOL active;
    UIImage *touchImage;
    CGFloat touchAlpha;
    NSTimeInterval fadeDuration;
    BOOL fingerTipRemovalScheduled;
}

@property (nonatomic, retain) UIImage *touchImage;
@property (nonatomic, assign) CGFloat touchAlpha;
@property (nonatomic, assign) NSTimeInterval fadeDuration;

@end
