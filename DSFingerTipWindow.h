//
//  DSFingerTipWindow.h
//
//  Created by Justin R. Miller on 3/29/11.
//  Copyright 2011-2012 Development Seed. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DSFingerTipWindow : UIWindow

@property (nonatomic, strong) UIImage *touchImage;
@property (nonatomic, assign) CGFloat touchAlpha;
@property (nonatomic, assign) NSTimeInterval fadeDuration;

@end