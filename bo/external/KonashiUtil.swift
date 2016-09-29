//
//  KonashiUtil.swift
//  bo
//
//  Created by 古川信行 on 2016/08/01.
//  Copyright © 2016年 tf-web. All rights reserved.
//

import Foundation
import konashi_ios_sdk

class KonashiUtil{
    //シングルトン インスタンス作成
    class var sharedInstance : KonashiUtil {
        struct Static {
            static let instance : KonashiUtil = KonashiUtil()
        }
        return Static.instance
    }
        
    //デバイス シリアルコード
    var serialCode:String?

    //ボタンの値変化の通知
    var didUpdateNotification:((pin:KonashiDigitalIOPin, value:Int32)->Void)?

    private init(){

    }
    
    //初期化
    func initialize(connected:()->Void,disconnected:()->Void,ready:()->Void){
        //デバイスと接続された時
        Konashi.shared().connectedHandler = {() -> Void in
            //print("connected")
            connected()
        }
        
        //デバイスから切断された時
        Konashi.shared().disconnectedHandler = {() -> Void in
            //print("disconnected")
            disconnected()
        }
        
        //デジタル インプットに設定したピンに変化があった場合の処理
        Konashi.shared().digitalInputDidChangeValueHandler = {[weak self](pin, value) -> Void in
            //print("digitalInputDidChangeValueHandler")
            //print(" pin:\(pin) value::\(value)")
            if let weakSelf = self {
                if let callback = weakSelf.didUpdateNotification{
                    callback(pin: pin, value:value)
                }
            }
        }

        //使用可能状態になった時
        Konashi.shared().readyHandler = {() -> Void in
            //print("ready")
            ready()
            //ボタンをインプットモードに設定
            Konashi.pinMode(KonashiDigitalIOPin.DigitalIO0,mode:.Input)
            Konashi.pinPullup(.DigitalIO0, mode:.Pullup)
        }
    }
    
    //デバイス シリアルコードを設定
    func setSerialCode(serialCode:String){
        self.serialCode = serialCode
    }
    
    //デバイス シリアルコードを取得
    func getSerialCode()->String? {
        return self.serialCode
    }
    
    //デバイス検索
    func find(){
        //リアルコードが設定済みなら それを指定して検索&接続
        if let serialCode = self.serialCode {
            self.find(serialCode)
        }
    }
    
    //デバイス検索
    func find(serialCode:String){
        setSerialCode(serialCode)
        let name = "konashi2-f0\(serialCode)"
        Konashi.findWithName(name)
    }

    //デジタル インプットに設定したピンに変化があった場合の処理
    func setUpdateNotification(callback:(pin:KonashiDigitalIOPin, value:Int32)->Void){
        self.didUpdateNotification = callback
    }
    
    //接続状態を確認する
    func isConnected() -> Bool{
        return Konashi.isConnected()
    }
}