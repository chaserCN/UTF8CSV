Pod::Spec.new do |s|
  s.name         = 'UTF8CSV'
  s.version      = '1.0.0'
  s.summary      = 'Simple CSV parser for UTF8 encoding in Swift'
  s.description  = "Simple CSV parser for UTF8 encoding. Supports decoding strings into structures"
  s.homepage     = 'https://github.com/chaserCN/UTF8CSV'
  s.license      = 'MIT'
  s.author       = ['Nikolay Popok' => "nikolay.popok@gmail.com"]
  s.source       = { :git => 'https://github.com/chaserCN/UTF8CSV.git', :tag => s.version.to_s }
  s.platform     = :ios, '8.0'
  s.requires_arc = true
  s.source_files = 'UTF8CSV/**/*.{swift}'
  s.frameworks   = 'Foundation'
end
