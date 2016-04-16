Pod::Spec.new do |s|

    s.name         = "SPTDataLoader"
    s.version      = "1.1.0"
    s.summary      = "SPTDataLoader is Spotify’s HTTP library for Objective-C"

    s.description  = <<-DESC
                        Authentication and back-off logic is a pain, let’s do it
                        once and forget about it! This is a library that allows you
                        to centralise this logic and forget about the ugly parts of
                        making HTTP requests.
                     DESC

    s.ios.deployment_target     = "7.0"
    s.osx.deployment_target     = "10.9"
    s.tvos.deployment_target    = "9.0"
    s.watchos.deployment_target = "2.0"

    s.homepage          = "https://github.com/spotify/SPTDataLoader"
    s.social_media_url  = "https://twitter.com/spotifyeng"
    s.license           = "Apache 2.0"
    s.author            = {
        "Will Sackfield" => "sackfield@spotify.com"
    }

    s.source                = { :git => "https://github.com/spotify/SPTDataLoader.git", :tag => s.version }
    s.source_files          = "include/SPTDataLoader/*.h", "SPTDataLoader/*.{h,m}"
    s.public_header_files   = "include/SPTDataLoader/*.h"
    s.framework             = "Security"
    s.xcconfig              = {
        "OTHER_LDFLAGS" => "-lObjC"
    }

end
