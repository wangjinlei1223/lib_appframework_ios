//
//  HSIAPProduct.swift
//  HSAppFramework
//
//  Created by jinlei.wang on 2019/10/16.
//  Copyright © 2019 iHandySoft Inc. All rights reserved.
//
import StoreKit

public class HSIAPProduct: NSObject {
    /**
     商品ID
     */
    public var productID: String?
    
    /**
     商品名称
     */
    public var localizedTitle: String?
    
    /**
     商品描述
     */
    public var localizedDescription: String?
    
    /**
     本地化货币符号
     */
    public var priceSymbol: String?
    
    /**
     本地化国家代码
     */
    public var countryCode: String?
    /**
    本地化商品价格
    */
    public var price: Float = 0.0
    
    /**
     商品原始数据
     */
    public var skProduct: SKProduct?
}
