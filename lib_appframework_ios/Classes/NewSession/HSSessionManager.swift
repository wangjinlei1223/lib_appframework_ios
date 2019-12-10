//
//  HSSessionManager.swift
//  HSAppFramework
//
//  Created by long.liu on 2019/10/14.
//  Copyright © 2019年 iHandySoft Inc. All rights reserved.
//

import Foundation


let kHSNotificationName_SessionDidStart = NSNotification.Name("kHSNotificationName_SessionDidStart")
let kHSNotificationName_SessionDidEnd = NSNotification.Name("kHSNotificationName_SessionDidEnd")

private let kHSUserDefaultsKey_FirstSessionStartTime = "kHSUserDefaultsKey_FirstSessionStartTime"
private let kHSUserDefaultsKey_LastSessionEndTime = "kHSUserDefaultsKey_LastSessionEndTime"
private let kHSUserDefaultsKey_TotalUsageSeconds = "kHSUserDefaultsKey_TotalUsageSeconds"
private let kHSUserDefaultsKey_TotalSessionCount = "kHSUserDefaultsKey_TotalSessionCount"

public final class HSSessionManager {

    private static var sIsSessionManagerEnabled: Bool = true
    private var isSessionStarted: Bool = false
    private var currentSessionStartTime: Date?

    private (set) var isFirstSessionInCurrentLaunch: Bool
    private (set) var firstSessionStartTime: Date?
    private (set) var lastSessionEndTime: Date?
    private (set) var currentSessionID: Int
    private (set) var totalUsageSeconds: Double

    public static let shared = HSSessionManager()

    private init() {

        isFirstSessionInCurrentLaunch = true;
        isSessionStarted = false;

        let defaults = UserDefaults.standard;
        firstSessionStartTime = defaults.object(forKey: kHSUserDefaultsKey_FirstSessionStartTime) as? Date;
        lastSessionEndTime = defaults.object(forKey: kHSUserDefaultsKey_LastSessionEndTime) as? Date;
        
        currentSessionID = defaults.integer(forKey: kHSUserDefaultsKey_TotalSessionCount);
        totalUsageSeconds = defaults.double(forKey: kHSUserDefaultsKey_TotalUsageSeconds);
    }
    
    class func disableSessionNotification() {
        sIsSessionManagerEnabled = false
    }

    func enableAndPostSessionNotificationIfNeeded() {
        if HSSessionManager.sIsSessionManagerEnabled == false && isSessionStarted {
            NotificationCenter.default.post(name: kHSNotificationName_SessionDidStart, object: nil)
        }
        HSSessionManager.sIsSessionManagerEnabled = true
    }

    func startSession() {

        if isSessionStarted {
            print("======== Duplicated Session Start ")
            return
        }

        isSessionStarted = true
        currentSessionStartTime = Date()
        currentSessionID += 1

        let defaults = UserDefaults.standard
        defaults.set(currentSessionID, forKey: kHSUserDefaultsKey_TotalSessionCount)

        if firstSessionStartTime == nil {
            firstSessionStartTime = currentSessionStartTime
            defaults.set(firstSessionStartTime, forKey: kHSUserDefaultsKey_FirstSessionStartTime)
        } else {
            firstSessionStartTime = defaults.object(forKey: kHSUserDefaultsKey_FirstSessionStartTime) as? Date
        }
        defaults.synchronize()

        if HSSessionManager.sIsSessionManagerEnabled {
            NotificationCenter.default.post(name: kHSNotificationName_SessionDidStart, object: nil)
        }

        //todo Analytics
//        [[HSAnalytics sharedInstance] logAppOpenedWithUserInfo:nil];
        //todo AppsFlyer
//        [HSAppsFlyerLogEventUtils logActiveAppsFlyerEvent];
    }

    func endSession() {

        if !isSessionStarted {
            print("======== Duplicated Session End ")
            return
        }

        lastSessionEndTime = Date()
        totalUsageSeconds += lastSessionEndTime?.timeIntervalSince(currentSessionStartTime ?? Date()) ?? 0

        let defaults = UserDefaults.standard;
        defaults.set(totalUsageSeconds, forKey: kHSUserDefaultsKey_TotalUsageSeconds)
        defaults.set(lastSessionEndTime, forKey: kHSUserDefaultsKey_LastSessionEndTime)
        defaults.synchronize()

        isSessionStarted = false

        if HSSessionManager.sIsSessionManagerEnabled {
            NotificationCenter.default.post(name: kHSNotificationName_SessionDidEnd, object: nil)
        }

        isFirstSessionInCurrentLaunch = false

        //todo Analytics
//        [[HSAnalytics sharedInstance] logAppClosedWithUserInfo:nil];
    }
}
