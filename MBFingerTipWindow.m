//
//  MBFingerTipWindow.m
//
//  Created by Justin R. Miller on 3/29/11.
//  Copyright 2011-2013 MapBox. All rights reserved.
//

#import "MBFingerTipWindow.h"

#import <objc/runtime.h>

// This file must be built with ARC.
//
#if !__has_feature(objc_arc)
	#error "ARC must be enabled for MBFingerTipWindow.m"
#endif

// Turn this on to debug touches during development.
//
#ifdef TARGET_IPHONE_SIMULATOR
	#define DEBUG_FINGERTIP_WINDOW 0
#else
	#define DEBUG_FINGERTIP_WINDOW 0
#endif

#pragma mark - JRSwizzle (prefixed to avoid conflicts; see https://github.com/rentzsch/jrswizzle, commit d3307b1204c2357c8c2c69097be7661597462e40)

#if TARGET_OS_IPHONE
	#import <objc/runtime.h>
	#import <objc/message.h>
#else
	#import <objc/objc-class.h>
#endif

#define SetNSErrorFor(FUNC, ERROR_VAR, FORMAT,...)	\
	if (ERROR_VAR) {	\
		NSString *errStr = [NSString stringWithFormat:@"%s: " FORMAT,FUNC,##__VA_ARGS__]; \
		*ERROR_VAR = [NSError errorWithDomain:@"NSCocoaErrorDomain" \
										 code:-1	\
									 userInfo:[NSDictionary dictionaryWithObject:errStr forKey:NSLocalizedDescriptionKey]]; \
	}
#define SetNSError(ERROR_VAR, FORMAT,...) SetNSErrorFor(__func__, ERROR_VAR, FORMAT, ##__VA_ARGS__)

#if OBJC_API_VERSION >= 2
	#define GetClass(obj)	object_getClass(obj)
#else
	#define GetClass(obj)	(obj ? obj->isa : Nil)
#endif

@interface NSObject (MBFingerTipJRSwizzle)

+ (BOOL)mbjr_swizzleMethod:(SEL)origSel_ withMethod:(SEL)altSel_ error:(NSError**)error_;
+ (BOOL)mbjr_swizzleClassMethod:(SEL)origSel_ withClassMethod:(SEL)altSel_ error:(NSError**)error_;

@end

@implementation NSObject (MBFingerTipJRSwizzle)

+ (BOOL)mbjr_swizzleMethod:(SEL)origSel_ withMethod:(SEL)altSel_ error:(NSError**)error_ {
#if OBJC_API_VERSION >= 2
	Method origMethod = class_getInstanceMethod(self, origSel_);
	if (!origMethod) {
#if TARGET_OS_IPHONE
		SetNSError(error_, @"original method %@ not found for class %@", NSStringFromSelector(origSel_), [self class]);
#else
		SetNSError(error_, @"original method %@ not found for class %@", NSStringFromSelector(origSel_), [self className]);
#endif
		return NO;
	}
	
	Method altMethod = class_getInstanceMethod(self, altSel_);
	if (!altMethod) {
#if TARGET_OS_IPHONE
		SetNSError(error_, @"alternate method %@ not found for class %@", NSStringFromSelector(altSel_), [self class]);
#else
		SetNSError(error_, @"alternate method %@ not found for class %@", NSStringFromSelector(altSel_), [self className]);
#endif
		return NO;
	}
	
	class_addMethod(self,
					origSel_,
					class_getMethodImplementation(self, origSel_),
					method_getTypeEncoding(origMethod));
	class_addMethod(self,
					altSel_,
					class_getMethodImplementation(self, altSel_),
					method_getTypeEncoding(altMethod));
	
	method_exchangeImplementations(class_getInstanceMethod(self, origSel_), class_getInstanceMethod(self, altSel_));
	return YES;
#else
	//	Scan for non-inherited methods.
	Method directOriginalMethod = NULL, directAlternateMethod = NULL;
	
	void *iterator = NULL;
	struct objc_method_list *mlist = class_nextMethodList(self, &iterator);
	while (mlist) {
		int method_index = 0;
		for (; method_index < mlist->method_count; method_index++) {
			if (mlist->method_list[method_index].method_name == origSel_) {
				assert(!directOriginalMethod);
				directOriginalMethod = &mlist->method_list[method_index];
			}
			if (mlist->method_list[method_index].method_name == altSel_) {
				assert(!directAlternateMethod);
				directAlternateMethod = &mlist->method_list[method_index];
			}
		}
		mlist = class_nextMethodList(self, &iterator);
	}
	
	//	If either method is inherited, copy it up to the target class to make it non-inherited.
	if (!directOriginalMethod || !directAlternateMethod) {
		Method inheritedOriginalMethod = NULL, inheritedAlternateMethod = NULL;
		if (!directOriginalMethod) {
			inheritedOriginalMethod = class_getInstanceMethod(self, origSel_);
			if (!inheritedOriginalMethod) {
				SetNSError(error_, @"original method %@ not found for class %@", NSStringFromSelector(origSel_), [self className]);
				return NO;
			}
		}
		if (!directAlternateMethod) {
			inheritedAlternateMethod = class_getInstanceMethod(self, altSel_);
			if (!inheritedAlternateMethod) {
				SetNSError(error_, @"alternate method %@ not found for class %@", NSStringFromSelector(altSel_), [self className]);
				return NO;
			}
		}
		
		int hoisted_method_count = !directOriginalMethod && !directAlternateMethod ? 2 : 1;
		struct objc_method_list *hoisted_method_list = malloc(sizeof(struct objc_method_list) + (sizeof(struct objc_method)*(hoisted_method_count-1)));
		hoisted_method_list->obsolete = NULL;	// soothe valgrind - apparently ObjC runtime accesses this value and it shows as uninitialized in valgrind
		hoisted_method_list->method_count = hoisted_method_count;
		Method hoisted_method = hoisted_method_list->method_list;
		
		if (!directOriginalMethod) {
			bcopy(inheritedOriginalMethod, hoisted_method, sizeof(struct objc_method));
			directOriginalMethod = hoisted_method++;
		}
		if (!directAlternateMethod) {
			bcopy(inheritedAlternateMethod, hoisted_method, sizeof(struct objc_method));
			directAlternateMethod = hoisted_method;
		}
		class_addMethods(self, hoisted_method_list);
	}
	
	//	Swizzle.
	IMP temp = directOriginalMethod->method_imp;
	directOriginalMethod->method_imp = directAlternateMethod->method_imp;
	directAlternateMethod->method_imp = temp;
	
	return YES;
#endif
}

+ (BOOL)mbjr_swizzleClassMethod:(SEL)origSel_ withClassMethod:(SEL)altSel_ error:(NSError**)error_ {
	return [GetClass((id)self) mbjr_swizzleMethod:origSel_ withMethod:altSel_ error:error_];
}

@end

#pragma mark -

@interface MBFingerTipView : UIImageView

@property (nonatomic, assign) NSTimeInterval timestamp;
@property (nonatomic, assign) BOOL shouldAutomaticallyRemoveAfterTimeout;
@property (nonatomic, assign, getter=isFadingOut) BOOL fadingOut;

@end

#pragma mark -

@interface MBFingerTipSettings ()

@property (nonatomic, strong) UIWindow *overlayWindow;
@property (nonatomic, assign, getter=isActive) BOOL active;
@property (nonatomic, assign, getter=isFingerTipRemovalScheduled) BOOL fingerTipRemovalScheduled;

@end

#pragma mark -

@implementation MBFingerTipSettings

- (id)initWithFrame:(CGRect)frame
{
	self = [super init];
	
	if (self != nil) {
		self.strokeColor = [UIColor blackColor];
		self.fillColor = [UIColor whiteColor];
		self.touchAlpha = 0.5;
		self.fadeDuration = 0.3;
		
		self.overlayWindow = [[UIWindow alloc] initWithFrame:frame];
		
		self.overlayWindow.userInteractionEnabled = NO;
		self.overlayWindow.windowLevel = UIWindowLevelStatusBar;
		self.overlayWindow.backgroundColor = [UIColor clearColor];
		self.overlayWindow.hidden = NO;
		
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
	
	return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIScreenDidConnectNotification    object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIScreenDidDisconnectNotification object:nil];
}

- (UIImage *)touchImage
{
	if ( ! _touchImage)
	{
		UIBezierPath *clipPath = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, 50.0, 50.0)];
		
		UIGraphicsBeginImageContextWithOptions(clipPath.bounds.size, NO, 0);
		
		UIBezierPath *drawPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(25.0, 25.0)
																radius:22.0
															startAngle:0
															  endAngle:2 * M_PI
															 clockwise:YES];
		
		drawPath.lineWidth = 2.0;
		
		[self.strokeColor setStroke];
		[self.fillColor setFill];
		
		[drawPath stroke];
		[drawPath fill];
		
		[clipPath addClip];
		
		_touchImage = UIGraphicsGetImageFromCurrentImageContext();
		
		UIGraphicsEndImageContext();
	}
	
	return _touchImage;
}

