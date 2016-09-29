//
//  SharePopUpViewControllerSwift.swift
//  bo
//
//  Created by 古川信行 on 2016/09/28.
//  Copyright © 2016年 tf-web. All rights reserved.
//

import Foundation

import UIKit
import QuartzCore
import GoogleMaps
import NMPopUpViewSwift

public class SharePopUpViewControllerSwift : PopUpViewControllerSwift {
    //最後にGPS取得した位置
    var lastLocation: CLLocationCoordinate2D?
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: NSBundle!) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    //位置情報を設定
    public func setLastLocation(lastLocation: CLLocationCoordinate2D){
        self.lastLocation = lastLocation
    }
    
    /** シェアボタンタップ時
     *
     */
    @IBAction func clickShare(sender: AnyObject) {
        print("clickShare")
        
        //ここでサーバに乾杯を追加する
        let serialCode = BottleOpener.sharedInstance.getSerialCode()
        let detail = Detail(serialCode: BottleOpener.sharedInstance.getSerialCode()!,title: "title",body: "body")
        detail.setLocation(["latitude":self.lastLocation!.latitude,"longitude":self.lastLocation!.longitude])
        detail.setSerialCode(serialCode!)
        BottleOpener.sharedInstance.saveDetail(detail,callback:{ (object:AnyObject?,error:NSError?) in
            if let error = error {
                print("error:\(error)")
            }
            if let obj = object {
                let userDefaults = NSUserDefaults.standardUserDefaults()
                let auto_tweet = userDefaults.boolForKey("auto_tweet_preference")
                if auto_tweet == true {
                    //自動投稿か設定されていたら Twitterに投稿
                    BottleOpener.sharedInstance.sendTwitterRequest(obj)
                }
            }
        })
        
    }
}
