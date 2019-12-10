//
//  GDPRAssent.swift
//  HSAppFramework
//
//  Created by kai.sun on 2019/10/14.
//  Copyright © 2019 iHandySoft Inc. All rights reserved.
//

import UIKit

enum GdprAssentState {
    /// 未知状态，同步版本中不会出现
    case Unknown
    /// 用户未做出选择
    case ToBeConfirmed
    /// 用户已同意收集数据，或者用户不在GDPR范围
    case Accepted
    /// 用户已拒绝收集数据
    case Declined
}

enum GdprAssentAlertStyle {
    /// 用户必须接受的样式
    case Continue
    /// 用户可以接受或拒绝的样式
    case Agree
}

let LEGdprAssentDidChangeGrantNotification : NSNotification.Name = NSNotification.Name(rawValue: "GDPRAssentDidChangeGrantNotification")

let LEGdprAssentStateKey = "GDPRAssentState";
let LEGdprAssentGrantStateKey = "GDPRAssentGrantState"
let LEGdprAssentAlertMadeChoiceKey = "GDPRAssentAlertMadeChoice"

@objc class GDPRAssent: NSObject {
    private(set) var isGdprUser: Bool
    var gdprState : GdprAssentState {
        set {
//            self.gdprState = newValue
            let user = UserDefaults.standard
            guard let value = user.object(forKey: LEGdprAssentStateKey) else {
                return
            }
            if newValue == value as! GdprAssentState {
                return
            }
            user.set(newValue, forKey: LEGdprAssentStateKey)
            user.synchronize()
            
            NotificationCenter.default.post(name: LEGdprAssentDidChangeGrantNotification, object: nil)
//            self.spreadStateToDeqendentLibraries()
        }
        
        get {
            return (UserDefaults.standard.object(forKey: LEGdprAssentStateKey) ?? GdprAssentState.Unknown) as! GdprAssentState
        }
    }
    
    @objc public var granted : Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: LEGdprAssentGrantStateKey)
            UserDefaults.standard.synchronize()
            self.updateState()
        }
        
        @objc get {
            return (self.grantGDPRStateValue() as AnyObject).boolValue ?? false
        }
    }
    
// MARK: Singleton Instance
    @objc static let shareInstance = GDPRAssent();
    override init() {
        isGdprUser = false
        super.init()
        
        let countryCode : String = ((Locale.current as NSLocale).object(forKey: .countryCode) as? String)?.uppercased() ?? ""
        isGdprUser = self.isGDPRUserWithCountryCode(countryCode: countryCode)
        
        self.updateState()
    
        let value = UserDefaults.standard.object(forKey: LEGdprAssentStateKey)
        self.gdprState = value == nil ? GdprAssentState.Unknown : value as! GdprAssentState
    }
    
// MARK: Public function
    @objc(isGDPRAccepted) func isGDPRAccepted() -> Bool {
        return self.gdprState == GdprAssentState.Accepted
    }
    
    @objc(isGDPRUser) func isGDPRUser() -> Bool {
        return self.isGdprUser
    }
    
    @objc(isAlertMadeChoice) func isAlertMadeChoice() -> Bool {
        return UserDefaults.standard.bool(forKey: LEGdprAssentAlertMadeChoiceKey)
    }
    
    @objc(showAlertWithParent:style:moreURL:completion:) func showAlertWithParent(parent:UIViewController, style:NSInteger, moreURL:NSURL, completion: @escaping (Bool) -> Void) {
        let block = {(granted : Bool) -> Void in
            UserDefaults.standard.set(true, forKey: LEGdprAssentAlertMadeChoiceKey)
            self.granted = granted
            completion(granted)
            parent.dismiss(animated: true, completion: nil);
        }
        let vc = GDPRAgreeAlertViewController(style: style == 1 ? GdprAssentAlertStyle.Agree : GdprAssentAlertStyle.Continue, moreURL: moreURL as URL, completion: block)
        parent.present(vc, animated: true, completion: nil)
    }
    
// MARK: Private Function
    private func isGDPRUserWithCountryCode(countryCode: String) -> Bool {
        return self.affactCountryCodes().contains(countryCode)
    }
    
    private func updateState() {
        if self.isGDPRUser() {
            self.gdprState = self.gdprStateWithGrantState()
        }
        self.gdprState = GdprAssentState.Accepted
    }
    
    private func gdprStateWithGrantState() -> GdprAssentState {
        let isGranted : Any? = self.grantGDPRStateValue()
        if (isGranted != nil) && isGranted is NSNumber {
            if (isGranted as! NSNumber).boolValue {
                return GdprAssentState.Accepted
            } else {
                return GdprAssentState.Declined
            }
        }
        return GdprAssentState.ToBeConfirmed
    }
    
    private func grantGDPRStateValue() -> Any? {
        return UserDefaults.standard.object(forKey: LEGdprAssentGrantStateKey)
    }
    
    private func affactCountryCodes() -> [String] {
        let codes : [String] = [
                // EU
                "AT", // 奥地利
                "BE", // 比利时
                "BG", // 保加利亚
                "CY", // 塞浦路斯
                "CZ", // 捷克
                "DK", // 丹麦
                "EE", // 爱沙尼亚
                "FI", // 芬兰
                "DE", // 德国
                "HR", // 克罗地亚
                "FR", // 法国
                "GR", // 希腊
                "HU", // 匈牙利
                "IE", // 爱尔兰
                "IT", // 意大利
                "IS", // 冰岛
                "LI", // 列支敦士登
                "LV", // 拉脱维亚
                "LT", // 立陶宛
                "LU", // 卢森堡
                "MT", // 马耳他 MLT
                "NL", // 荷兰
                "NO", // 挪威
                "PL", // 波兰
                "PT", // 葡萄牙
                "RO", // 罗马尼亚
                "SK", // 斯洛伐克 SVK
                "SI", // 斯洛文尼亚
                "ES", // 西班牙
                "SE", // 瑞典
                // Other
                "GB", // 英国
        ]
        return codes
    }
}
