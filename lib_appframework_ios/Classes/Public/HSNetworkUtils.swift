//
//  HSNetworkUtils.swift
//  HSAppFramework
//
//  Created by jinlei.wang on 2019/10/17.
//  Copyright © 2019 iHandySoft Inc. All rights reserved.
//
import Alamofire

public class HSNetworkUtils: NSObject {
    
    /**
     GET 请求
     
     - parameter url:        请求URL
     - parameter parameters: 请求参数
     - parameter completion: 请求结果回调
     */
    public static func get(url: String, parameters: [String: Any]?, completion: ((Bool, Error?, Any?) -> Void)?) {
        request(url: url, method: .get, parameters: parameters, encoding: URLEncoding.default, headers: nil, completion: completion)
    }
    
    /**
     POST 请求
     
     - parameter url:        请求URL
     - parameter parameters: 请求参数
     - parameter completion: 请求结果回调
     */
    public static func post(url: String, parameters: [String: Any]?, completion: ((Bool, Error?, Any?) -> Void)?) {
        request(url: url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: nil, completion: completion)
    }
    
    /**
     网络请求
     
     - parameter url:        请求URL
     - parameter method:     请求方法
     - parameter parameters: 请求参数
     - parameter encoding:   参数编码，默认是`URLEncoding.default`
     - parameter headers:    请求头部内容，默认`nil`
     - parameter completion: 请求结果回调
     */
    public static func request(url: String, method: HTTPMethod, parameters: [String: Any]?, encoding: ParameterEncoding, headers:HTTPHeaders?, completion: ((Bool, Error?, Any?) -> Void)?) {
        Alamofire.request(url, method: method, parameters: parameters, encoding: encoding, headers: headers).responseJSON { (response) in
            if let letCompletion = completion {
                letCompletion(response.result.isSuccess, response.result.error, response.result.value)
            }
        }
    }
    
    /**
     文件下载
     
     - parameter url:              下载URL
     - parameter savePathURL:      文件存储路径
     - parameter downloadProgress: 下载进度回调
     - parameter completion:       结果回调
     */
    public static func download(url: String, savePathURL: URL, downloadProgress: ((Double) -> Void)?, completion: ((Bool, Error?, URL) -> Void)?) {
        let destination: DownloadRequest.DownloadFileDestination = {_,_ in
            return (savePathURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        Alamofire.download(url, to: destination)
            .downloadProgress { (progress) in
                if let letProgress = downloadProgress {
                    letProgress(progress.fractionCompleted)
                }
            }
            .responseData { (response) in
                if let letCompletion = completion {
                    letCompletion(response.result.isSuccess, response.result.error, savePathURL)
                }
            }
    }
    
    /**
    文件上传
     
    - parameter url:             上传URL
    - parameter uploadFileURL:   要上传文件路径
    - parameter uploadProgress:  上传进度回调
    - parameter completion:      结果回调
    */
    public static func upload(url: String, uploadFileURL: URL, uploadProgress: ((Double) -> Void)?, completion:((Bool, Error?, URL) -> Void)?) {
        Alamofire.upload(uploadFileURL, to: url)
            .uploadProgress { (progress) in
                if let letProgress = uploadProgress {
                    letProgress(progress.fractionCompleted)
                }
            }
            .responseJSON { (response) in
                if let letCompletion = completion {
                    letCompletion(response.result.isSuccess, response.result.error, uploadFileURL)
                }
            }
    }
}
