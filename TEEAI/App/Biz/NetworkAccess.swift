//
//  NetworkAccess.swift
//  sst-ios
//
//  Created by Zal Zhang on 12/27/16.
//  Copyright © 2016 po. All rights reserved.
//

import UIKit
import Gzip
import Alamofire

let kNetworkStatusNofication         = "network_changed"
let kNetworkTimeoutInterval: Double  = 30

public typealias RequestCallBack = (_ data: Any?, _ error:Any?) -> Void
public typealias ErrorCallBack   = (_ errorCode: Any?) -> Bool
enum APICodeType: Int {
    case Ok = 101
    case CodeRepeat = 103 // 发送验证码过于频繁
    case UserAlreadyExist = 100
    case NotLogined = 508
    case LoginWithAnotherDevice = 520
    case UnclearedCOD = 627
    case UnclearedMandatory = 629
    case UnclearedShip = 631
    case MainOrderIsInProcess = 634
    case OrderItemOutOfStock = 638
    case CheckedToday = 105 // 已经签到
    case TokenInvalid = 102 // token 失效
}
class NetworkAccess {
    
    let networkReachabilityManager = NetworkReachabilityManager(host: "www.apple.com")
    let mAlamofire:SessionManager!
    var mHeader:[String: String]
    
    var networkIsAvailable = false
    
    weak var signInAC: UIAlertController?
    
    init() {
        
        _ = ServerTrustPolicy.performDefaultEvaluation(
            validateHost: true
        )

        var defaultHeaders = Alamofire.SessionManager.defaultHTTPHeaders
        defaultHeaders["Accept"] = "application/json"
        defaultHeaders["Content-Type"] = "application/json"
        
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = defaultHeaders
        configuration.timeoutIntervalForRequest = kNetworkTimeoutInterval

        mAlamofire = Alamofire.SessionManager(configuration: configuration)

        mHeader = [
            "Content-Type": "application/json"
        ]
    }
    
    func listen() {

    }
    
    func resetViewAfterCancelWhenLoginByAntherAccount() {

    }
    
    
    func request(_ method: HTTPMethod, url: String, parameters: [String: Any]? = nil,  callback: RequestCallBack? = nil) {
//        mHeader["UID"] =  biz.user?.userId
//        mHeader["Authorization"] =  biz.user?.token
//        printX("UID====\(biz.user?.userId)")
//        printX("token====\(biz.user?.token)")
        let tmpUrl = url.toUrl()
        if parameters != nil {
            if !JSONSerialization.isValidJSONObject(parameters!) {
                printX("Error: The parameters of url '" + url + "' is not a valid json")
                return
            }
        }
        printX("url: \(url), parameters: \(toJsonString(validDictionary(parameters)))")

            mAlamofire.request(tmpUrl, method: method, parameters: parameters, encoding: JSONEncoding.default, headers: mHeader)
            .validate()
            .responseJSON { response in

                self.handleResponseNew(method: method, url: tmpUrl, parameters: parameters, response: response) { data, error in
                    callback?(data, error)
                }
        }
    }
    
    
    
