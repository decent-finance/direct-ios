# CEX Direct Client Framework

![Swift](https://img.shields.io/badge/Swift-5.0-orange.svg) [![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0) [![Gitter](https://badges.gitter.im/decent-finance/community.svg)](https://gitter.im/decent-finance/community?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)

## Requirements

* Swift 5
* iOS 11

## Installation

For the moment you can download and link with the framework manually. Support for CocoaPods and Carthage will be added soon.

## Usage

```
  let cexDirect = CEXDirect(placementID: "your_placement_id", secret: "your_placement_secret")
  if let rootViewController = cexDirect.rootViewController {
      present(rootViewController, animated: true, completion: nil)
  }  
```

## Dependencies

* [Alamofire](https://github.com/Alamofire/Alamofire)
* [SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON)
* [CocoaLumberjack](https://github.com/CocoaLumberjack/CocoaLumberjack)
* [ObjectMapper](https://github.com/tristanhimmelman/ObjectMapper)
* [AlamofireObjectMapper](https://github.com/tristanhimmelman/AlamofireObjectMapper)
* [RxSwift](https://github.com/ReactiveX/RxSwift)
* [CryptoSwift](https://github.com/krzyzanowskim/CryptoSwift)
* [ReactorKit](https://github.com/ReactorKit/ReactorKit)
* [Starscream](https://github.com/daltoniam/Starscream)
* [BigInt](https://github.com/attaswift/BigInt)
* [MarkdownView](https://github.com/keitaoouchi/MarkdownView)
* [SVProgressHUD](https://github.com/SVProgressHUD/SVProgressHUD)
* [Nantes](https://github.com/instacart/Nantes)
* [Firebase](https://github.com/firebase/firebase-ios-sdk)

## License

```
   Copyright 2019 CEX.​IO Ltd (UK)

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
```
