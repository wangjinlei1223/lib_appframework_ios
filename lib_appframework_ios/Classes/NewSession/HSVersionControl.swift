//
//  HSVersionControl.swift
//  HSAppFramework
//
//  Created by long.liu on 2019/10/14.
//  Copyright © 2019年 iHandySoft Inc. All rights reserved.
//

import Foundation
import UIKit

final class HSVersionControl {
    class func appVersion() -> String? {
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String;
        return shortVersion;
    }
    
    class func osVersion() -> String? {
        return UIDevice.current.systemVersion;
    }
    
    class func isFirstLaunchSinceInstallation() -> Bool {
        return HSApplication.sharedInstance().currentLaunchInfo?.launchID == 1;
    }
    
    class func isFirstLaunchSinceOSUpgrade() -> Bool {
        return HSVersionControl.compareVersion(formVersion: HSApplication.sharedInstance().currentLaunchInfo?.osVersion, toVersion: HSApplication.sharedInstance().lastLaunchInfo?.osVersion) == .orderedDescending
    }
    
    class func isFirstLaunchSinceUpgrade() -> Bool {
        return HSVersionControl.compareVersion(formVersion: HSApplication.sharedInstance().currentLaunchInfo?.appVersion, toVersion: HSApplication.sharedInstance().lastLaunchInfo?.appVersion) == .orderedDescending
    }
    
    class func isFirstSessionSinceInstallation() -> Bool {
        return HSSessionManager.shared.currentSessionID == 1 && HSSessionManager.shared.isFirstSessionInCurrentLaunch
    }
    
    class func isFirstSessionSinceOSUpgrade() -> Bool {
        return self.isFirstLaunchSinceOSUpgrade() && HSSessionManager.shared.isFirstSessionInCurrentLaunch
    }
    
    class func isFirstSessionSinceUpgrade() ->Bool {
        return self.isFirstLaunchSinceUpgrade() && HSSessionManager.shared.isFirstSessionInCurrentLaunch
    }

    class func isUpdateUser() -> Bool {
        return !(HSApplication.sharedInstance().firstLaunchInfo?.appVersion == HSApplication.sharedInstance().currentLaunchInfo?.appVersion)
    }
    
    //todo 这个访问权限的测试一下用哪个 public、open、internal、fileprivate、private
    fileprivate class func compareVersion(formVersion: String?, toVersion: String?) -> ComparisonResult {
        // Version格式是类似于1.2.3这样的
        var formVersionArray: [String]? = nil
        if let components = formVersion?.components(separatedBy: ".") {
            formVersionArray = components;
        }
        
        var toVersionArray: [String]? = nil
        if let components = toVersion?.components(separatedBy: ".") {
            toVersionArray = components
        }
        
        let count1 = formVersionArray?.count ?? 0
        let count2 = toVersionArray?.count ?? 0

        // 从左向右比较
        for i in 0..<count1 {
            if i >= count1 {
                if Int(toVersionArray?[i] ?? "") ?? 0 > 0 {
                    // 如果前辍相同且version1比较短，那么version2比较大（但认为5.0==5.0.0，所以这里要加上>0的判断）
                    return .orderedAscending
                }
            } else if i >= count2 {
                if Int(formVersionArray?[i] ?? "") ?? 0 > 0 {
                    // 如果前辍相同且version2比较短，那么version1比较大（但认为5.0==5.0.0，所以这里要加上>0的判断）
                    return .orderedDescending
                }
            } else {
                if Int(formVersionArray?[i] ?? "") ?? 0 < Int(toVersionArray?[i] ?? "") ?? 0 {
                    // 从左向右比较，如果某位上version1比version2小，那么version1<version2
                    return .orderedAscending
                } else if Int(formVersionArray?[i] ?? "") ?? 0 > Int(toVersionArray?[i] ?? "") ?? 0 {
                    // 从左向右比较，如果某位上version1比version2大，那么version1>version2
                    return .orderedDescending
                }
            }
        }

        // 从左向右比较，如果所有位上version1和version2相等，那么version1==version2
        return .orderedSame
    }
}
