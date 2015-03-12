# Fingertips

### Presentation mode for your iOS app

Fingertips is a small library (one class) meant for presentations from iOS devices that shows all touches and gestures so that the audience can see them. 

This is only designed for the iPad 2 and iPhone 4S (or later), which feature [hardware video mirroring](http://www.apple.com/ipad/features/airplay/) support. **This library does not do the mirroring for you!**

Just drop in our replacement `UIWindow` subclass and your app will automatically determine when an external screen is available. It will show every touch on-screen with a nice partially-transparent graphic that automatically fades out when the touch ends. 

Here's a [demo video](http://vimeo.com/22136667).

Fingertips requires iOS 5.0 or greater and ARC. 

## Configuration

You shouldn't need to configure anything, but if you want to tweak some knobs: 

 * `touchImage`: pass a `UIImage` to use for showing touches
 * `touchAlpha`: change the visible-touch alpha transparency
 * `fadeDuration`: change how long lifted touches fade out
 * `strokeColor`: change default `touchImage` stroke color (defaults to black)
 * `fillColor`: change default `touchImage` fill color (defaults to white)

If you ever need to debug Fingertips, i.e. always show touches even when no mirroring is active, set the `DEBUG_FINGERTIP_WINDOW` [environment variable](http://stackoverflow.com/questions/17393053/xcode-4-6-where-to-set-environment-variables-for-app/17394454#17394454) to `YES` in Xcode. If you want to always show touches, even in release mode, just add this line of code.

```objc
setenv("DEBUG_FINGERTIP_WINDOW", "YES", 1);
```

## License

Copyright (c) 2011-2014 Mapbox, Inc.

The Fingertips library should be accompanied by a LICENSE file. This file contains the license relevant to this distribution. If no license exists, please contact [Mapbox](http://mapbox.com).