Pod::Spec.new do |s|

    s.name         = "SPTDataLoader"
    s.version      = "2.1.0"
    s.summary      = "SPTDataLoader is Spotify’s HTTP library for Objective-C"

    s.description  = <<-DESC
                        Authentication and back-off logic is a pain, let’s do it
                        once and forget about it! This is a library that allows you
                        to centralise this logic and forget about the ugly parts of
                        making HTTP requests.
                     DESC

    s.ios.deployment_target     = "8.0"
    s.osx.deployment_target     = "10.9"
    s.tvos.deployment_target    = "9.0"
    s.watchos.deployment_target = "2.0"

    s.homepage          = "https://github.com/spotify/SPTDataLoader"
    s.social_media_url  = "https://twitter.com/spotifyeng"
    s.license           = "Apache 2.0"
    s.author            = {
        "Will Sackfield" => "sackfield@spotify.com"
    }

    s.source           = { :git => "https://github.com/spotify/SPTDataLoader.git", :tag => s.version }
    s.swift_version    = "5.1"

    s.default_subspec  = "Core"

    s.subspec "Core" do |sp|
        sp.source_files         = "include/SPTDataLoader/*.h", "Sources/SPTDataLoader/*.{h,m}"
        sp.public_header_files  = "include/SPTDataLoader/*.h"
        sp.framework            = "Security"
        sp.xcconfig             = {
            "OTHER_LDFLAGS" => "-lObjC"
        }
    end

    s.subspec "Swift" do |sp|
        sp.dependency "SPTDataLoader/Core"

        sp.source_files  = "Sources/SPTDataLoaderSwift/**/*.swift"

        sp.ios.deployment_target      = "10.0"
        sp.osx.deployment_target      = "10.12"
        sp.tvos.deployment_target     = "10.0"
        sp.watchos.deployment_target  = "3.0"
    end

end
