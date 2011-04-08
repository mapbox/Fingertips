//
//  DSFingerTipWindow.h
//
//  Created by Justin R. Miller on 3/29/11.
//  Copyright 2011 Development Seed. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DSFingerTipWindow : UIWindow
{
    UIWindow *overlay;
    NSMutableDictionary *touches;
    BOOL active;
    UIImage *touchImage;
    CGFloat touchAlpha;
    NSTimeInterval fadeDuration;
}

@property (nonatomic, retain) UIImage *touchImage;
@property (nonatomic, assign) CGFloat touchAlpha;
@property (nonatomic, assign) NSTimeInterval fadeDuration;

@end