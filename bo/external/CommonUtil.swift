//
//  CommonUtil.swift
//  carekoma
//
//  Created by 古川信行 on 2016/05/07.
//  Copyright © 2016年 tf-web. All rights reserved.
//

import Foundation
import UIKit

class CommonUtil {
    
    private init(){
    }
    
    //block 内容をメインスレッドで実行する
    static func dispatch_async_main(block: () -> ()) {
        dispatch_async(dispatch_get_main_queue(), block)
    }
    
    //block 内容をバックグラウンドスレッドで実行する
    static func dispatch_async_global(block: () -> ()) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block)
    }
    
    //日付フォーマット指定して文字列を取得する
    static func dateToFormatString(format:String,date:NSDate,locale:String) -> String {
        let dateFormatter = NSDateFormatter()
        dateFormatter.locale = NSLocale(localeIdentifier: locale)
        dateFormatter.dateFormat = format
        return dateFormatter.stringFromDate(date)
    }
    
    //スリープ
    static func sleep(d:Double,callback:(()->Void)){
        let delay = d * Double(NSEC_PER_SEC)
        let time  = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(time, dispatch_get_main_queue(), {
            callback()
        })
    }
    
    //設定画面を開く
    static func openSettings(){
        let url = NSURL(string:UIApplicationOpenSettingsURLString)
        UIApplication.sharedApplication().openURL(url!)
    }
}