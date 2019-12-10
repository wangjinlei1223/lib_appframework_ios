//
//  SearchAds.swift
//  HSAppFramework
//
//  Created by kai.sun on 2019/10/22.
//  Copyright © 2019 iHandySoft Inc. All rights reserved.
//

import UIKit
import iAd

let kUserDefaultsKey_SearchAdsAttributionDetails = "kUserDefaultsKey_SearchAdsAttributionDetails";
let kUserDefaultsKey_SearchAdsAttributionDetailsFetched = "kUserDefaultsKey_SearchAdsAttributionDetailsFetched"

class SearchAds: NSObject {
    func getIadKeyword() -> String? {
        guard let dict = UserDefaults.standard.object(forKey: kUserDefaultsKey_SearchAdsAttributionDetails) as? [String : Any] else {
            return nil
        }
        return dict["iad-keyword"] as? String
    }

    func getAttributionDetails() -> [AnyHashable : Any]? {
        return UserDefaults.standard.object(forKey: kUserDefaultsKey_SearchAdsAttributionDetails) as? [AnyHashable : Any]
    }
    
    func requestAttributionDetails() {
        if UserDefaults.standard.bool(forKey: kUserDefaultsKey_SearchAdsAttributionDetailsFetched) {
            return
        }
        
        if #available(iOS 9.0, *) {
            ADClient.shared().requestAttributionDetails { (attributeDictionary : [String : NSObject]?, error : Error?) in
                if error == nil && attributeDictionary != nil {
                    self.attributionDetailsProcessing(attributionDetails: attributeDictionary!)
                }
            }
        }
    }
    
    private func attributionDetailsProcessing(attributionDetails : [String : NSObject]) {
        var detailValueDictionary : [AnyHashable : Any]?
        for value in attributionDetails.values {
            if value is [AnyHashable : Any] {
                let temp = (value as? [AnyHashable : Any])?["iad-click-date"]
                if temp is String {
                    detailValueDictionary = value as? [AnyHashable : Any]
                    break
                }
            }
        }
        
        if detailValueDictionary == nil {
            return
        }
        
        var logDetails = [String : Any]()
        let needKeys = ["iad-click-date", "iad-campaign-id", "iad-adgroup-id", "iad-campaign-name", "iad-keyword"]
        for key in needKeys {
            let itemValue = detailValueDictionary![key]
            if itemValue != nil {
                logDetails[key] = itemValue
            }
        }
        
        HSAnalytics.sharedInstance.logEvent("HSSearchAds_AttributionDetails", withParameters: logDetails)
        UserDefaults.standard.set(detailValueDictionary, forKey: kUserDefaultsKey_SearchAdsAttributionDetails)
        UserDefaults.standard.set(true, forKey: kUserDefaultsKey_SearchAdsAttributionDetailsFetched)
        UserDefaults.standard.synchronize()
    }
}
