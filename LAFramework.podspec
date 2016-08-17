#
# Be sure to run `pod lib lint LAFramework.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'LAFramework'
  s.version          = '0.1.0'
  s.summary          = 'iOS Base Framework.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  This is a base framwork that constans Networking,Monitor,Cache,Mediator...
                       DESC

  s.homepage         = 'https://github.com/huhk345/LAFramework'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'LakeR' => 'njlaker@gmail.com' }
  s.source           = { :git => 'https://github.com/huhk345/LAFramework.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
  s.prefix_header_file =  'LAFramework/Classes/LAPrefix.pch'

  
  s.ios.deployment_target = '8.0'

  s.source_files = 'LAFramework/Classes/**/*'
  s.exclude_files = 'LAFramework/Classes/LAPrefix.pch'
  # s.resource_bundles = {
  #   'LAFramework' => ['LAFramework/LAFramework/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'



  s.dependency 'AFNetworking', '~> 3.1.0'
  s.dependency 'ReactiveCocoa', '~> 4.2.0'
  s.dependency 'CocoaLumberjack', '~>2.3.0'


  s.subspec 'LADataCategory' do |sp|
    sp.source_files = 'LADataCategory/Classes/**/*'
    sp.libraries    = 'z'
  end


  s.subspec 'LAJsonKit' do |sp|
    sp.source_files = 'LAJsonKit/Classes/**/*'
    sp.public_header_files = 'LAJsonKit/Classes/**/*.h'
  end

  s.subspec 'LAMediator' do |sp|
    sp.source_files = 'LAMediator/Classes/**/*'
  end


  s.subspec 'LACache' do |sp|
    sp.source_files = 'LACache/Classes/**/*'
    sp.dependency 'LAFramework/LADataCategory'
  end


  s.subspec 'LAWebViewBridge' do |sp|
    sp.source_files = 'LAWebViewBridge/Classes/**/*'
    sp.dependency 'LAFramework/LACache'
  end


  s.subspec 'LASystemInfo' do |sp|
    sp.source_files = 'LASystemInfo/Classes/**/*'
  end


  s.subspec 'LANetworking' do |sp|
    sp.source_files = 'LANetworking/Classes/**/*'
    sp.preserve_paths = 'LANetworking/Scripts/**/*'
    sp.dependency 'LAFramework/LADataCategory'
    sp.dependency 'LAFramework/LACache'
    sp.dependency 'LAFramework/LAJsonKit'
  end

end
