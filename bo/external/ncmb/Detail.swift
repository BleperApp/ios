//
//  Detail.swift
//  bo
//
//  Created by 古川信行 on 2016/08/01.
//  Copyright © 2016年 tf-web. All rights reserved.
//

import Foundation
import NCMB

/** 詳細データを格納する
 */
class Detail {
    private var objectId:String?
    private var serialCode:String?
    private var title:String?
    private var body:String?
    private var location:[String:Double]?
    private var imgUrl:String?
    
    internal init(){
    }
    
    internal init(serialCode:String,title:String,body:String){
        self.serialCode = serialCode
        self.title = title
        self.body = body
    }
    
    /*
    internal func parse(object:NCMBObject){
        self.objectId = object.objectId
        self.serialCode = object.objectForKey("serialCode") as? String
        self.title = object.objectForKey("title") as? String
        self.body = object.objectForKey("body") as? String
        self.imgUrl = object.objectForKey("imgUrl") as? String
        
        let loc:NCMBGeoPoint = object.objectForKey("location") as! NCMBGeoPoint
        self.location = ["latitude":loc.latitude,"longitude":loc.longitude]        
    }
    */
    
    internal func setSerialCode(serialCode:String){
        self.serialCode = serialCode
    }
    
    internal func getSerialCode() -> String?{
        return self.serialCode
    }
    
    internal func setObjectId(objectId:String){
        self.objectId = objectId
    }
    
    internal func getObjectId() -> String?{
        return self.objectId
    }
    
    internal func setTitle(title:String){
        self.title = title
    }
    
    internal func getTitle()->String?{
        return self.title
    }
    
    internal func setBody(body:String){
        self.body = body
    }
    
    internal func getBody()-> String?{
        return self.body
    }
    
    internal func setImageUrl(imgUrl:String){
        self.imgUrl = imgUrl
    }
    
    internal func getImageUrl()-> String?{
        return self.imgUrl
    }
    
    internal func setLocation(location:[String:Double]){
        self.location = location
    }
    
    internal func getLocation()-> [String:Double]?{
        return self.location
    }
}
