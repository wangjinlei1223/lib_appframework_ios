//
//  ViewController.swift
//  lib_appframework_ios
//
//  Created by wangjinlei1223 on 12/09/2019.
//  Copyright (c) 2019 wangjinlei1223. All rights reserved.
//

import UIKit

import lib_appframework_ios
import MMKV

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        HSIAPManage.sharedInstance.requestProducts(productsID: [""]) { (_, _, _) in
            
        }
        
//        HSDiverseSession.s
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

