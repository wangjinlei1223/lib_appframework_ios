//
//  HSApplication.swift
//  HSAppFramework
//
//  Created by long.liu on 2019/10/14.
//  Copyright © 2019年 iHandySoft Inc. All rights reserved.
//

import Foundation
import UIKit

var isDebugEnabled: Bool = false;

private let kLEUserDefaultsKey_FirstLaunchInfo = "kLEUserDefaultsKey_FirstLaunchInfo";
private let kLEUserDefaultsKey_LastLaunchInfo = "kLEUserDefaultsKey_LastLaunchInfo";

private let kKey_LaunchID = "launchId";
private let kKey_AppVersion = "appVersion";
private let kKey_OSVersion = "osVersion";

private let LIB_VER = "com_ihandysoft_appframework_version_3_4_0_beta03"

enum LELaunchInfoType {
    case LELaunchInfoType_Unknown
    case LELaunchInfoType_First
    case LELaunchInfoType_Last
}

enum LEError: Error {
    case RuntimeError(String)
}

class LELaunchInfo: NSCopying {
    var launchID: Int = 0; //打开程序时的 launch ID，首次打开为 1，以后每次全新打开 app 此数值 +1
    var appVersion: String?
    var osVersion: String?

    class func launchInfo(for type: LELaunchInfoType) -> Self? {
        return launchInfoHelper(for: type)
    }

    private class func launchInfoHelper<T>(for type: LELaunchInfoType) -> T? {
        let info = LELaunchInfo()

        var dict: [AnyHashable : Any]? = nil
        let defaults = UserDefaults.standard
        switch type {
        case .LELaunchInfoType_First:
            dict = defaults.object(forKey: kLEUserDefaultsKey_FirstLaunchInfo) as? [AnyHashable : Any]
        case .LELaunchInfoType_Last:
            dict = defaults.object(forKey: kLEUserDefaultsKey_LastLaunchInfo) as? [AnyHashable : Any]
        default:
            break
        }

        if type != .LELaunchInfoType_Unknown && dict?.count != 3 {
            return nil
        }

        info.launchID = dict?[kKey_LaunchID] as? Int ?? 0
        info.appVersion = dict?[kKey_AppVersion] as? String ?? nil
        info.osVersion = dict?[kKey_OSVersion] as? String ?? nil
        return info as? T
    }

    func synchronize(for type: LELaunchInfoType) throws{
        var dict: [AnyHashable : Any]? = [:]
        //todo need test
        dict?[kKey_LaunchID] = launchID
        dict?[kKey_AppVersion] = appVersion
        dict?[kKey_OSVersion] = osVersion

        let defaults = UserDefaults.standard;
        switch type {
        case .LELaunchInfoType_First:
            defaults.set(dict, forKey: kLEUserDefaultsKey_FirstLaunchInfo)
        case .LELaunchInfoType_Last:
            defaults.set(dict, forKey: kLEUserDefaultsKey_LastLaunchInfo)
        default:
            //todo NSException
            throw LEError.RuntimeError("Can not synchronize unknown launch info")
        }
        defaults.synchronize();
    }

    func copy(with zone: NSZone? = nil) -> Any {
        let info = LELaunchInfo()
        info.launchID = launchID
        info.appVersion = appVersion
        info.osVersion = osVersion
        return info
    }
}

public class LEApplication: UIResponder {
    private var appLaunchingIntoBackground: Bool = false

    var firstLaunchInfo: LELaunchInfo?
    var lastLaunchInfo: LELaunchInfo?
    var currentLaunchInfo: LELaunchInfo?

    public static var debugEnabled: Bool = false
    /***
     这个不能再HSApplication里使用
     */
    private static var instance: LEApplication? = nil

    class func sharedInstance() -> LEApplication {
        let dele = UIApplication.shared.delegate

        if let application = dele as? LEApplication {
            return application
        } else {
            return instance ?? LEApplication()
        }

    }
    //子类重写
    func onApplicationStart() {
        
    }

