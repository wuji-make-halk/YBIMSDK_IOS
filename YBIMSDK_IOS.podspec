Pod::Spec.new do |s|
   s.name = 'YBIMSDK_IOS'
   s.version = '1.0.0'
   s.license = { :type => "MIT", :file => "LICENSE.md" }

   s.summary = 'An elegant messages UI library for iOS.'
   s.homepage = 'https://github.com/Apolla/YBIMSDK_IOS'
  # s.social_media_url = 'https://twitter.com/_SD10_'
   s.author = { "apolla" => "apolla.song@gmail.com" }

  s.homepage         = 'https://github.com/Apolla/YBIMSDK_IOS'

  s.source           = { :git => 'https://github.com/Apolla/YBIMSDK_IOS.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'

  s.source_files = 'YBIMSDK_IOS/Classes/**/*.{h,m,swift}'
  
  s.resources = ["YBIMSDK_IOS/Classes/**/*"]
  s.resource_bundles = {
    'YBIMSDK_IOS' => ['YBIMSDK_IOS/Classes/**/*.{xib,storyboary}','YBIMSDK_IOS/Assets/**/*.*']
  }

      s.dependency 'Alamofire'
      s.dependency 'Kingfisher'
      s.dependency 'ObjectMapper'
      s.dependency 'SwiftyJSON'
      s.dependency 'Dollar'
      s.dependency 'AliyunOSSiOS'
      s.dependency 'RxSwift'
      s.dependency 'RxCocoa'
      s.dependency 'RxBlocking'
      s.dependency 'XCGLogger'
      s.dependency 'SnapKit'
      s.dependency "BSImagePicker"
      s.dependency 'TSVoiceConverter'

      #Objective-C
      s.dependency 'YYText'
      s.dependency 'SVProgressHUD'
      s.dependency 'INTULocationManager'
      s.dependency 'Starscream'
      s.dependency 'Reachability'
      s.dependency 'JXPhotoBrowser'
      s.dependency "ObjectMapper+Realm"
      s.dependency "RealmSwift" , '4.3.1'
  end

