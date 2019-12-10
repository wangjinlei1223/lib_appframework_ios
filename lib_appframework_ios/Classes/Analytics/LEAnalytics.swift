//
//  LEAnalytics.swift
//  HSAppFramework
//
//  Created by ying on 2019/10/17.
//  Copyright © 2019 iHandySoft Inc. All rights reserved.
//

import Foundation
import Flurry_iOS_SDK
import FBSDKCoreKit
import AppsFlyerLib

private var currentVersion = 0

func FLURRY_ENABLED() -> Bool {
    return GDPRAssent.shareInstance.isGDPRAccepted()
}

func APPSFLYER_ENABLED() -> Bool {
    return GDPRAssent.shareInstance.isGDPRAccepted()
}

public class LEAnalytics : NSObject {
    private var facebookAppID: String?
    private var purchaseContentID: String?
    private var registration: String?
    private var spentCredits: String?
    private var analyticsCount = 0
    
    public static let sharedInstance = LEAnalytics();
    
    private override init() {
        super.init()
        analyticsCount = 0
    }
    
    func initFlurry(withOptions options: [AnyHashable : Any]?) {
        if Flurry.activeSessionExists() {
            return
        }
        
        let analyticsConfig = LELocalConfig.instance.data?["libCommons.Analytics"] as? [AnyHashable : Any]
        let appIsNotMultitask = Bundle.main.object(forInfoDictionaryKey: "UIApplicationExitsOnSuspend")
        if (appIsNotMultitask as? NSNumber)?.boolValue ?? false {
            Flurry.setSessionReportsOnCloseEnabled(false)
        }
        let flurryKey = analyticsConfig?["FlurryKey"] as? String
        log("\n================================================\n[HSAnalytics Start Session with Flurry_Key]: \(flurryKey ?? "")\n================================================")
        var isBGSessionEnabled = false
        let backgroundModes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [AnyHashable]
        for mode in ["remote-notification", "voip", "audio", "fetch", "location"] {
            if backgroundModes?.contains(mode) ?? false {
                isBGSessionEnabled = true
                break
            }
        }
        let builder = FlurrySessionBuilder().withCrashReporting(true)
        builder?.withIncludeBackgroundSessions(inMetrics: isBGSessionEnabled)
        Flurry.startSession(flurryKey ?? "", withOptions: options, with: builder)
        if System.currentSystem.isMultitaskingSupported {
            NotificationCenter.default.addObserver(self, selector: #selector(resetAnalyticsCount), name: kLENotificationName_SessionDidStart, object: nil)
            if isBGSessionEnabled {
                NotificationCenter.default.addObserver(self, selector: #selector(pauseFlurryBackgroundSession), name: kLENotificationName_SessionDidEnd, object: nil)
            }
        }
    }
    
    @objc public func logAppOpened(withUserInfo userInfo: [AnyHashable : Any]?) {
        var parameters: [AnyHashable : Any] = [:]
        
        var useCount: String? = nil
        let count = LESessionManager.shared.currentSessionID
        if count < 5 {
            useCount = "0-4"
        } else if count >= 5 && count < 10 {
            useCount = "5-9"
        } else if count >= 10 && count < 50 {
            useCount = "10-49"
        } else if count >= 50 && count < 100 {
            useCount = "50-99"
        } else {
            useCount = "100+"
        }
        parameters["UsageCount"] = useCount
        
        var useTime: String? = nil
        let time = LESessionManager.shared.totalUsageSeconds
        if time <= 300 {
            useTime = "0-5min"
        } else if time > 300 && time <= 600 {
            useTime = "5-10min"
        } else if time > 600 && time <= 1800 {
            useTime = "10-30min"
        } else if time > 1800 && time <= 3600 {
            useTime = "30-60min"
        } else {
            useTime = "1hour+"
        }
        
        parameters["UsageTime"] = useTime
        parameters["FirmwareVersion"] = LEVersionControl.osVersion()
        parameters["DevicePlatform"] = System.currentSystem.platform
        
        if userInfo != nil {
            for (k, v) in userInfo! { parameters[k] = v }
        }
        logEvent("App_Opened", withParameters: parameters)
    }

    @objc public func logAppClosed(withUserInfo userInfo: [AnyHashable : Any]?) {
        logEvent("App_Closed", withParameters: userInfo ?? [:])
    }
    
    // MARK: - Private Utils
    @objc func resetAnalyticsCount() {
        analyticsCount = 0
    }
    
    @objc func pauseFlurryBackgroundSession() {
        if !FLURRY_ENABLED() {
            return
        }
        Flurry.pauseBackgroundSession()
        log("pauseFlurryBackgroundSession")
    }

    func baseInfo() -> [AnyHashable : Any] {
        var baseInfo: [AnyHashable : Any] = [:]
        baseInfo["UserType"] = LEVersionControl.isFirstLaunchSinceInstallation() ? "NewUser" : "OldUser"
        return baseInfo
    }
    
    func log(_ format: String?, _ args: CVarArg...) {
        if LEApplication.isDebugEnabled() {
            let text = String(format: format ?? "", args)
            print("\(text)")
        }
    }

    @objc public func logEvent(_ info: String?) {
        logEvent(info ?? "", withParameters: [:])
    }
    
    @objc public func logEvent(_ info: String, withParameters parameters: [AnyHashable : Any]) {
        if !FLURRY_ENABLED() {
            return
        }
        analyticsCount += 1
        var dictParameter = baseInfo()
        for (k, v) in parameters { dictParameter[k] = v }
        Flurry.logEvent(info, withParameters: dictParameter)
        log("\n================================================\n[HSAnalytics Event-\(Int(analyticsCount))]:\(info) withParameters:\(dictParameter)\n================================================")
    }
    
    @objc public func startTimeEvent(_ info: String?) {
        startTimeEvent(info ?? "", withParameters: [:])
    }
    
    @objc public func startTimeEvent(_ info: String, withParameters parameters: [AnyHashable : Any]) {
        if !FLURRY_ENABLED() {
            return
        }
        analyticsCount += 1
        var dictParameter = baseInfo()
        for (k, v) in parameters { dictParameter[k] = v }
        Flurry.logEvent(info, withParameters: dictParameter, timed: true)
        log("\n================================================\n[HSAnalytics Event-\(analyticsCount)]:\(info) [startTimer] withParameters:\(dictParameter)\n================================================")
    }
    
    @objc public func endTimeEvent(_ info: String?) {
        endTimeEvent(info ?? "", withParameters: [:])
    }
    
    @objc public func endTimeEvent(_ info: String, withParameters parameters: [AnyHashable : Any]) {
        if !FLURRY_ENABLED() {
            return
        }
        analyticsCount += 1
        var dictParameter = baseInfo()
        for (k, v) in parameters { dictParameter[k] = v }
        Flurry.endTimedEvent(info, withParameters: dictParameter)
        log("\n================================================\n[HSAnalytics Event-\(analyticsCount)]:\(info) [endTimer] withParameters:\(dictParameter)\n================================================")
    }
    
    @objc public func logError(_ errorID: String, message: String, exception: NSException?) {
        if !FLURRY_ENABLED() {
            return
        }
        Flurry.logError(errorID, message: message, exception: exception)
        log("\n================================================\n[HSAnalytics Error]:\(errorID) message:\(message) \nexception:\(String(describing: exception)) \n================================================")
    }

    @objc public func logError(_ errorID: String, message: String, error: Error?) {
        if !FLURRY_ENABLED() {
            return
        }
        Flurry.logError(errorID, message: message, error: error)
        log("\n================================================\n[HSAnalytics Error]:\(errorID) message:\(message) \nerror:\(error as? String ?? "") \n================================================")
    }
    // MARK: -
    // MARK: App Open Report
    @objc func queryString(withParams paramDict: [AnyHashable : Any]?) -> String {
        if paramDict == nil || paramDict?.count == 0 {
            return ""
        }
        var parts: [String] = []
        for key in paramDict!.keys {
            var value: Any? = nil
            value = paramDict![key]
            
            // Encode string to a legal URL string.
            let encodedString = Utils.encodedStringForString(string: value as? String ?? "")
            let part = "\(key)=\(encodedString ?? "")"
            parts.append(part)
        }
        
        return parts.joined(separator: "&")
    }
    
    @objc func pingBackFacebook() {
        log("Trying to ping back Facebook")
        if facebookAppID?.count ?? 0 > 0 {
            log("start to ping back Facebook.")
            let fbSettings: AnyClass? = NSClassFromString("FBSDKSettings")
            let fbAppEvents: AnyClass? = NSClassFromString("FBSDKAppEvents")
            if fbSettings == nil || fbAppEvents == nil {
                print("Can not find Facebook SDK.")
                NSException(name: NSExceptionName("Can not find Facebook SDK."), reason: "Misssing Facebook SDK.", userInfo: nil).raise()
                return
            }
            //[FBSDKSettings setAppID:_facebookAppID];
            //#pragma clang diagnostic push
            //#pragma clang diagnostic ignored "-Wundeclared-selector"
            
            Settings.appID = facebookAppID
            AppEvents.activateApp()
            
//            DebugLog("Successfully pingBackFacebookWithAppID.App ID: %@", facebookAppID)
            //#pragma clang diagnostic pop
        }
    }
    
    // MARK: -
    // MARK: Analytics Methods For FACEBOOK
    @objc public func setFBEventNamePurchase(_ purchaseEventName: String, registration registrationEventName: String, spentCredits spentCreditsEventName: String?) {
        purchaseContentID = purchaseEventName
        registration = registrationEventName
        spentCredits = spentCreditsEventName
    }
    
    @objc public func logFBEvent(_ eventName: String) {
        let eventName = eventName
        if facebookAppID?.count ?? 0 > 0 {
            let fbAppEvents: AnyClass? = NSClassFromString("FBSDKAppEvents")
            if fbAppEvents == nil {
                print("Can not find Facebook SDK.")
                NSException(name: NSExceptionName("Can not find Facebook SDK."), reason: "Misssing Facebook SDK.", userInfo: nil).raise()
                return
            }
//            DebugLog("\n================================================\n[HSAnalyticsFACEBOOK Event]:%@\n================================================", eventName)
            //[FBSDKAppEvents logEvent:eventName];
            AppEvents.logEvent(AppEvents.Name(rawValue: eventName))
        }
    }

    @objc public func logFBEvent(_ eventName: String, valueToSum: Double) {
        let eventName = eventName
        let valueToSum = valueToSum
        if facebookAppID?.count ?? 0 > 0 {
            let fbAppEvents: AnyClass? = NSClassFromString("FBSDKAppEvents")
            if fbAppEvents == nil {
                print("Can not find Facebook SDK.")
                NSException(name: NSExceptionName("Can not find Facebook SDK."), reason: "Misssing Facebook SDK.", userInfo: nil).raise()
                return
            }
//            DebugLog("\n================================================\n[HSAnalyticsFACEBOOK Event]:%@ valueToSum:%f\n================================================", eventName, valueToSum)
            
            //[FBSDKAppEvents logEvent:eventName valueToSum:valueToSum];
            //#pragma clang diagnostic push
            //#pragma clang diagnostic ignored "-Wundeclared-selector"
            AppEvents.logEvent(AppEvents.Name(rawValue: eventName), valueToSum: valueToSum);
        }
    }
    
    @objc public func logFBEvent(_ eventName: String, parameters: [AnyHashable : Any]?) {
        let eventName = eventName
        let parameters = parameters
        if facebookAppID?.count ?? 0 > 0 {
            let fbAppEvents: AnyClass? = NSClassFromString("FBSDKAppEvents")
            if fbAppEvents == nil {
                print("Can not find Facebook SDK.")
                NSException(name: NSExceptionName("Can not find Facebook SDK."), reason: "Misssing Facebook SDK.", userInfo: nil).raise()
                return
            }
            log("\n================================================\n[HSAnalyticsFACEBOOK Event]:\(eventName) withParameters:\(parameters ?? [:])\n================================================")

            AppEvents.logEvent(AppEvents.Name(rawValue: eventName), parameters: parameters as? [String : Any] ?? [:])
        }
    }

    @objc public func logFBEvent(_ eventName: String, valueToSum: Double, parameters: [AnyHashable : Any]?) {
        let eventName = eventName
        let valueToSum = valueToSum
        let parameters = parameters
        if facebookAppID?.count ?? 0 > 0 {
            let fbAppEvents: AnyClass? = NSClassFromString("FBSDKAppEvents")
            if fbAppEvents == nil {
                print("Can not find Facebook SDK.")
                NSException(name: NSExceptionName("Can not find Facebook SDK."), reason: "Misssing Facebook SDK.", userInfo: nil).raise()
                return
            }
            log("\n================================================\n[HSAnalyticsFACEBOOK Event]:\(eventName) valueToSum:\(valueToSum) withParameters:\(parameters ?? [:])\n================================================")
            //[FBSDKAppEvents logEvent:eventName valueToSum:valueToSum parameters:parameters];
            //#pragma clang diagnostic push
            //#pragma clang diagnostic ignored "-Wundeclared-selector"
            AppEvents.logEvent(AppEvents.Name(rawValue: eventName), valueToSum: valueToSum)
        }
    }
    
    @objc public func logFBIAPUSDPurchaseEvent(_ productIdentifier: String, amount purchaseAmount: Double) {
        let purchaseAmount = purchaseAmount
        if facebookAppID?.count ?? 0 > 0 {
            let fbAppEvents: AnyClass? = NSClassFromString("FBSDKAppEvents")
            if fbAppEvents == nil {
                print("Can not find Facebook SDK.")
                NSException(name: NSExceptionName("Can not find Facebook SDK."), reason: "Misssing Facebook SDK.", userInfo: nil).raise()
                return
            }
            
            if (purchaseContentID?.count ?? 0 > 0) {
                log("\n================================================\n[HSAnalyticsFACEBOOK Event]:\(purchaseAmount) amount:%f identifier:\(productIdentifier)\n================================================", "IAPUSDPurchase")
                
                let currency = "USD";
                let para = [purchaseContentID!: productIdentifier];
                
                AppEvents.logPurchase(purchaseAmount, currency: currency, parameters: para)
            }
        }
    }

    @objc public func logFBLoginEvent(_ parameters: [AnyHashable : Any]?) {
        if registration?.count ?? 0 > 0 {
            logFBEvent(registration!, parameters: parameters ?? [:])
        }
    }
    
    @objc public func logFBSpentCreditsEvent(_ parameters: [AnyHashable : Any]?, credits: Double) {
        if spentCredits?.count ?? 0 > 0 {
            logFBEvent(spentCredits!, valueToSum: credits, parameters: parameters ?? [:])
        }
    }
    
    @objc public func logAppsFlyerEvent(_ eventName: String, values eventValues: [AnyHashable : Any]?) {
        if !APPSFLYER_ENABLED() {
            return
        }
        if eventName.count == 0 {
//            DebugLog("AppsFlyer Eventname is empty!")
            return
        }
        if eventValues?.count ?? 0 != 0 {
            (eventValues! as NSDictionary).enumerateKeysAndObjects({ key, obj, stop in
                let newEventName = "\(eventName)_\(key)_\(obj)"
                AppsFlyerTracker.shared().trackEvent(newEventName, withValues: eventValues)
//                DebugLog("AppsFlyer Eventname: %@", newEventName)
            })
        } else {
            AppsFlyerTracker.shared().trackEvent(eventName, withValues: eventValues)
        }
//        DebugLog("AppsFlyer record eventname: %@, values: %@", eventName, eventValues)
    }

    @objc public func setup(withOptions options: [AnyHashable : Any]?) {
        let analyticsConfig = LELocalConfig.instance.data?["libCommons.Analytics"] as? [AnyHashable : Any]
        if NSString(string: UIDevice.current.systemVersion).floatValue > 8 {
            if GDPRAssent.shareInstance.isGDPRAccepted() {
                initFlurry(withOptions: options)
            } else {
                NotificationCenter.default.addObserver(forName: LEGdprAssentDidChangeGrantNotification, object: nil, queue: nil, using: { note in
                    if GDPRAssent.shareInstance.isGDPRAccepted() {
                        self.initFlurry(withOptions: options)
                    }
                })
            }
        }
        facebookAppID = analyticsConfig?["FacebookID"] as? String
        NotificationCenter.default.addObserver(self, selector: #selector(pingBackFacebook), name: kLENotificationName_SessionDidStart, object: nil)
        let appID = analyticsConfig?["AppleAppID"] as? String
        log("\n================================================\n[HSAnalytics with Apple App ID:\(appID ?? "").\n================================================")
    }
}
