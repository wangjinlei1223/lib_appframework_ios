//
//  HSDiverseSession.swift
//  HSAppFramework
//
//  Created by long.liu on 2019/10/15.
//  Copyright © 2019年 iHandySoft Inc. All rights reserved.
//

import Foundation

let HSDiverseSession_Notification_SessionStart = Notification.Name("HSDiverseSession_Notification_SessionStart");
let HSDiverseSession_Notification_SessionEnd = Notification.Name("HSDiverseSession_Notification_SessionEnd");

public class HSDiverseSession {
    private var startCount: Int = 0
    private var endCount: Int = 0

    static let shared = HSDiverseSession()

    private init() {
        // 如果配为true，代表由app接管，false由Appframework接管
        if !HSDiverseSession.isAppManageDiverseSession() {
            print("AppManageDiverseSession == false, DiverseSession is triggered by Appframework");
#if !TARGET_IS_EXTENSION
            NotificationCenter.default.addObserver(self, selector: #selector(handleSessionDidStart(_:)), name: kHSNotificationName_SessionDidStart, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(handleSessionDidEnd(_:)), name: kHSNotificationName_SessionDidEnd, object: nil)
#endif
        }else{
            print("AppManageDiverseSession == true, DiverseSession is triggered by app");
        }

        startCount = 0;
        endCount = 0;
    }

#if !TARGET_IS_EXTENSION
    @objc func handleSessionDidStart(_ notification: Notification) {
        sendStart();
    }
    @objc func handleSessionDidEnd(_ notification: Notification) {
        sendEnd();
    }
#endif

    func start() {
        print("Start Begin: startCount: %d, endCount:%d", startCount, endCount);

        if !HSDiverseSession.isAppManageDiverseSession() {

            print("AppManageDiverseSession == false, DiverseSession is triggered by Appframework, could not send start");
#if DEBUG
            NotificationCenter.default.post(name: NSNotification.Name("HSDiverseSession_Notification_SessionStartFailed"), object: nil, userInfo: ["errorMessage": "AppManageDiverseSession == false, DiverseSession is triggered by Appframework, could not send start"])
#endif

            return;
        }

        if (startCount > endCount) {
            sendEnd();
        }

        sendStart();
    }

    func sendStart() {
        NotificationCenter.default.post(name: HSDiverseSession_Notification_SessionStart, object: nil)

        startCount += 1

        print("Start Finish: startCount: %d, endCount:%d", startCount, endCount);
    }

    func end() {
        print("End Begin: startCount: %d, endCount:%d", startCount, endCount);

        if !HSDiverseSession.isAppManageDiverseSession() {
            print("AppManageDiverseSession == false, DiverseSession is triggered by Appframework, could not send end");

#if DEBUG
            NotificationCenter.default.post(name: NSNotification.Name("HSDiverseSession_Notification_SessionEndFailed"), object: nil, userInfo: ["errorMessage": "AppManageDiverseSession == false, DiverseSession is triggered by Appframework, could not send end"])
#endif

            return;
        }

        if (endCount >= startCount) {
            print("startcount <= endcount, could not send end");

#if DEBUG
            NotificationCenter.default.post(name: NSNotification.Name("HSDiverseSession_Notification_SessionEndFailed"), object: nil, userInfo: ["errorMessage": "startcount <= endcount, could not send end, end can only be sent after start"])
#endif

            return;
        }

        sendEnd();
    }

    func sendEnd() {
        NotificationCenter.default.post(name: HSDiverseSession_Notification_SessionEnd, object: nil)

        endCount += 1

        print("End Finish: startCount: %d, endCount:%d", startCount, endCount);
    }

    //todo HSConfig
    class func isAppManageDiverseSession() -> Bool {
//        let obj = [[HSConfig sharedInstance].data valueForKeyPath:@"libCommons.DiverseSession.AppManageDiverseSession"];
//
//        print("isAppManageDiverseSession: %@",obj)

        return true
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    //todo Log定义
    /// 自定义Log打印
    ///
    /// - Description:
    ///     考虑到自定义Log要打印方法所在的文件/方法名/行号，以及自定义的内容，同时考虑调用的便捷性，所以要使用默认参数（fileName: String = #file），因此无需调用者传递太多的参数。
    ///     T 使用泛型，可以让调用者传递任意的类型，进行打印Log的操作。
    /// - Parameters:
    ///   - message: 需要打印的内容
    ///   - fileName: 当前打印所在文件名 使用#file获取
    ///   - funcName: 当前打印所在方法名 使用#function获取
    ///   - lineNum: 当前打印所在行号   使用#line获取
    func HSLog<T> (message: T, fileName: String = #file, funcName: String = #function, lineNum: Int = #line) {
#if DEBUG
        let file = (fileName as NSString).lastPathComponent
        print("-\(file) \(funcName)-[\(lineNum)]: \(message)")
#endif

    }
}
