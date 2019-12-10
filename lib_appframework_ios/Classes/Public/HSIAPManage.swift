//
//  HSIAPManage.swift
//  HSAppFramework
//
//  Created by jinlei.wang on 2019/10/17.
//  Copyright © 2019 iHandySoft Inc. All rights reserved.
//
import StoreKit

public let kHSIAPPurchaseSucceedNotification = "kHSIAPPurchaseSucceedNotification"

public class HSIAPManage: NSObject, SKPaymentTransactionObserver {
    private var productsRequest: HSIAPProductRequest?
    private var purchaseRequest: HSIAPPurchaseRequest?
    private var restoreRequest: HSIAPRestoreRequest?
    private var verifyReceiptPassword: String?
    
    public static let sharedInstance = HSIAPManage()

    private override init() {
        super.init()
        
        SKPaymentQueue.default().add(self)
    }
    
    deinit {
        SKPaymentQueue.default().remove(self)
    }
    
    /**
     开启内购监听，一般在didFinishLaunchingWithOptions实现
     */
    public func start() {
        print("HSIAPManage start...")
    }
    
    /**
     设置共享密钥，如果有自动续订的订阅商品，则必须设置此项，否则验证时返回21004错误
     
     - parameter password: 共享密钥
     */
    public func setVerifyReceiptPassword(password: String) {
        verifyReceiptPassword = password
    }
    
    /**
     判断是否允许付款,用户可以在Settings中禁用购买的功能, 购买前可以手动调用此方法确认一下
     
     - returns: 如果允许付款，则返回true,如果没有权限则返回false
     */
    public func canMakePayment() -> Bool {
        return SKPaymentQueue.canMakePayments();
    }
    
    /**
    判断是否有正在进行中的交易
    
     - returns: 是否存在正在进行中的交易
    */
    public func isPurchasing() -> Bool {
        for transcation in SKPaymentQueue.default().transactions {
            if transcation.transactionState == .purchasing {
                return true
            }
        }
        return false
    }
    
    /**
     请求商品信息
     
     - parameter productsID: 待请求的商品列表
     - parameter completion: 请求结果回调
     */
    public func requestProducts(productsID: [String], completion: ((Bool, [HSIAPProduct]?, String?) -> Void)?) {
        if self.productsRequest != nil {
            if let requestCompletion = completion {
                requestCompletion(false, nil, "requesting,please try again later");
            }
            return
        }
        
        self.productsRequest = HSIAPProductRequest()
        self.productsRequest?.start(productsID: productsID, completion: { [weak self] (sucess: Bool, products: [HSIAPProduct]?, error: String?) in
            if let requestCompletion = completion {
                requestCompletion(sucess, products, error);
            }
            self?.productsRequest = nil
        })
    }
    
    /**
     购买商品
     
     - parameter productsID: 购买商品的ID，一次只能购买一个商品
     - parameter completion: 购买商品结果回调
     */
    public func purchase(productID: String, completion: ((Bool, String?, String?, Double) -> Void)?) {
        if !self.canMakePayment() {
            if let purchaseCompletion = completion {
                purchaseCompletion(false, "can not make payment", nil, 0.0);
                return
            }
        }
        
        if self.purchaseRequest != nil {
            if let purchaseCompletion = completion {
                purchaseCompletion(false, "purchasing,please try again later", nil, 0.0);
                return
            }
        }
        
        self.purchaseRequest = HSIAPPurchaseRequest()
        self.purchaseRequest?.purchase(productID: productID, completion: { [weak self] (sucess: Bool, error: String?, productID: String?, expireDateMS: Double) in
            if let purchaseCompletion = completion {
                purchaseCompletion(sucess, error, productID, expireDateMS);
            }
            self?.purchaseRequest = nil
        })
    }
    
    /**
     恢复购买，刷新Bundle中收据，然后恢复所有的交易，最后再验证收据
     
     - parameter completion: 恢复购买结果回调
     */
    public func restore(completion: ((Bool, String?, String?, Double) -> Void)?) {
        if self.restoreRequest != nil {
            if let restoreCompletion = completion {
                restoreCompletion(false, "restoring,please try again later", nil, 0.0);
                return
            }
        }
        
        self.restoreRequest = HSIAPRestoreRequest()
        self.restoreRequest?.restore(completion: { [weak self] (success: Bool, error: String?, productID: String?, expireDateMS: Double) in
            if let restoreCompletion = completion {
                restoreCompletion(success, error, productID, expireDateMS);
                return
            }
            self?.restoreRequest = nil
        })
    }
    
    /**
     验证收据
     使用场景:
      1. 因为付费和restore都有较低的可能会验证失败, App可以选择引导用户 [1. (仅非消费型商品)重新购买 或2. restore 或3. 再验证一次 或4. 刷新收据后再验证一次]
      2. 如果有自动续订的商品. -----> 想更'及时'地知道用户续订了, 可以手动调用此方法进行验证并保存验证结果(否则发生续订时, 只有下次启动时 IAPKit 才会收到续订的消息并验证). 顺便一提:
      沙盒账号会提前一分钟开始续订, 大概几十秒钟完成续订交易, 正式账号是提前一天开始续订
     
     - parameter completion: 验证结果回调
     */
    public func verifyReceipt(completion: ((Bool, String?, String?, Double) -> Void)?) {
        HSIAPVerifyUtil.verify(env: .defaults, password: self.verifyReceiptPassword) { (success: Bool, error: String?, productID: String?, expireDateMS: Double) in
            if let verifyCompletion = completion {
                verifyCompletion(success, error, productID, expireDateMS);
            }
        }
    }
    
    /**
     获取收据
     
     - returns 收据信息
     */
    public func fetchReceiptData() -> Data? {
        if let receiptURL = Bundle.main.appStoreReceiptURL {
            return try? Data(contentsOf: receiptURL)
        }
        return nil
    }
    
    private func postPurchasSucceedNotification(success: Bool) {
        if success {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: kHSIAPPurchaseSucceedNotification), object: nil)
        }
    }
    
    // MARK: - SKPaymentTransactionObserver
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        var purchaseSuccess = false
        
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchasing:
                break
            case .purchased:
                purchaseSuccess = true
                SKPaymentQueue.default().finishTransaction(transaction)
                break
            case .failed:
                SKPaymentQueue.default().finishTransaction(transaction)
                if transaction.payment.productIdentifier == self.purchaseRequest?.productID {
                    self.purchaseRequest?.finish(success: false, error: transaction.error?.localizedDescription ?? "Purchase failed", productID: nil, expireDateMS: 0.0)
                }
                break
            case .restored:
                SKPaymentQueue.default().finishTransaction(transaction)
                break
            default:
                break
            }
        }
        
        if purchaseSuccess {
            self.verifyReceipt { (success: Bool, error: String?, productID: String?, expireDateMS: Double) in
                self.purchaseRequest?.finish(success: success, error: error, productID: productID, expireDateMS: expireDateMS)
                self.postPurchasSucceedNotification(success: success)
            }
        }
    }
    
    public func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        self.verifyReceipt { (success: Bool, error: String?, productID: String?, expireDateMS: Double) in
            self.restoreRequest?.finish(success: success, error: error, productID: productID, expireDateMS: expireDateMS)
            self.postPurchasSucceedNotification(success: success)
        }
    }
    
    public func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        self.restoreRequest?.finish(success: false, error: error.localizedDescription, productID: nil, expireDateMS: 0.0)
    }
    
    public func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool {
        self.purchase(productID: product.productIdentifier, completion: nil)
        return false
    }
}
