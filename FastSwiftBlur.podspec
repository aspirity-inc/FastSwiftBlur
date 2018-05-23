#
# Be sure to run `pod lib lint FastSwiftBlur.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'FastSwiftBlur'
  s.version          = '0.1.0'
  s.summary          = 'Blur image from UIImage with optimizations.'

  s.description      = <<-DESC
                       Allows developers render blurred images in background.
                       If you want your image view always be blurred, just use FastBlurImageView instead of UIImageView.
                       DESC

  s.homepage         = 'https://github.com/aspirity-ru/FastSwiftBlur'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Maxim Krupin' => 'mkrupin@aspirity.com' }
  s.source           = { :git => 'https://github.com/aspirity/FastSwiftBlur.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'

  s.source_files = 'FastSwiftBlur/Classes/**/*'

  s.frameworks = 'UIKit', 'MapKit'
end