    func uploadFile(url: String, image: UIImage,parameters: [String: Any], callback: RequestCallBack? = nil) {
        
        mAlamofire.upload(multipartFormData: { (multipartFormData) in
            
            let data = image.resetImgSize(sourceImage: image, maxImageLenght: 100, maxSizeKB: 50)
            multipartFormData.append(data, withName: "file", fileName: "file12", mimeType: "image/jpg")
            for (key, value) in parameters {
                let str: String = validString(value)
                let _datas:Data = str.data(using:String.Encoding.utf8)!
                multipartFormData.append(_datas, withName:validString(key))
            }
        }, usingThreshold: 20480, to: url.toUrl(), method: .post, headers: mHeader) { (encodingResult) in
            switch encodingResult {
            case .success(let upload, _, _):
                upload.responseJSON { response in
                    printX(response)
                    let jsonObject = validDictionary(try? JSONSerialization.jsonObject(with: response.data!, options:JSONSerialization.ReadingOptions.allowFragments))
                    callback?(jsonObject, nil)
                }
            case .failure(let encodingError):
                callback?(nil, encodingError)
            }
        }
    
//        mAlamofire.upload(multipartFormData: { (multipartFormData) in
//            if let imageData = image.pngData() {
//                multipartFormData.append(imageData, withName: "file", fileName: "file12", mimeType: "image/jpg")
//            } else if let imageData = image.jpegData(compressionQuality: 0.2) {
//                multipartFormData.append(imageData, withName: "file", fileName: "file", mimeType: "image/jpg")
//            }
//            for (key, value) in parameters {
//                let str: String = validString(value)
//                let _datas:Data = str.data(using:String.Encoding.utf8)!
//                multipartFormData.append(_datas, withName:validString(key))
//            }
//        }, usingThreshold: 20480, to: url.toUrl(), method: .post, headers: mHeader) { (encodingResult) in
//            switch encodingResult {
//            case .success(let upload, _, _):
//                upload.responseJSON { response in
//                    printDebug(response)
//
//                }
//            case .failure(let encodingError):
//                callback?(nil, encodingError)
//            }
//        }
        
//            mAlamofire.upload(multipartFormData: { (multipartFormData)in
//                
//                for (key, value) in parameters {
//                    let str: String = validString(value)
//                    let _datas:Data = str.data(using:String.Encoding.utf8)!
//                    multipartFormData.append(_datas, withName:validString(key))
//                }
//                multipartFormData.append(data, withName:"file", fileName:  "file", mimeType:"image/png")
//                
//                }, to: validString(url)) { (result) in
//                    printX(result)
//                    switch result {
//                    case .success(let upload,_, _):
//                        upload.responseJSON(completionHandler: { (response)in
//                           printX(response)
//
//                        })
//                    case .failure:
//                        break
//
//                    }
//            }
//        }
    }

    func handleResponseNew(method: HTTPMethod, url: String, parameters: [String: Any]? = nil,  response: DataResponse<Any>, callback: RequestCallBack? = nil) {
        printX("url===\(url)")
        printX(parameters)
        printX(response)
        
        switch response.result {
        case .success:
            self.networkIsAvailable = true  // ensure the network status is updated immediately when request is ok
            let jsonObject = validDictionary(try? JSONSerialization.jsonObject(with: response.data!, options:JSONSerialization.ReadingOptions.allowFragments))
            switch validInt(jsonObject["code"]) {
            case APICodeType.Ok.rawValue:
                callback?(jsonObject, nil)
                break
            case APICodeType.CodeRepeat.rawValue:
                callback?(nil, jsonObject)
               break
            case APICodeType.UserAlreadyExist.rawValue:
                callback?(nil, jsonObject)
                break
            case APICodeType.LoginWithAnotherDevice.rawValue:
                
                let mAC = UIAlertController(title: "", message: kAccountSignOutByAnotherDeviceTip, preferredStyle: .alert)
                
                
                let signInAction = UIAlertAction(title: "登录", style: .default, handler: { action in

                    presentLoginVC({ (data, error) in

                        if error == nil {
                            self.request(method, url: url, parameters: parameters, callback: callback)
                        }
                    })
                })
                mAC.addAction(signInAction)
                getCurrentVCBS().present(mAC, animated: true, completion: nil)
            case APICodeType.TokenInvalid.rawValue:
                
                let mAC = UIAlertController(title: "", message: kAccountSignOutByAnotherDeviceTip, preferredStyle: .alert)
                
                let signInAction = UIAlertAction(title: "登录", style: .default, handler: { action in
                    
                    presentLoginVC({ (data, error) in
                        
                        if error == nil {
                            self.request(method, url: url, parameters: parameters, callback: callback)
                        }
                    })
                })
                mAC.addAction(signInAction)
                getCurrentVCBS().present(mAC, animated: true, completion: nil)
            case APICodeType.CheckedToday.rawValue:
                callback?(jsonObject, nil)
                break
            default:
                printDebug("SERVER API ERROR: " + validString(jsonObject["msg"]))
                callback?(nil, jsonObject)
            }
        case .failure(let error):
            callback?(nil, error.localizedDescription)

        }
    }
    
}
