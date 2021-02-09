Pod::Spec.new do |s|
  s.name             = 'DPAdapterKit'
  s.version          = '1.2.0'
  s.summary          = 'DP Adapter Kit'
  s.description      = 'A set of useful utilities'
  s.homepage         = 'https://github.com/DPLibs/DPAdapterKit'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Dmitriy Polyakov' => 'dmitriyap11@gmail.com' }
  s.source           = { :git => 'https://github.com/DPLibs/DPAdapterKit.git', :tag => s.version.to_s }
  s.ios.deployment_target = '11.0'
  s.source_files = 'DPAdapterKit/**/*'
  s.swift_version = '5.0'
  
  s.dependency 'DPLibrary'
end
