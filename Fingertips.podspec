Pod::Spec.new do |f|

  f.name    = 'Fingertips'
  f.version = '0.6.0'

  f.summary          = 'Touch indicators on external displays for iOS applications.'
  f.description      = 'Touch indicators on external displays for iOS applications, giving you automatic presentation mode using a simple UIWindow subclass.'
  f.homepage         = 'https://github.com/mapbox/Fingertips'
  f.license          = 'BSD'
  f.author           = { 'Mapbox' => 'mobile@mapbox.com' }
  f.social_media_url = 'https://twitter.com/Mapbox'

  f.source = { :git => 'https://github.com/mapbox/Fingertips.git', :tag => "v#{f.version.to_s}" }

  f.platform = :ios, '11.0'

  f.source_files = 'Sources/Fingertips/*.{swift}'

  f.swift_version = '5'

  f.framework = 'UIKit'

end
