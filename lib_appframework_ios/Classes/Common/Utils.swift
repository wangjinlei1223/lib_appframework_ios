//
//  Utils.swift
//  HSAppFramework
//
//  Created by kai.sun on 2019/10/31.
//  Copyright © 2019 iHandySoft Inc. All rights reserved.
//

import UIKit

func RGBA(_ R: Double, _ G: Double, _ B: Double, _ A: Double) -> UIColor {
    UIColor(red: CGFloat(R / 255.0), green: CGFloat(G / 255.0), blue: CGFloat(B / 255.0), alpha: CGFloat(A))
}
//
//func RGBCOLOR_HEX(_ hexColor: Any) -> UIColor {
//    UIColor(red: ((hexColor >> 16) & 0xff) / 255.0, green: ((hexColor >> 8) & 0xff) / 255.0, blue: (hexColor & 0xff) / 255.0, alpha: 1)
//}

let kNotficationName_DeviceTokenDidChange = Notification.Name("kHSNotficationName_DeviceTokenDidChange")
let kHSUserDefaultKey_CurrentDeviceToken : String = "kHSUserDefaultKey_CurrentDeviceToken"
let kHSUserDefaultsKey_CustomerUserID : String = "kHSUserDefaultsKey_CustomerUserID"

class Utils: NSObject {
    
    /**
    *   判断当前系统版本是否早于 version
    *
    *  @param version version
    *
    *  @return 是否早于
    */
    class func isOSVersionPriorTo(version:Float) -> Bool {
        guard let currentVersion : Float = Float(UIDevice.current.systemVersion) else {
            return false
        }
        return currentVersion < version
    }
    
    /**
    *   在系统版本早于 version 的情况下执行 priorBlock，大于等于 version 的版本上执行 geqBlock
    *
    *  @param priorBlock priorBlock
    *  @param version    version
    *  @param geqBlock   geqBlock
    */
    class func execute(priorBlock: @escaping () -> (Void), ifVersionPriorTo version:Float, otherwiseExecute geqBlock: @escaping () -> (Void)) {
        if self.isOSVersionPriorTo(version: version) {
            priorBlock()
        } else {
            geqBlock()
        }
    }
    
    /**
    *  JSON serialize
    *
    *  @param object object 需要序列化的 json 对象， NSArray 或者 NSDictionary
    *
    *  @return 反序列化之后的 json 串
    */
    class func jsonStringWithObject(object: Any) -> String? {
        var jsonString : String? = nil
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: object, options: .prettyPrinted)
            jsonString = String.init(data: jsonData, encoding: .utf8)
        } catch {
        }
        return jsonString
    }
    
    class func jsonObjectWithString(jsonString: String) -> Any? {
        var jsonObject : Any? = nil
        do {
            guard let stringData = jsonString.data(using: .utf8) else {
                return nil
            }
            let object = try JSONSerialization.jsonObject(with: stringData, options: .allowFragments)
            jsonObject = object
        } catch  {
        }
        return jsonObject
    }
    
    /**
    *  获取 Document 目录的完整路径
    *
    *  @return Document 目录的完整路径
    */
    class func documentDirectoryPath() -> String? {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        return paths.first
    }
    
    class func encodedStringForString(string: String) -> String? {
        let encodedString = NSString.init(string: string).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        return encodedString
    }
    class func decodedStringForString(string: String) -> String? {
        let decodedString = NSString.init(string: string).removingPercentEncoding
        return decodedString
    }
    
    /**
    *  获取程序 Entitlements 中 com.apple.security.application-groups 中的值，我们只配置一项，
    *
    libCommons:
      Entitlements:
        AppleSecurityApplicationGroup: "apple.security.application-groups"
    *  @return AppleSecurityApplicationGroup 对应的值
    */
    class func appSecurityApplicationGroup() -> String? {
        let dataDic = NSDictionary.init(dictionary: HSLocalConfig.instance.data!)
        return dataDic.value(forKeyPath: "libCommons.Entitlements.AppleSecurityApplicationGroup") as? String
    }
    
    // 返回相对于格林威治标准时间的偏移秒数
    class func timeZone() -> Int {
        return TimeZone.autoupdatingCurrent.secondsFromGMT()
    }
    
    // 本地读取手机配置的国家/地区简写 e.g. US 即 country code
    class func region() -> String {
        let countryCode : String = ((Locale.current as NSLocale).object(forKey: .countryCode) as? String)?.uppercased() ?? "ZZ"
        return countryCode
    }
    
    class func deviceID() -> String? {
        if Utils.isOSVersionPriorTo(version: 6.0) {
            return "Unknown id"
        } else {
            let uuid = UIDevice.current.identifierForVendor
            return uuid?.uuidString
        }
    }
    
    class func deviceToken() -> String? {
        return UserDefaults.standard.object(forKey: kHSUserDefaultKey_CurrentDeviceToken) as? String
    }
    
    class func appID() -> String? {
        let dataDic = NSDictionary.init(dictionary: HSLocalConfig.instance.data!)
        let appId : String = dataDic.value(forKeyPath: "libCommons.AppID") as? String ?? ""
        return appId.count < 1 ? nil : appId
    }
    
    class func MD5String(string: String?) -> String? {
        if let strData = string?.data(using: .utf8) {
            var buffer = [UInt8](repeating: 0, count: 16)
            strData.withUnsafeBytes {
                CC_MD5($0.baseAddress, UInt32(strData.count), &buffer)
            }
            var md5String = ""
            for byte in buffer {
                md5String += String(format: "%02x", UInt8(byte))
            }
            
            return md5String
        }
        return nil
    }
    
    class func customerUserID() -> String? {
        var customerUserID : String? = UserDefaults.standard.string(forKey: kHSUserDefaultsKey_CustomerUserID)
        if customerUserID == nil {
            if !ASIdentifierManager.shared().isAdvertisingTrackingEnabled {
                customerUserID = UIDevice.current.identifierForVendor?.uuidString
            } else {
                customerUserID = ASIdentifierManager.shared().advertisingIdentifier.uuidString
            }
            UserDefaults.standard.set(customerUserID, forKey: kHSUserDefaultsKey_CustomerUserID)
            UserDefaults.standard.synchronize()
        }
        return customerUserID
    }
    
    class func saveDeviceToken(deviceToken: Data) {
        if deviceToken.count == 0 {
            return
        }
        let deviceTokenString : String = deviceToken.description.trimmingCharacters(in: CharacterSet.init(charactersIn: "<>")).replacingOccurrences(of: " ", with: "")
        
        if deviceTokenString.count == 0 {
            return
        }
        
        let oldDeviceToken : String? = UserDefaults.standard.object(forKey: kHSUserDefaultKey_CurrentDeviceToken) as? String
        
        UserDefaults.standard.set(deviceTokenString, forKey: kHSUserDefaultKey_CurrentDeviceToken)
        UserDefaults.standard.synchronize()
        
        if oldDeviceToken != deviceTokenString {
            NotificationCenter.default.post(name: kNotficationName_DeviceTokenDidChange, object: nil)
        }
    }
}
