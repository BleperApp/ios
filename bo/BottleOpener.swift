//
//  BottleOpener.swift
//  bo
//
//  Created by 古川信行 on 2016/07/28.
//  Copyright © 2016年 tf-web. All rights reserved.
//

import Foundation
import Fabric
import TwitterKit
import GoogleMaps
import NMPopUpViewSwift
import NCMB
import SDWebImage
import konashi_ios_sdk

//メイン処理を実装するクラス
class BottleOpener {

    //シングルトン インスタンス作成
    class var sharedInstance : BottleOpener {
        struct Static {
            static let instance : BottleOpener = BottleOpener()
        }
        return Static.instance
    }
    
    static let DefaultButtonColor = UIButton(type: UIButtonType.System).titleColorForState(.Normal)!
    
    //再検索までの待ち時間
    let reFindSec:Double = 5.0
    
    //画面に追加したマーカー
    var markers:[GMSMarker]?
    
    //アプリ起動時の処理
    func appDidFinishLaunchingWithOptions(){
        initializeUserNotification()
        
        //Twitterライブラリを初期化
        let twitter = NSBundle.mainBundle().infoDictionary?["Twitter"]
        let consumerKey = twitter!["consumerKey"] as! String
        let consumerSecret = twitter!["consumerSecret"] as! String
        Twitter.sharedInstance().startWithConsumerKey(consumerKey, consumerSecret: consumerSecret)
        Fabric.with([Twitter.self()])
        
        //ニフティクラウド 初期化
        Ncmb.sharedInstance.initialize()
        
        //Google Mapを初期化
        let data = NSBundle.mainBundle().infoDictionary! as Dictionary
        let googleMapKey = data["GoogleMapKey"] as! String
        GMSServices.provideAPIKey(googleMapKey)
        
        //設定画面の値を取得
        let userDefaults = NSUserDefaults.standardUserDefaults()
        let serialCode = userDefaults.stringForKey("serial_code_preference")
        if let serialCode = serialCode {
            print("serialCode:\(serialCode)")
            
            //デバイスとの接続の為 初期化
            deviceInitialize(serialCode)
        }
    }
        
    //Twitterログイン処理
    func loginTwitter(callback:BOTWRLogInCallback){
        Ncmb.sharedInstance.loginTwitter(callback)
    }
    
    //モーダルで画面を開く
    func presentModalViewController(parent:UIViewController,vc:MainViewController){
        parent.presentViewController(vc,animated: true, completion: nil)
    }
    
    //モーダルで画面を開く
    func presentModalViewController(parent:UIViewController,identifier:String){
        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        let vc: MainViewController = storyboard.instantiateViewControllerWithIdentifier(identifier) as! MainViewController
        presentModalViewController(parent,vc:vc)
    }
    
    //GoogleMap View を初期化して画面に追加
    func initGoogleMap(view:UIView) -> GMSMapView {
        let googleMap : GMSMapView = GMSMapView(frame: CGRectMake(0, 0, view.bounds.width, view.bounds.height))
        view.addSubview(googleMap)
        return googleMap
    }
    
    //ポップアップで詳細ビューを表示
    func openPopUpDetailView(view:UIView,detail:AnyObject) -> PopUpViewControllerSwift {
        let popViewController:PopUpViewControllerSwift
        let bundle = NSBundle(forClass: PopUpViewControllerSwift.self)
        
        if UIScreen.mainScreen().bounds.size.width > 320 {
            if UIScreen.mainScreen().scale == 3 {
                popViewController = PopUpViewControllerSwift(nibName: "PopUpViewController_iPhone6Plus", bundle: bundle)
            } else {
                popViewController = PopUpViewControllerSwift(nibName: "PopUpViewController_iPhone6", bundle: bundle)
            }
        } else {
            popViewController = PopUpViewControllerSwift(nibName: "PopUpViewController", bundle: bundle)
        }
        
        let title:String = detail.objectForKey("title") as! String
        let body:String = detail.objectForKey("body") as! String
        if let url = detail.objectForKey("imageUrl") {
            //イメージをダウンロード&キャッシュする
            SDWebImageManager.sharedManager().downloadImageWithURL(
                NSURL(string: url as! String),
                options: .HighPriority,
                progress: nil,
                completed: {(image, data, error, finished, imageURL) in
                    //イメージ取得成功したら 詳細を設定して画面に表示
                    popViewController.title = title
                    popViewController.showInView(view, withImage: image, withMessage: body, animated: true)
            })
        }
        else{
            popViewController.title = title
            popViewController.showInView(view, withImage: nil, withMessage: body, animated: true)
        }
        
        return popViewController
    }
    
