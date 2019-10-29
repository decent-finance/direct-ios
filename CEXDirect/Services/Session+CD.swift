// Copyright 2019 CEX.​IO Ltd (UK)
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//  Created by Ihor Vovk on 4/5/19.

import Alamofire
import CocoaLumberjack
import ObjectMapper
import AlamofireObjectMapper

extension Session {
    
    func cd_request(_ url: URLConvertible, method: Alamofire.HTTPMethod = .get, parameters: Parameters? = nil, encoding: ParameterEncoding = URLEncoding.default, headers: HTTPHeaders? = nil, success: @escaping (Any) -> Void, failure: @escaping (Error) -> Void) {
        request(url, method: method, parameters: parameters, encoding: encoding, headers: headers).validate().responseJSON { response in
            switch response.result {
            case .success(let result):
                DDLogInfo("Successfully sent request \(url)")
                success(result)
            case .failure(let error):
                DDLogError("Failed to send request \(url) - \(error)")
                failure(error)
            }
        }
    }
    
    func cd_requestObject<ResponseType: Mappable>(_ url: URLConvertible, method: Alamofire.HTTPMethod = .get, parameters: Parameters? = nil, encoding: ParameterEncoding = URLEncoding.default, headers: HTTPHeaders? = nil, keyPath: String? = nil, success: @escaping (ResponseType) -> Void, failure: @escaping (Error) -> Void) {
        request(url, method: method, parameters: parameters, encoding: encoding, headers: headers).validate().responseObject(keyPath: keyPath) { (response: AFDataResponse<ResponseType>) in
            switch response.result {
            case .success(let result):
                DDLogInfo("Successfully sent request \(url)")
                success(result)
            case .failure(let error):
                DDLogError("Failed to send request \(url) - \(error)")
                failure(error)
            }
        }
    }
    
    func cd_requestArray<ResponseType: Mappable>(_ url: URLConvertible, method: Alamofire.HTTPMethod = .get, parameters: Parameters? = nil, encoding: ParameterEncoding = URLEncoding.default, headers: HTTPHeaders? = nil, keyPath: String? = nil, success: @escaping ([ResponseType]) -> Void, failure: @escaping (Error) -> Void) {
        request(url, method: method, parameters: parameters, encoding: encoding, headers: headers).validate().responseArray(keyPath: keyPath) { (response: AFDataResponse<[ResponseType]>) in
            switch response.result {
            case .success(let result):
                DDLogInfo("Successfully sent request \(url)")
                success(result)
            case .failure(let error):
                DDLogError("Failed to send request \(url) - \(error)")
                failure(error)
            }
        }
    }
}
