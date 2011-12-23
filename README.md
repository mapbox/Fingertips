# Fingertips: Presentation mode for your iOS app

Fingertips is a small library (currently, one class) that gives you automatic presentation mode in your iOS app. Note that currently, this is only designed for the iPad 2 and iPhone 4S, which feature [hardware video mirroring](http://www.apple.com/ipad/features/mirroring.html) support. **This library does not do the mirroring for you!**

Just drop in our replacement `UIWindow` subclass and your app will automatically determine when an external screen is available. It will show every touch on-screen with a nice partially-transparent graphic that automatically fades out when the touch ends. 

Here's a [demo video](http://vimeo.com/22136667).

There is an ARC-capable dev branch happening over on `dev-arc` that will eventually becomes `master`. 

## Configuration

You shouldn't need to configure anything, but if you want to tweak some knobs: 

 * `touchImage`: pass a `UIImage` to use for showing touches
 * `touchAlpha`: change the visible-touch alpha transparency
 * `fadeDuration`: change how long lifted touches fade out

## License

Copyright (c) 2011 Development Seed, Inc.

The Fingertips library should be accompanied by a LICENSE file. This file contains the license relevant to this distribution. If no license exists, please contact [Development Seed](http://developmentseed.org).