    /** Ready,乾杯画面を表示する
     *
     */
    func openPopUpCheersView(view:UIView,image:UIImage,closeDelay:Double,onClose:()->Void) -> PopUpViewControllerSwift {
        let popViewController:PopUpViewControllerSwift
        //let bundle = NSBundle(forClass: PopUpViewControllerSwift.self)
        let bundle = NSBundle.mainBundle()
        
        if UIScreen.mainScreen().bounds.size.width > 320 {
            if UIScreen.mainScreen().scale == 3 {
                popViewController = PopUpViewControllerSwift(nibName: "CheersPopUpViewController_iPhone6Plus", bundle: bundle)
            } else {
                popViewController = PopUpViewControllerSwift(nibName: "CheersPopUpViewController_iPhone6", bundle: bundle)
            }
        } else {
            popViewController = PopUpViewControllerSwift(nibName: "CheersPopUpViewController", bundle: bundle)
        }
        
        let data = NSBundle.mainBundle().infoDictionary! as Dictionary
        let title:String = data["CheersTweetTitleText"] as! String
        let body:String = data["CheersTweetText"] as! String

        popViewController.view.frame = UIScreen.mainScreen().bounds
        
        popViewController.title = title
        popViewController.showInView(view, withImage: image, withMessage: body, animated: true)
        
        //closeDelay 秒後に閉じる
        if(closeDelay != 0){
            CommonUtil.sleep(closeDelay) {
                popViewController.closePopup(view)
                
                //閉じたときのコールバック
                onClose()
            }
        }
        return popViewController
    }
    
    /** 乾杯後のシェア画面を表示する
     *
     */
    func openPopUpShareView(view:UIView) -> PopUpViewControllerSwift {
        let popViewController:PopUpViewControllerSwift
        let bundle = NSBundle.mainBundle()
        
        if UIScreen.mainScreen().bounds.size.width > 320 {
            if UIScreen.mainScreen().scale == 3 {
                popViewController = SharePopUpViewControllerSwift(nibName: "SharePopUpViewController_iPhone6Plus", bundle: bundle)
            } else {
                popViewController = SharePopUpViewControllerSwift(nibName: "SharePopUpViewController_iPhone6", bundle: bundle)
            }
        } else {
            popViewController = SharePopUpViewControllerSwift(nibName: "SharePopUpViewController", bundle: bundle)
        }
        
        let data = NSBundle.mainBundle().infoDictionary! as Dictionary
        let title:String = data["CheersTweetTitleText"] as! String
        let body:String = data["CheersTweetText"] as! String
        let image:UIImage = UIImage(named:"cheers")!
        
        popViewController.view.frame = UIScreen.mainScreen().bounds
        popViewController.title = title
        popViewController.showInView(view, withImage: image, withMessage: body, animated: true)

        return popViewController
    }
    
    //設定 画面を開く
    func openSettings(){
        if let url = NSURL(string:UIApplicationOpenSettingsURLString) {
            UIApplication.sharedApplication().openURL(url)
        }
    }
    
    //シェア機能
    func share(vc:UIViewController){
        // 共有する項目
        let shareText = "Apple - Apple Watch"
        let shareWebsite = NSURL(string: "https://www.apple.com/jp/watch/")!
        let shareImage = UIImage(named: "background_login_base")!
        
        let activityItems = [shareText, shareWebsite, shareImage]
        
        // 初期化処理
        let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        
        // 使用しないアクティビティタイプ
        let excludedActivityTypes = [
            UIActivityTypePostToWeibo,
            UIActivityTypeSaveToCameraRoll,
            UIActivityTypePrint
        ]
        
        activityVC.excludedActivityTypes = excludedActivityTypes
        
        // UIActivityViewControllerを表示
        vc.presentViewController(activityVC, animated: true, completion: nil)
    }
    
