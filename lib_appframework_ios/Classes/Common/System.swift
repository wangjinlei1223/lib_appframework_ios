//
//  System.swift
//  HSAppFramework
//
//  Created by kai.sun on 2019/10/23.
//  Copyright © 2019 iHandySoft Inc. All rights reserved.
//

import UIKit
import AVFoundation
import MessageUI

enum BlockCheckType {
    case Facebook
    case Google
}

class System: NSObject {
    let isMultitaskingSupported : Bool = {
        let device : UIDevice = UIDevice.current
        return device.isMultitaskingSupported
    }()
    
    let isCameraFlashAvailable : Bool = {
        if (NSClassFromString("AVCaptureDevice") != nil) {
            return AVCaptureDevice.default(for: AVMediaType.video)?.hasFlash ?? false
        }
        return false
    }()
    
    let isSmsSupported : Bool = {
        var smsSupportedSymbol : Bool = false
        let device : UIDevice = UIDevice.current
        let smsClass : AnyClass? = NSClassFromString("MFMessageComposeViewController")
        if smsClass != nil {
            smsSupportedSymbol = MFMessageComposeViewController.canSendText()
        } else {
            smsSupportedSymbol = device.model == "iPhone"
        }
        return smsSupportedSymbol
    }()
    
    let isHighResolutionSupported : Bool = {
        let scale : CGFloat = UIScreen.main.scale
        return scale > 1.0
    }()
    
    let isJailBroken : Bool = {
        var jailBrokeSymbol : Bool = false
    #if targetEnvironment(simulator)
        jailBrokeSymbol = false
    #else
        let jailBreakApps : [String] = ["/Applications/Cydia.app",
                                        "/Applications/limera1n.app",
                                        "/Applications/greenpois0n.app",
                                        "/Applications/blackra1n.app",
                                        "/Applications/blacksn0w.app",
                                        "/Applications/redsn0w.app",
                                        "/Applications/Installous.app",
                                        "/Applications/iFile.app",
                                        "/Applications/IAPFree.app",
                                        "/Library/MobileSubstrate/MobileSubstrate.dylib",
                                        "/var/cache/apt",
                                        "/var/lib/apt",
                                        "/var/lib/cydia",
                                        "/var/tmp/cydia.log",
                                        "/bin/bash",
                                        "/bin/sh",
                                        "/usr/sbin/sshd",
                                        "/usr/libexec/ssh-keysign",
                                        "/etc/ssh/sshd_config",
                                        "/etc/apt"]
        for appPath in jailBreakApps {
            if (currentSystem.isBreakFileExist(file: appPath)) {
                jailBrokeSymbol = true
            }
        }
        
        if jailBrokeSymbol == false && currentSystem.sandbox_integrity_compromised() == 1 {
            jailBrokeSymbol = true
        }
        
        if jailBrokeSymbol == false {
            let symlinkFolders : [String] = ["/Applications",
                                            "/Library/Ringtones",
                                            "/Library/Wallpaper",
                                            "/usr/arm-apple-darwin9",
                                            "/usr/include",
                                            "/usr/libexec",
                                            "/usr/share"]
            for item in symlinkFolders {
                var s: stat = stat()
                if lstat(item.cString(using: String.Encoding.utf8), &s) != 0 {
                    if s.st_mode == S_IFLNK {
                        jailBrokeSymbol = true
                        break
                    }
                }
            }
        }
    #endif
        return jailBrokeSymbol
    }()
    
    let isIapBroken : Bool = {
        var iapBrokeSymbol : Bool = false
    #if targetEnvironment(simulator)
        iapBrokeSymbol = false
    #else
        if currentSystem.isJailBroken {
            let iapFreeApps : [String] = ["/Applications/IAPFree.app"]
            
            for item in iapFreeApps {
                if currentSystem.isBreakFileExist(file: item) {
                    iapBrokeSymbol = true
                    break;
                }
            }
        }
    #endif
        return iapBrokeSymbol
    }()
    
    let isScreenTall : Bool = {
        let height : CGFloat = UIScreen.main.bounds.height > UIScreen.main.bounds.width ? UIScreen.main.bounds.height : UIScreen.main.bounds.width
        if height == 568 {
            return true
        }
        return false
    }()
    let userInterfaceIdiom : UIUserInterfaceIdiom = {
        return UI_USER_INTERFACE_IDIOM()
    }()
    let platform : String = {
        var size : size_t = size_t()
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.machine",&machine, &size, nil, 0)
        return String(cString: machine)
    }()
    
