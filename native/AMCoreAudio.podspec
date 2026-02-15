Pod::Spec.new do |s|
  s.name         = 'AMCoreAudio'
  s.version      = '3.4'
  s.summary      = 'A Swift framework that aims to make Core Audio use less tedious in macOS'

  s.description  = <<-DESC
                   AMCoreAudio is a Swift framework that aims to make Core Audio use less tedious in macOS.

                   Here's a few things it can do:

                   * Simplifying audio device enumeration
                   * Providing accessors for the most relevant audio device properties
                   * Managing audio streams
                   * Subscribing to audio hardware events
                   DESC

  s.homepage     = 'https://github.com/rnine/AMCoreAudio'
  s.license      = { :type => 'MIT', :file => 'LICENSE.md' }
  s.author       = { 'Ruben Nine' => 'ruben@9labs.io' }
  s.social_media_url = 'https://twitter.com/sonicbee9'

  s.platform     = :osx, '10.10'
  s.osx.deployment_target = '10.10'

  # Point to the renamed repo and tag 3.4
  s.source       = { :git => 'https://github.com/rnine/SimplyCoreAudio.git', :tag => '3.4' }
  
  # FIX: Recursive glob to include subdirectories like Source/Public/
  s.source_files = 'Source/**/*.{swift,h,m}'

  s.requires_arc = true
  s.swift_versions = ['4.0', '4.2', '5.0', '5.1', '5.2']
end
