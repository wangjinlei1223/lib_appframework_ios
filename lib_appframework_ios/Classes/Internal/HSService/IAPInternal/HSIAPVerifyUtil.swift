//
//  HSIAPVerifyUtil.swift
//  HSAppFramework
//
//  Created by jinlei.wang on 2019/10/17.
//  Copyright © 2019 iHandySoft Inc. All rights reserved.
//
import UIKit

enum HSIAPEnv {
    case defaults
    case debug
    case release
}

typealias VerifyCompletion = (Bool, String?, String?, Double) -> Void

class HSIAPVerifyUtil: NSObject {
    
    /**
    验证发票信息
     
     - parameter env: 验证环境
     - parameter password: 共享密钥
     - parameter completion: 验证结果回调
    */
    static func verify(env: HSIAPEnv, password: String?, completion: VerifyCompletion?) {
        
        let appStoreReceiptURL = Bundle.main.appStoreReceiptURL
        
        guard let receiptURL = appStoreReceiptURL else {
            if let verifyCompletion = completion {
                verifyCompletion(false, "NO Receipt", nil, 0.0)
            }
            return
        }
        
        let receiptData = try? Data(contentsOf: receiptURL)
        guard let receipt = receiptData else {
            if let verifyCompletion = completion {
                verifyCompletion(false, "NO Receipt", nil, 0.0)
            }
            return
        }
        
        let receiptBase64 = receipt.base64EncodedString(options: [])
        var parameters: [String : Any] = ["receipt-data": receiptBase64, "exclude-old-transactions": true]
        if let verifyPassword = password {
            parameters["password"] = verifyPassword
        }
        
        HSNetworkUtils.post(url: verifyReceiptURL(env: env), parameters: parameters) { (success: Bool, error: Error?, result: Any?) in
            if !success {
                if let verifyCompletion = completion {
                    verifyCompletion(false, error?.localizedDescription, nil, 0.0)
                }
                return
            }
            
            guard let letResult = result as? [String:Any] else {
                if let verifyCompletion = completion {
                    verifyCompletion(false, "验证收据，解析错误", nil, 0.0)
                }
                return
            }
            
            guard let status = letResult["status"] as? Int else {
                if let verifyCompletion = completion {
                    verifyCompletion(false, "验证收据，解析错误", nil, 0.0)
                }
                return
            }
            
            if status != 0 {
                if status == 21007 && env != .debug {
                    // 测试的receipt提交到了正式环境服务器验证，需要切换到测试环境重新验证
                    self.verify(env: .debug, password: password, completion: completion)
                    return
                }
                
                if status == 21008 && env != .release {
                    // 正式的receipt提交到了测试环境服务器验证，需要切换到正式环境重新验证
                    self.verify(env: .release, password: password, completion: completion)
                    return
                }
                
                if let verifyCompletion = completion {
                    verifyCompletion(false, "FailStatus: \(status)", nil, 0.0)
                }
                return
            }
            
            let receipt = letResult["receipt"] as? [String:Any]
            let inAppTransactions = receipt?["in_app"] as? [[String: Any]]
            let latestTransactions = letResult["latest_receipt_info"] as? [[String: Any]]
            
            let appResult = findValidProduct(transactions: inAppTransactions)
            let latestResult = findValidProduct(transactions: latestTransactions)
            
            var productID: String?
            var expireDateMS: Double = 0.0
            
            if appResult.productID != nil && latestResult.productID != nil {
                if appResult.expireDateMS >= latestResult.expireDateMS {
                    productID = appResult.productID
                    expireDateMS = appResult.expireDateMS
                } else {
                    productID = latestResult.productID
                    expireDateMS = latestResult.expireDateMS
                }
            }
            
            if let verifyCompletion = completion {
                if productID == nil || expireDateMS <= 0 {
                    verifyCompletion(false, "productID无效", nil, 0.0)
                } else {
                    verifyCompletion(true, nil, productID, expireDateMS)
                }
            }
        }
    }
    
    private static func findValidProduct(transactions: [[String: Any]]?) -> (productID: String?, expireDateMS: Double) {
        var productID: String? = nil
        var productExpiresDateMS = 0.0
        
        if transactions == nil {
            return (productID, productExpiresDateMS)
        }
        
        for t in transactions! {
            let product_id = t["product_id"] as? String
            if product_id == nil {
                continue
            }
            
            if t["cancellation_date"] != nil {
                //已取消的商品不用管
                continue
            }
            
            let expiresDateMSString = t["expires_date_ms"] as? String
            if expiresDateMSString != nil {
                let currentExpiresDateMS = Double(expiresDateMSString!) ?? 0
                if currentExpiresDateMS > productExpiresDateMS {
                    productExpiresDateMS = currentExpiresDateMS
                    productID = product_id
                }
            }
        }
        return (productID, productExpiresDateMS)
    }
    
    private static func verifyReceiptURL(env: HSIAPEnv) -> String {
        if env == .debug {
            return "https://sandbox.itunes.apple.com/verifyReceipt"
        }
        
        if env == .release {
            return "https://buy.itunes.apple.com/verifyReceipt"
        }
        
        #if DEBUG
            return "https://sandbox.itunes.apple.com/verifyReceipt"
        #else
            return "https://buy.itunes.apple.com/verifyReceipt"
        #endif
    }
}