    //マーカーを表示する
    func addGoogleMapMarker(mapView:GMSMapView, position:CLLocationCoordinate2D, title:String){
        addGoogleMapMarker(mapView,position: position,title: title,color: nil, userData:nil)
    }
    
    //マーカーを表示する
    func addGoogleMapMarker(mapView:GMSMapView, position:CLLocationCoordinate2D, title:String, color:UIColor?, userData:AnyObject?){
        let marker = GMSMarker(position: position)
        marker.title = title
        if let color = color{
            marker.icon = GMSMarker.markerImageWithColor(color)
        }
        if let userData = userData{
            marker.userData = userData
        }
        marker.map = mapView
        
        self.markers?.append(marker)
    }
    
    //マーカーをすべて削除
    func clearGoogleMapMarker(){
        if let markers = self.markers {
            for marker in markers {
                marker.map = nil
            }
            self.markers = []
        }
    }
    
    //詳細データを作成する
    func saveDetail(detail:Detail,callback:(object:AnyObject?,error:NSError?)->Void) {
        Ncmb.sharedInstance.saveDetail(detail,callback: callback)
    }
    
    //詳細一覧を取得する
    func getDetails(detail:Detail?, km:Double?, limit:Int32?,callback:(objects:[AnyObject]?,error:NSError?)->Void){
        Ncmb.sharedInstance.getDetails(detail, km:km, limit:limit, callback: callback)
    }
    
    //詳細データ一覧を表示する
    func getDetails(detail:Detail,callback:(objects:[AnyObject]?,error:NSError?)->Void){
        self.getDetails(detail, km:nil, limit:nil, callback: callback)
    }
    
    //詳細データ一覧を表示する
    func getDetails(limit:Int32?, callback:(objects:[AnyObject]?,error:NSError?)->Void){
        self.getDetails(nil, km:nil, limit:limit, callback: callback)
    }
    
    //詳細データ一覧を表示する
    func getDetails(callback:(objects:[AnyObject]?,error:NSError?)->Void){
        self.getDetails(nil, km:nil, limit:nil, callback: callback)
    }
    
    //Konashi 初期化
    func deviceInitialize(serialCode:String){
        
        KonashiUtil.sharedInstance.initialize({
                print("connected")
            },
            disconnected: {
                print("disconnected")
            },
            ready: {
                print("ready")
            })
        
        //シリアルコードを設定
        KonashiUtil.sharedInstance.setSerialCode(serialCode)
    }
    
    //デバイス シリアルコードを取得
    func getSerialCode()->String?{
        let userDefaults = NSUserDefaults.standardUserDefaults()
        let serialCode = userDefaults.stringForKey("serial_code_preference")
        return serialCode;
    }
    
    //デバイス検索&接続
    func find(){
        //シリアルコードを毎回 確認する
        if let serialCode = getSerialCode(){
            KonashiUtil.sharedInstance.setSerialCode(serialCode)
        }
        
        KonashiUtil.sharedInstance.find()
    }
    
