//
//  HSLocalConfig.swift
//  HSAppFramework
//
//  Created by JackSparrow on 2019/10/21.
//  Copyright © 2019 iHandySoft Inc. All rights reserved.
//

import Foundation
import UIKit


@objc class HSLocalConfig : NSObject  {
    @objc static let instance = HSLocalConfig()
    @objc var data : NSDictionary? = nil
    
    private override init() {}
    
    private func decryptData(data: Data?) -> Data? {
        var key = [CUnsignedChar](repeating: 0, count: 24)
        key[0] = 0x4c
        key[1] = 0x53
        key[2] = 0x46
        key[3] = 0x36
        key[4] = 0x4d
        key[5] = 0x55
        key[6] = 0x59
        key[7] = 0x71
        key[8] = 0x52
        key[9] = 0x69
        key[10] = 0x52
        key[11] = 0x44
        key[12] = 0x4a
        key[13] = 0x44
        key[14] = 0x52
        key[15] = 0x69
        key[16] = 0x57
        key[17] = 0x7a
        key[18] = 0x4d
        key[19] = 0x6c
        key[20] = 0x4a
        key[21] = 0x41
        key[22] = 0x3d
        key[23] = 0x3d

        let decodeData = NSData(base64Encoded: NSString(bytes: key, length: 24, encoding: String.Encoding.utf8.rawValue)! as String, options: NSData.Base64DecodingOptions.init())
        let decodeKey = NSString.init(data: decodeData! as Data, encoding: String.Encoding.utf8.rawValue)
        let decryptedData = HSAESUtils.aes256DecryptData(data, withKey: decodeKey as String?)
        return decryptedData
    }
    
    @objc func configure(withYamlFileName yamlFileName: String?) {
        data = loadLocalConfig(withYamlFile: yamlFileName) as NSDictionary?
    }
    
    func loadLocalConfig(withYamlFile file: String?) -> [AnyHashable : Any]? {
        //    file = @"bundle://U5GamesResource/AccountConfig.ya";
        let fileURL = URL(string: file ?? "")
        var bundleFileName: String? = nil
        if fileURL?.scheme?.caseInsensitiveCompare("bundle") == .orderedSame {
            bundleFileName = fileURL?.host
        }
        let filePath = (bundleFileName == nil ? Bundle.main : Bundle(path: Bundle.main.path(forResource: bundleFileName, ofType: "bundle") ?? ""))?.path(forResource: fileURL?.path, ofType: nil)
        let rawData = NSData(contentsOfFile: filePath ?? "")
        let decryptedData = decryptData(data: rawData as Data?)
        
        var jsonObject: Any? = nil
        do {
            jsonObject = try JSONSerialization.jsonObject(with: decryptedData!, options: [JSONSerialization.ReadingOptions.init(rawValue: 0)])
        } catch {
        }
        return jsonObject as? [AnyHashable : Any]
    }
}
