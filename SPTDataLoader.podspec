Pod::Spec.new do |s|

    s.name         = "SPTDataLoader"
    s.version      = "1.0.0"
    s.summary      = "SPTDataLoader is Spotify's HTTP library for Objective-C"

    s.description  = <<-DESC
                        Authentication and back-off logic is a pain, let's do it
                        once and forget about it! This is a library that allows you
                        to centralise this logic and forget about the ugly parts of
                        making HTTP requests.
                     DESC

    s.homepage     = "https://github.com/spotify/SPTDataLoader"
    s.license      = "Apache 2.0"
    s.author       = { "Will Sackfield" => "sackfield@spotify.com" }
    s.platform     = :ios, "7.0"
    s.source       = { :git => "https://github.com/spotify/SPTDataLoader.git", :tag => "1.0.0" }
    s.source_files = "include/SPTDataLoader/*.h", "SPTDataLoader/*.{h,m}"
    s.public_header_files = "include/SPTDataLoader/*.h"
    s.xcconfig = { 'OTHER_LDFLAGS' => '-lObjC' }

end
