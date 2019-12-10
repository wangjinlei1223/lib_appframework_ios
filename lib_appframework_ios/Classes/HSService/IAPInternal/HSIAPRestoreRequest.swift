//
//  HSIAPRestoreRequest.swift
//  HSAppFramework
//
//  Created by jinlei.wang on 2019/10/17.
//  Copyright © 2019 iHandySoft Inc. All rights reserved.
//
import StoreKit

typealias RestoreCompletion = (Bool, String?, String?, Double) -> Void

class HSIAPRestoreRequest: NSObject, SKRequestDelegate {
    private var receiptRequest: SKReceiptRefreshRequest?
    private var completion: RestoreCompletion?
    
    /**
    开始恢复购买商品
     
     - parameter completion: 恢复购买结果回调
    */
    func restore(completion: RestoreCompletion?) {
        self.completion = completion
        self.receiptRequest = SKReceiptRefreshRequest()
        self.receiptRequest?.delegate = self
        self.receiptRequest?.start()
    }
    
    func finish(success: Bool, error: String?, productID: String?, expireDateMS: Double) {
        if let restoreCompletion = completion {
            restoreCompletion(success, error, productID, expireDateMS)
        }
    }
    
    // MARK: - SKRequestDelegate
    func requestDidFinish(_ request: SKRequest) {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        self.finish(success: false, error: error.localizedDescription, productID: nil, expireDateMS: 0.0)
    }
}
