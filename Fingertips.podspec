Pod::Spec.new do |f|

  f.name    = 'Fingertips'
  f.version = '0.5.0'

  f.summary          = 'Touch indicators on external displays for iOS applications.'
  f.description      = 'Touch indicators on external displays for iOS applications, giving you automatic presentation mode using a simple UIWindow subclass.'
  f.homepage         = 'https://github.com/mapbox/Fingertips'
  f.license          = 'BSD'
  f.author           = { 'Mapbox' => 'mobile@mapbox.com' }
  f.social_media_url = 'https://twitter.com/Mapbox'

  f.source = { :git => 'https://github.com/mapbox/Fingertips.git', :tag => "v#{f.version.to_s}" }

  f.platform = :ios, '5.0'

  f.source_files = '*.{h,m}'

  f.requires_arc = true

  f.framework = 'UIKit'

end
