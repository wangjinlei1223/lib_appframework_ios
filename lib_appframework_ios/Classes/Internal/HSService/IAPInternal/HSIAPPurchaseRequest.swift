//
//  HSIAPPurchaseRequest.swift
//  HSAppFramework
//
//  Created by jinlei.wang on 2019/10/16.
//  Copyright © 2019 iHandySoft Inc. All rights reserved.
//
import StoreKit

typealias PurchaseCompletion = (Bool, String?, String?, Double) -> Void

class HSIAPPurchaseRequest: NSObject {
    private var completion: PurchaseCompletion?
    private var productRequest: HSIAPProductRequest?
    public var productID = ""
    
    /**
    开始购买商品
     
     - parameter productID:  待购买商品的ID
     - parameter completion: 购买结果回调
    */
    func purchase(productID: String, completion: PurchaseCompletion?) {
        self.productID = productID
        self.completion = completion
        self.productRequest = HSIAPProductRequest()
        self.productRequest?.start(productsID: [productID], completion: { [weak self] (sucess: Bool, products: [HSIAPProduct]?, error: String?) in
            if sucess {
                let skProduct = products?.first?.skProduct
                if let product = skProduct {
                    let payment = SKMutablePayment(product: product)
                    SKPaymentQueue.default().add(payment)
                    return
                }
            }
            self?.finish(success: false, error: error ?? "request product error", productID: nil, expireDateMS: 0.0)
            self?.productRequest = nil
        })
    }
    
    func finish(success: Bool, error: String?, productID: String?, expireDateMS: Double) {
        if let purchaseCompletion =  completion {
            purchaseCompletion(success, error, productID, expireDateMS)
        }
    }
}
