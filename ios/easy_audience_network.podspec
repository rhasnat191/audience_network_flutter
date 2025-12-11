# #
# # To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
# #
# Pod::Spec.new do |s|
#   s.name             = 'easy_audience_network'
#   s.version          = '0.0.7'
#   s.summary          = 'Facebook Audience Network plugin for Flutter application'
#   s.description      = <<-DESC
# Facebook Audience Network plugin for Flutter application
#                        DESC
#   s.homepage         = 'http://example.com'
#   s.license          = { :file => '../LICENSE' }
#   s.author           = { 'Cross Code' => 'admin@crosscode.dev' }
#   s.source           = { :path => '.' }
#   s.source_files = 'Classes/**/*'
#   s.public_header_files = 'Classes/**/*.h'
#   s.dependency 'Flutter'
#   s.dependency 'FBAudienceNetwork', '~> 6.21.0'

#   s.static_framework = true
#   s.swift_version = '6.2'
#   s.ios.deployment_target = '15.0'
# end


Pod::Spec.new do |s|
  s.name             = 'easy_audience_network'
  s.version          = '0.0.7'
  s.summary          = 'Facebook Audience Network plugin for Flutter'
  s.description      = <<-DESC
A Flutter plugin providing access to Facebook Audience Network ads,
rewritten for Swift 6 and updated for FAN 6.21.0 SDK.
  DESC

  s.homepage         = 'https://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Cross Code' => 'admin@crosscode.dev' }

  # Local plugin
  s.source           = { :path => '.' }

  # Swift + Objective-C mixed plugin
  s.source_files     = 'Classes/**/*.{swift,h,m}'
  s.public_header_files = 'Classes/**/*.h'

  # Dependencies
  s.dependency 'Flutter'
  s.dependency 'FBAudienceNetwork', '~> 6.21.0'

  # Build settings
  s.static_framework      = true
  s.swift_version         = '6.0'   # 6.0+ is correct; 6.2 is OK but optional
  s.ios.deployment_target = '15.0'

  # Prevents warnings for missing modules in transitive Swift targets
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'CLANG_WARN_DOCUMENTATION_COMMENTS' => 'YES'
  }

  s.swift_version = '6.0'
end