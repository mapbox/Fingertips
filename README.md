# Fingertips

[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bhttps%3A%2F%2Fgithub.com%2Fmapbox%2FFingertips.svg?type=shield)](https://app.fossa.io/projects/git%2Bhttps%3A%2F%2Fgithub.com%2Fmapbox%2FFingertips?ref=badge_shield)

### Presentation mode for your iOS app

Fingertips is a small library (one class) meant for presentations from iOS devices that shows all touches and gestures so that the audience can see them.

**This library does not do the mirroring or screen recording for you!**

Just drop in our replacement `UIWindow` subclass and your app will automatically determine when you are in the screen recording or an external screen is available. It will show every touch on-screen with a nice partially-transparent graphic that automatically fades out when the touch ends.

If you are using storyboards, the easiest way to integrate Fingertips is to override the `window` method of your application delegate like this:

```objc
// AppDelegate.m

- (UIWindow *)window {
	if (!_window) {
		_window = [[MBFingerTipWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	}
	return _window;
}
```


```swift
// AppDelegate.swift (Swift)

var window: UIWindow? = FingerTipWindow(frame: UIScreen.main.bounds)
```

For iOS 13+ with UISceneDelegate:
```swift
var windows: [UIWindow] = []

func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
	guard let windowScene = scene as? UIWindowScene else { return }

	let window = FingerTipWindow(windowScene: windowScene)

	window.rootViewController = // Your root view controller
	window.makeKeyAndVisible()

	windows.append(window)
}

```

Fingertips require iOS 11.0 or greater and ARC. It uses **no private API** and is safe for App Store submissions.

https://github.com/mapbox/Fingertips/assets/735178/833f659e-b549-4e74-ae27-e695f37717b6

## Configuration

You shouldn't need to configure anything, but if you want to tweak some knobs:

 * `touchImage`: pass a `UIImage` to use for showing touches
 * `touchAlpha`: change the visible-touch alpha transparency
 * `fadeDuration`: change how long lifted touches fade out
 * `strokeColor`: change default `touchImage` stroke color (defaults to black)
 * `fillColor`: change default `touchImage` fill color (defaults to white)

If you ever need to debug Fingertips, just set the `DEBUG_FINGERTIP_WINDOW` environment variable to `YES` in Xcode or set the runtime property `alwaysShowTouches` to `YES`.

## License

Copyright (c) 2011-2023 Mapbox, Inc.

The Fingertips library should be accompanied by a LICENSE file. This file contains the license relevant to this distribution. If no license exists, please contact [Mapbox](http://mapbox.com).

[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bhttps%3A%2F%2Fgithub.com%2Fmapbox%2FFingertips.svg?type=large)](https://app.fossa.io/projects/git%2Bhttps%3A%2F%2Fgithub.com%2Fmapbox%2FFingertips?ref=badge_large)
