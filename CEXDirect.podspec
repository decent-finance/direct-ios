Pod::Spec.new do |s|
  s.name = "CEXDirect"
  s.version = "1.0.0-alpha3"
  s.summary = "CEX Direct Client Framework"
  s.description = <<-DESC
Provides easy access to crypto assets by handling all user verification and payment procedures, procurement and delivery, giving you freedom to do what you do best - engage with your users.
                   DESC
  s.homepage = "https://github.com/decent-finance/direct-ios"

  s.license = "Apache License, Version 2.0"
  s.author = { "CEX.​IO Ltd (UK)" => "webmaster@cex.io" }

  s.platform = :ios
  s.ios.deployment_target = "11.4"
  s.swift_versions = ["5.0", "5.1"]

  s.source = { :git => "https://github.com/decent-finance/direct-ios.git", :tag => "v#{s.version}" }
  s.source_files = "CEXDirect/**/*.swift"
  s.resources = "CEXDirect/**/*.{storyboard,xib,ttf,bundle,plist,json,xcassets}"
  s.exclude_files = "CEXDirect/Info.plist"

  s.frameworks = "WebKit"

  s.dependency "Alamofire"
  s.dependency "SwiftyJSON"
  s.dependency "CocoaLumberjack/Swift"
  s.dependency "ObjectMapper"
  s.dependency "AlamofireObjectMapper"
  s.dependency "RxSwift"
  s.dependency "RxCocoa"
  s.dependency "CryptoSwift"
  s.dependency "ReactorKit"
  s.dependency "Starscream"
  s.dependency "BigInt"
  s.dependency "MarkdownView"
  s.dependency "SVProgressHUD"
  s.dependency "Nantes"
  s.dependency "lottie-ios"
end