    //Bluetoothの接続状態を監視する
    func monitorConnection(callback:(isConnected:Bool)->Void){
        //Bluetoothの接続状態を確認するタイマー
        NSTimer.scheduledTimerWithTimeInterval(reFindSec, target: NSBlockOperation(block: {
            callback(isConnected: KonashiUtil.sharedInstance.isConnected())
        }), selector: #selector(NSOperation.main), userInfo: nil, repeats: true)
    }
    
    //デジタル インプットに設定したピンに変化があった場合の処理
    func updateNotification(callback:(pin:KonashiDigitalIOPin, value:Int32)->Void){
       KonashiUtil.sharedInstance.setUpdateNotification( callback )
    }
    
    //ノティフケーション関係の初期化
    func initializeUserNotification(){
        //現在のノティフケーションを全て削除
        UIApplication.sharedApplication().cancelAllLocalNotifications()
        
        //パーミッション設定
        let notiSettings = UIUserNotificationSettings(forTypes:[.Alert,.Sound,.Badge], categories:nil)
        UIApplication.sharedApplication().registerUserNotificationSettings(notiSettings)
        //UIApplication.sharedApplication().registerForRemoteNotifications()
    }
    
    //ローカル通知を設定する
    func addUserNotification(){
        //info.plistからツイート内容テキスト取得
        let data = NSBundle.mainBundle().infoDictionary! as Dictionary
        let cheersTweetText = data["CheersTweetText"] as! String
        
        let notif = UILocalNotification()
        notif.timeZone = NSTimeZone.defaultTimeZone()
        notif.alertBody = cheersTweetText
        notif.alertAction = "OK"
        notif.soundName = UILocalNotificationDefaultSoundName
        UIApplication.sharedApplication().scheduleLocalNotification(notif)
    }
    
    //Twitterへの投稿
    func sendTwitterRequest(object:AnyObject){
        print("objectId:\(object.objectId)")
        
        //info.plistからツイート内容テキスト取得
        let data = NSBundle.mainBundle().infoDictionary! as Dictionary
        let cheersTweetText = data["CheersTweetText"] as! String
        
        //送信メッセージを作成
        let message = "\(cheersTweetText) http://example.com/detail?id=\(object.objectId)"
        
        //Twitterセッションを初期化
        let authToken = NCMBTwitterUtils.twitter().authToken
        let authTokenSecret = NCMBTwitterUtils.twitter().authTokenSecret
        Twitter.sharedInstance().sessionStore.saveSessionWithAuthToken(authToken, authTokenSecret: authTokenSecret, completion: { (session, error) -> Void in
            
            if let error = error {
                print("error:\(error)")
                return
            }
            
            let store = Twitter.sharedInstance().sessionStore
            if let userid = store.session()?.userID {
                //ユーザーIDを指定してPOSTする
                let client = TWTRAPIClient(userID:userid)
                self.twitterStatusUpdateWithClient(client,message: message)
            }

        })
    }
    
    //Twitterに投稿
    func twitterStatusUpdateWithClient(client:TWTRAPIClient,message:String){
        var clientError : NSError?
        let endPoint = "https://api.twitter.com/1.1/statuses/update.json"
        let params = ["status":message]
        let request = client.URLRequestWithMethod("POST", URL: endPoint, parameters: params, error: &clientError)
        client.sendTwitterRequest(request) { (response, data, connectionError) -> Void in
            if (connectionError == nil) {
                print("sucess")
            }
            else {
                print("Error: \(connectionError)")
            }
        }
    }
    
    //アラーム音を鳴らす
    func playAlarm(fileName:String){
        var soundId:SystemSoundID = 0
        // システムサウンドへのパスを指定
        let path = NSBundle.mainBundle().pathForResource(fileName, ofType: "wav")
        if let soundUrl:NSURL = NSURL.fileURLWithPath(path!) {
            //print("soundUrl:\(soundUrl)")
            // SystemsoundIDを作成して再生実行
            CommonUtil.dispatch_async_main({
                AudioServicesCreateSystemSoundID(soundUrl, &soundId)
                AudioServicesPlaySystemSound(soundId)
            })
        }
    }
    
    //初回 起動時にシリアルコード入力を促すアラートを表示させる
    func showAlertOpenSettings(vc:UIViewController){
        let alert: UIAlertController = UIAlertController(title: "初期設定", message: "設定画面で デバイスの Serial Code を設定してください。", preferredStyle:  UIAlertControllerStyle.Alert)
        let defaultAction: UIAlertAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler:{
            // ボタンが押された時の処理を書く（クロージャ実装）
            (action: UIAlertAction!) -> Void in
            //設定画面を開く
            BottleOpener.sharedInstance.openSettings()
        })
        alert.addAction(defaultAction)
        vc.presentViewController(alert, animated: true, completion: nil)
    }
    
}

//Twitter ログインのコールバック
public typealias BOTWRLogInCallback = (NCMBUser!, NSError!) -> Void
