//
//  HSIAPProductRequest.swift
//  HSAppFramework
//
//  Created by jinlei.wang on 2019/10/16.
//  Copyright © 2019 iHandySoft Inc. All rights reserved.
//
import StoreKit

typealias RequestCompletion = (Bool, [HSIAPProduct]?, String?) -> Void

class HSIAPProductRequest: NSObject, SKProductsRequestDelegate {
    private var productsRequest: SKProductsRequest?
    private var completion: RequestCompletion?

    /**
     开始请求商品信息
     
     - parameter productsID: 待请求的商品列表
     - parameter completion: 请求结果回调
     */
    func start(productsID: [String], completion: RequestCompletion?) {
        self.completion = completion
        
        if productsID.count == 0 {
            self.finish(success: false, products: nil, error: "Please Input ProductIDs")
            return;
        }
        
        self.productsRequest = SKProductsRequest(productIdentifiers: Set(productsID))
        self.productsRequest?.delegate = self;
        self.productsRequest?.start()
    }
    
    /**
     请求商品信息结束
     
     - parameter success:  是否成功
     - parameter products: 商品列表
     - parameter error:    错误信息
     */
    private func finish(success: Bool, products: [HSIAPProduct]?, error: String?) {
        if let requestCompletion = self.completion {
            DispatchQueue.main.async {
                requestCompletion(success, products, error)
            }
        }
    }
    
    // MARK: - SKProductsRequestDelegate
    func request(_ request: SKRequest, didFailWithError error: Error) {
        self.finish(success: false, products: nil, error: error.localizedDescription)
    }
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        if response.products.count == 0 {
            self.finish(success: false, products: nil, error: "ProductIDs is invalided")
            return
        }
        
        var products = [HSIAPProduct]()
        for skProduct in response.products {
            let product = HSIAPProduct()
            product.productID = skProduct.productIdentifier
            product.localizedTitle = skProduct.localizedTitle
            product.localizedDescription = skProduct.localizedDescription
            product.price = skProduct.price.floatValue
            product.priceSymbol = skProduct.priceLocale.currencySymbol
            product.countryCode = skProduct.priceLocale.regionCode
            product.skProduct = skProduct
            
            products.append(product)
        }
        self.finish(success: true, products: products, error: nil)
    }
}