    let bundleSeedID : String? = {
        let query: [String : AnyObject] = [
            kSecClass as String : kSecClassGenericPassword,
            kSecAttrAccount as String : "bundleSeedID" as AnyObject,
            kSecAttrService as String : "" as AnyObject,
            kSecReturnAttributes as String : kCFBooleanTrue
        ]
        var result: AnyObject?
        var status = withUnsafeMutablePointer(to: &result) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }
        
        if status == errSecItemNotFound {
            status = withUnsafeMutablePointer(to: &result) {
                SecItemAdd(query as CFDictionary, UnsafeMutablePointer($0))
            }
        }
        
        if status == noErr {
            if let resultDict = result as? [String : Any], let accessGroup = resultDict[kSecAttrAccessGroup as String] as? String {
                let components = accessGroup.components(separatedBy: ".")
                return components.first
            }
        }
        return nil
    }()

    private(set) var isGoogleBlocked : Bool
    private(set) var isFacebookBlocked : Bool
    
    static let currentSystem = System()
    override init() {
        isFacebookBlocked = false
        isGoogleBlocked = false
        
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(checkWalls), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleDiverseSessionNotificationSessionStart), name: HSDiverseSession_Notification_SessionStart, object: nil)
    }
    
    func isBreakFileExist(file : String?) -> Bool {
        var s: stat = stat()
        return stat(file?.cString(using: String.Encoding.utf8), &s) == 0
    }
    
    func sandbox_integrity_compromised() -> Int {
        var pid : pid_t = -1
//        var status : Int32 = 0
//        posix_spawn(&pid, "", nil, nil, [], nil)
//        waitpid(pid, &status, WEXITED)
//        if pid >= 0 {
//            return true
//        }
        posix_spawn(&pid, "", nil, nil, [], nil)
        if pid == 0 {
            exit(0)
        }
        if pid >= 0 {
            return 1
        }
        return 0
    }
    
    let dispatchOnce : Any = {
        System.init().checkWalls()
    }()
    
    func startCheckingNetworkBlockStatus() {
        _ = dispatchOnce
    }
    
    @objc func handleDiverseSessionNotificationSessionStart() {
        self.startCheckingNetworkBlockStatus()
    }
    
    @objc func checkWalls() {
        DispatchQueue.global(qos: .default).async(execute: {
            self.isFacebookBlocked = self.checkWallBlockStatus(with: .Facebook)
            self.isGoogleBlocked = self.checkWallBlockStatus(with: .Google)
        })
    }
    
    func checkWallBlockStatus(with type: BlockCheckType) -> Bool {
        var result: Bool
        var hostRef: Unmanaged<CFHost>
        var addresses: [AnyHashable]? = nil
        let hostName = type == .Facebook ? "fbwallcheck.api-alliance.com" : "gwallcheck.api-alliance.com"
        hostRef = CFHostCreateWithName(kCFAllocatorDefault, hostName as CFString)
        result = CFHostStartInfoResolution(hostRef.takeRetainedValue(), CFHostInfoType.addresses, nil)
        if result == true {
            let boolPtr = UnsafeMutablePointer<DarwinBoolean>.allocate(capacity: 1)
            boolPtr.initialize(to: DarwinBoolean.init(result))
            addresses = CFHostGetAddressing(hostRef.takeRetainedValue(), boolPtr) as? [AnyHashable]
        }
        
        var blockStatus = false
        if result == true && addresses != nil {
            for i in 0...CFArrayGetCount(addresses as! CFArray) {
                var remoteAddr : sockaddr_in?
                let saData = CFArrayGetValueAtIndex(addresses as! CFArray, i) as! CFData
                remoteAddr = CFDataGetBytePtr(saData) as? sockaddr_in
                
                if remoteAddr != nil {
                    let strDNS = String(cString: inet_ntoa(remoteAddr!.sin_addr), encoding: .ascii)
//                    DebugLog("RESOLVED %d:<%@>", i, strDNS)
                    if ((strDNS as NSString?)?.range(of: "99.2").length ?? 0) > 0 {
                        blockStatus = true
                    }
                }
            }
        }
        hostRef.release()
        return blockStatus
    }
}