    func initializeLaunchInfo() throws {

        if LEVersionControl.appVersion()?.count == 0 {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()) {
                let alert = UIAlertController.init(title: "You must specify CFBundleShortVersionString in your info.plist", message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction.init(title: "OK", style: .cancel, handler: nil))

                (UIApplication.shared.delegate?.window as? UIWindow)?.rootViewController?.present(alert, animated: false, completion: nil)
            }
        }

        firstLaunchInfo = LELaunchInfo.launchInfo(for: .LELaunchInfoType_First)
        lastLaunchInfo = LELaunchInfo.launchInfo(for: .LELaunchInfoType_Last)

        if firstLaunchInfo == nil && lastLaunchInfo != nil {
            firstLaunchInfo = lastLaunchInfo?.copy() as? LELaunchInfo ?? nil
            try firstLaunchInfo?.synchronize(for: .LELaunchInfoType_First)
        } else if firstLaunchInfo != nil && lastLaunchInfo == nil {
            lastLaunchInfo = firstLaunchInfo?.copy() as? LELaunchInfo ?? nil
            try lastLaunchInfo?.synchronize(for: .LELaunchInfoType_Last)
        }

        currentLaunchInfo = LELaunchInfo()
        currentLaunchInfo?.appVersion = LEVersionControl.appVersion()
        currentLaunchInfo?.osVersion = LEVersionControl.osVersion()

        if firstLaunchInfo == nil && lastLaunchInfo == nil {
            currentLaunchInfo?.launchID = 1;
            firstLaunchInfo = currentLaunchInfo?.copy() as? LELaunchInfo ?? nil
            lastLaunchInfo = currentLaunchInfo?.copy() as? LELaunchInfo ?? nil

            try firstLaunchInfo?.synchronize(for: .LELaunchInfoType_First)
            try lastLaunchInfo?.synchronize(for: .LELaunchInfoType_Last)
        } else if firstLaunchInfo != nil && lastLaunchInfo != nil {
            currentLaunchInfo?.launchID = (lastLaunchInfo?.launchID ?? 0) + 1;

            try currentLaunchInfo?.synchronize(for: .LELaunchInfoType_Last)
        }
    }

    class func isDebugEnabled() -> Bool {
        return debugEnabled
    }

    class func setDebugEnabled(enabled: Bool) {
        debugEnabled = enabled
    }
}

extension LEApplication: UIApplicationDelegate {
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        if UIApplication.shared.applicationState == .background {
            appLaunchingIntoBackground = true
            print("HSApplication -- appLaunchingIntoBackground")
        }

        //        print("document: %@", HSUtils.documentDirectoryPath())
        do {
            try initializeLaunchInfo()
        } catch LEError.RuntimeError(let errorMessage) {
            print(errorMessage)
            return false
        } catch {
            return false
        }

        //        HSGDPRConsent.sharedInstance()
        //        HSAnalytics.sharedInstance().start(withOptions: launchOptions)

        onApplicationStart()
        
        LEDiverseSession.shared

        //        HSAppsFlyerPublisher.sharedInstance()

        // 注意和 kHSNotificationName_SessionDidStart 通知相关模块初始化在 startSession 前的问题
        LESessionManager.shared.startSession()

        //        HSPushManager.sharedInstance()

        //        HSSystem.current()
        //
        //        HSSearchAds.requestAttributionDetails()

        return true
    }

    public func applicationWillEnterForeground(_ application: UIApplication) {
        if appLaunchingIntoBackground == false {
            LESessionManager.shared.startSession()
        }

        appLaunchingIntoBackground = false
    }

    public func applicationDidEnterBackground(_ application: UIApplication) {
        LESessionManager.shared.endSession()
    }

    public func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return true
    }

    public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        //        HSPushManager.sharedInstance().sendDeviceToken(deviceToken)
        //        HSAppsFlyerPublisher.sharedInstance().registerUninstall(deviceToken)
    }

}
