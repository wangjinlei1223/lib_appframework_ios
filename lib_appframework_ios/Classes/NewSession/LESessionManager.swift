//
//  HSSessionManager.swift
//  HSAppFramework
//
//  Created by long.liu on 2019/10/14.
//  Copyright © 2019年 iHandySoft Inc. All rights reserved.
//

import Foundation

let kLENotificationName_SessionDidStart = NSNotification.Name("kLENotificationName_SessionDidStart")
let kLENotificationName_SessionDidEnd = NSNotification.Name("kLENotificationName_SessionDidEnd")

private let kLEUserDefaultsKey_FirstSessionStartTime = "kLEUserDefaultsKey_FirstSessionStartTime"
private let kLEUserDefaultsKey_LastSessionEndTime = "kLEUserDefaultsKey_LastSessionEndTime"
private let kLEUserDefaultsKey_TotalUsageSeconds = "kLEUserDefaultsKey_TotalUsageSeconds"
private let kLEUserDefaultsKey_TotalSessionCount = "kLEUserDefaultsKey_TotalSessionCount"

public final class LESessionManager {

    private static var sIsSessionManagerEnabled: Bool = true
    private var isSessionStarted: Bool = false
    private var currentSessionStartTime: Date?

    private (set) var isFirstSessionInCurrentLaunch: Bool
    private (set) var firstSessionStartTime: Date?
    private (set) var lastSessionEndTime: Date?
    private (set) var currentSessionID: Int
    private (set) var totalUsageSeconds: Double

    public static let shared = LESessionManager()

    private init() {

        isFirstSessionInCurrentLaunch = true;
        isSessionStarted = false;

        let defaults = UserDefaults.standard;
        firstSessionStartTime = defaults.object(forKey: kLEUserDefaultsKey_FirstSessionStartTime) as? Date;
        lastSessionEndTime = defaults.object(forKey: kLEUserDefaultsKey_LastSessionEndTime) as? Date;
        
        currentSessionID = defaults.integer(forKey: kLEUserDefaultsKey_TotalSessionCount);
        totalUsageSeconds = defaults.double(forKey: kLEUserDefaultsKey_TotalUsageSeconds);
    }
    
    class func disableSessionNotification() {
        sIsSessionManagerEnabled = false
    }

    func enableAndPostSessionNotificationIfNeeded() {
        if LESessionManager.sIsSessionManagerEnabled == false && isSessionStarted {
            NotificationCenter.default.post(name: kLENotificationName_SessionDidStart, object: nil)
        }
        LESessionManager.sIsSessionManagerEnabled = true
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
        defaults.set(currentSessionID, forKey: kLEUserDefaultsKey_TotalSessionCount)

        if firstSessionStartTime == nil {
            firstSessionStartTime = currentSessionStartTime
            defaults.set(firstSessionStartTime, forKey: kLEUserDefaultsKey_FirstSessionStartTime)
        } else {
            firstSessionStartTime = defaults.object(forKey: kLEUserDefaultsKey_FirstSessionStartTime) as? Date
        }
        defaults.synchronize()

        if LESessionManager.sIsSessionManagerEnabled {
            NotificationCenter.default.post(name: kLENotificationName_SessionDidStart, object: nil)
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
        defaults.set(totalUsageSeconds, forKey: kLEUserDefaultsKey_TotalUsageSeconds)
        defaults.set(lastSessionEndTime, forKey: kLEUserDefaultsKey_LastSessionEndTime)
        defaults.synchronize()

        isSessionStarted = false

        if LESessionManager.sIsSessionManagerEnabled {
            NotificationCenter.default.post(name: kLENotificationName_SessionDidEnd, object: nil)
        }

        isFirstSessionInCurrentLaunch = false

        //todo Analytics
//        [[HSAnalytics sharedInstance] logAppClosedWithUserInfo:nil];
    }
}