- (void)updateFingertipsAreActive
{
#if DEBUG_FINGERTIP_WINDOW
	self.active = YES;
#else
	self.active = [self anyScreenIsMirrored];
#endif
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
	
	for (MBFingerTipView *touchView in [self.overlayWindow subviews])
	{
		if ( ! [touchView isKindOfClass:[MBFingerTipView class]])
			continue;
		
		if (touchView.shouldAutomaticallyRemoveAfterTimeout && now > touchView.timestamp + REMOVAL_DELAY)
			[self removeFingerTipWithHash:touchView.tag animated:YES];
	}
	
	if ([[self.overlayWindow subviews] count] > 0)
		[self scheduleFingerTipRemoval];
}

- (void)removeFingerTipWithHash:(NSUInteger)hash animated:(BOOL)animated;
{
	MBFingerTipView *touchView = (MBFingerTipView *)[self.overlayWindow viewWithTag:hash];
	if ( ! [touchView isKindOfClass:[MBFingerTipView class]])
		return;
	
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

@end

#pragma mark -

@implementation UIWindow (MBFingerTip)

- (MBFingerTipSettings *)fingerTipSettings
{
    static void *MBFingerTipSettingsKey = &MBFingerTipSettingsKey;
    
	// Lazily bind a settings object when the `fingerTipSettings` property is accessed
	MBFingerTipSettings *fingerTipSettings = objc_getAssociatedObject(self, MBFingerTipSettingsKey);
	if ( ! fingerTipSettings)
	{
		fingerTipSettings = [[MBFingerTipSettings alloc] initWithFrame:self.frame];
		objc_setAssociatedObject(self, MBFingerTipSettingsKey, fingerTipSettings, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	return fingerTipSettings;
}

@end

#pragma mark -

@implementation UIWindow (MBFingerTipPrivate)

+ (void)load
{
	[self mbjr_swizzleMethod:@selector(sendEvent:) withMethod:@selector(MBFingerTip_sendEvent:) error:NULL];
}

#pragma mark -
#pragma mark UIWindow overrides

- (void)MBFingerTip_sendEvent:(UIEvent *)event
{
	if (self.fingerTipSettings.enabled && self.fingerTipSettings.active)
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
					UIWindow *overlayWindow = self.fingerTipSettings.overlayWindow;
					MBFingerTipView *touchView = (MBFingerTipView *)[overlayWindow viewWithTag:touch.hash];
					
					if (touch.phase != UITouchPhaseStationary && touchView != nil && [touchView isFadingOut])
					{
						[touchView removeFromSuperview];
						touchView = nil;
					}
					
					if (touchView == nil && touch.phase != UITouchPhaseStationary)
					{
						touchView = [[MBFingerTipView alloc] initWithImage:self.fingerTipSettings.touchImage];
						[overlayWindow addSubview:touchView];
					}
					
					if ( ! [touchView isFadingOut])
					{
						touchView.alpha = self.fingerTipSettings.touchAlpha;
						touchView.center = [touch locationInView:overlayWindow];
						touchView.tag = touch.hash;
						touchView.timestamp = touch.timestamp;
						touchView.shouldAutomaticallyRemoveAfterTimeout = [self shouldAutomaticallyRemoveFingerTipForTouch:touch];
					}
					break;
				}
					
				case UITouchPhaseEnded:
				case UITouchPhaseCancelled:
				{
					[self.fingerTipSettings removeFingerTipWithHash:touch.hash animated:YES];
					break;
				}
			}
		}
	}
	
	[self MBFingerTip_sendEvent:event];
	
	[self.fingerTipSettings scheduleFingerTipRemoval]; // We may not see all UITouchPhaseEnded/UITouchPhaseCancelled events.
}

#pragma mark -
#pragma mark Private

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

@implementation MBFingerTipView

@end
