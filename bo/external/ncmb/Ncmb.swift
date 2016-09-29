//
//  Ncmb.swift
//  bo
//
//  Created by 古川信行 on 2016/07/29.
//  Copyright © 2016年 tf-web. All rights reserved.
//

import Foundation
import NCMB

class Ncmb{
    //シングルトン インスタンス作成
    class var sharedInstance : Ncmb {
        struct Static {
            static let instance : Ncmb = Ncmb()
        }
        return Static.instance
    }
    
    //コンストラクタ
    private init(){
    
    }
    
    //初期化
    func initialize(){
        //NCMB 初期化
        let ncmb = NSBundle.mainBundle().infoDictionary?["NCMB"]
        let appKey:String = ncmb!["appKey"] as! String
        let clientKey:String = ncmb!["clientKey"] as! String
        NCMB.setApplicationKey(appKey, clientKey: clientKey)
        
        //NCMBTwitterUtils 初期化
        let twitter = NSBundle.mainBundle().infoDictionary?["Twitter"]
        let consumerKey = twitter!["consumerKey"] as! String
        let consumerSecret = twitter!["consumerSecret"] as! String        
        NCMBTwitterUtils.initializeWithConsumerKey(consumerKey,consumerSecret:consumerSecret)
    }
    
    //DB書き込みテスト等
    func dbTest() {
        let query: NCMBQuery = NCMBQuery(className: "TestClass")
        query.whereKey("message", equalTo: "Hello, NCMB!")
        query.findObjectsInBackgroundWithBlock({(objects,error) in
            
            if error == nil {
                
                if objects.count > 0 {
                    let msg: AnyObject? = objects[0].objectForKey("message")
                    let msgStr: String = msg as! String
                    print("success find data. \(msgStr)")
                } else {
                    var saveError : NSError? = nil
                    let obj : NCMBObject = NCMBObject(className: "TestClass")
                    obj.setObject("Hello, NCMB!", forKey: "message")
                    obj.save(&saveError)
                    
                    if saveError == nil {
                        print("success save data.")
                    } else {
                        print("failure save data. \(saveError)")
                    }
                }
                
            } else {
                print(error.localizedDescription)
            }
        })
    }
    
    //Twitterログイン処理
    func loginTwitter(callback:BOTWRLogInCallback){
        NCMBTwitterUtils.logInWithBlock({(user,error) in
            callback(user,error)
        })        
    }
    
    //詳細 追加
    func saveDetail(detail:Detail,callback:(object:AnyObject?,error:NSError?)->Void) {
        if detail.getObjectId() == "" {
            //新規
            var error : NSError? = nil
            let obj : NCMBObject = NCMBObject(className: "DetailClass")
            obj.setObject(detail.getSerialCode(), forKey: "serialCode")
            obj.setObject(detail.getTitle(), forKey: "title")
            obj.setObject(detail.getBody(), forKey: "body")
            if let url = detail.getImageUrl() {
                obj.setObject(url, forKey: "imageUrl")
            }
            if let location = detail.getLocation() {
                let point:NCMBGeoPoint = NCMBGeoPoint(latitude: location["latitude"]!,longitude:location["longitude"]!)
                obj.setObject(point, forKey: "location")
            }
            obj.save(&error)
            callback(object:obj,error: error)
        }
        else{
            //更新
            let query: NCMBQuery = NCMBQuery(className: "DetailClass")
            query.whereKey("objectId", equalTo: detail.getObjectId())
            query.findObjectsInBackgroundWithBlock({(objects,error) in
                
                if error == nil {
                    if objects.count > 0 {
                        //更新
                        var error : NSError? = nil
                        let obj : NCMBObject = objects[0] as! NCMBObject
                        obj.setObject(detail.getSerialCode(), forKey: "serialCode")
                        obj.setObject(detail.getTitle(), forKey: "title")
                        obj.setObject(detail.getBody(), forKey: "body")
                        if let url = detail.getImageUrl() {
                            obj.setObject(url, forKey: "imageUrl")
                        }
                        if let location = detail.getLocation() {
                            let point:NCMBGeoPoint = NCMBGeoPoint(latitude: location["latitude"]!,longitude:location["longitude"]!)
                            obj.setObject(point, forKey: "location")
                        }
                        obj.save(&error)
                        callback(object:obj,error: error)
                    }
                    else {
                        //新規追加
                        var error : NSError? = nil
                        let obj : NCMBObject = NCMBObject(className: "DetailClass")
                        obj.setObject(detail.getSerialCode(), forKey: "serialCode")
                        obj.setObject(detail.getTitle(), forKey: "title")
                        obj.setObject(detail.getBody(), forKey: "body")
                        if let url = detail.getImageUrl() {
                            obj.setObject(url, forKey: "imageUrl")
                        }
                        if let location = detail.getLocation() {
                            let point:NCMBGeoPoint = NCMBGeoPoint(latitude: location["latitude"]!,longitude:location["longitude"]!)
                            obj.setObject(point, forKey: "location")
                        }
                        obj.save(&error)
                        callback(object:obj,error: error)
                    }
                    
                } else {
                    //エラー時
                    callback(object:nil,error: error)
                }
            })
        }
    }

    //詳細一覧を取得する
    func getDetails(detail:Detail?,km:Double?,limit:Int32?,callback:(objects:[AnyObject]?,error:NSError?)->Void){
        let query: NCMBQuery = NCMBQuery(className: "DetailClass")
        
        if let detail = detail {
            if let objectId = detail.getObjectId() {
                query.whereKey("objectId", equalTo: objectId)
            }
        
            if let location = detail.getLocation() {
                //検索 範囲 [km]
                if km != nil {
                    let point:NCMBGeoPoint = NCMBGeoPoint(latitude: location["latitude"]!,longitude:location["longitude"]!)
                    query.whereKey("location", nearGeoPoint: point, withinKilometers:km!)
                }
                else{
                    //範囲指定がなかった場合エラー
                    let error : NSError = NSError(domain: "km is null", code: -1, userInfo: nil)
                    callback(objects:nil,error: error)
                    return
                }
            }
        }
        if let limit = limit{
            query.limit = limit
        }
        
        //並べ替え
        query.orderByDescending("createDate")
        
        query.findObjectsInBackgroundWithBlock({(objects,error) in
            if error == nil {
                callback(objects:objects,error: nil)
            }
            else{
                //エラー時
                callback(objects:nil,error: error)
            }
        })
    }
}
