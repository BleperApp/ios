//
//  MainViewController.swift
//  bo
//
//  Created by 古川信行 on 2016/07/25.
//  Copyright © 2016年 tf-web. All rights reserved.
//

import UIKit
import GoogleMaps
import NMPopUpViewSwift
import NCMB

class MainViewController: UIViewController,CLLocationManagerDelegate,GMSMapViewDelegate {
    //Google Map
    private var googleMap:GMSMapView!
    
    //詳細 ポップアップ
    private var popDetailViewController:PopUpViewControllerSwift!

    //ロケーションマネージャー
    private var locationManager:CLLocationManager!
    
    //位置情報トラッキング
    private var isTracking:Bool = true
    
    //位置情報トラッキング 切り替えボタン
    @IBOutlet weak var btnTracking: UIBarButtonItem!
 
    //Bluetoothアイコン
    @IBOutlet weak var btnBluetooth: UIBarButtonItem!

    //ナビゲーションバー
    @IBOutlet weak var naviTitleItem: UINavigationItem!
    
    //最後にGPS取得した位置
    var lastLocation: CLLocationCoordinate2D?
    
    //Ready状態
    private var isReady:Bool = false
    
    //閉じる
    func dismissViewController(){
        self.dismissViewControllerAnimated(true,completion:nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //タイトルを設定
        let appName = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleName") as! String
        naviTitleItem.title = appName
        
        //位置情報取得の初期化
        initLocationManager()
        
        //デバイスとの接続
        BottleOpener.sharedInstance.find()
        
        //Bluetoothの接続状態を確認するタイマー
        BottleOpener.sharedInstance.monitorConnection { (isConnected) in
            if isConnected == true {
                //接続 済み
                self.btnBluetooth.tintColor = BottleOpener.DefaultButtonColor
            }
            else{
                //未接続 状態
                self.btnBluetooth.tintColor = UIColor.whiteColor()
                BottleOpener.sharedInstance.find()
            }
        }
        
        //ボタンが押された時の通知
        BottleOpener.sharedInstance.updateNotification { (pin, value) in
            print("updateNotification")
            print("pin:\(pin) value::\(value)")
            //TODO: value 1 で乾杯開始
            if value == 1 {
                //value 1 で Ready！を表示
                self.isReady = false
                CommonUtil.sleep(3) {
                    if self.view != nil {
                        if self.isReady == false {
                            self.isReady = true
                            if self.view != nil && self.popDetailViewController != nil {
                                self.popDetailViewController.closePopup(self.view)
                                self.popDetailViewController = nil
                            }
                            //Ready! 時の効果音を鳴らす
                            BottleOpener.sharedInstance.playAlarm("ready")
                            self.popDetailViewController = BottleOpener.sharedInstance.openPopUpCheersView(self.view,
                                image: UIImage(named:"ready")!,
                                closeDelay: 0,
                                onClose:{
                                    print("onClose")
                            })
                        }
                    }
                }
            }
            else if value == 0 {
                //value 0 で乾杯
                //Ready!を消す。
                if self.view != nil && self.popDetailViewController != nil {
                    self.popDetailViewController.closePopup(self.view)
                    self.popDetailViewController = nil
                }
                
                //Ready! 未設定なので以下の処理をしない
                if(self.isReady == false){
                    self.isReady = true
                    return
                }
                
                if self.view != nil {
                    //乾杯画面をポップアプする
                    self.popDetailViewController = BottleOpener.sharedInstance.openPopUpCheersView(self.view,
                        image: UIImage.sd_animatedGIFNamed("ani_cheers")!,
                        closeDelay:0.6,
                        onClose:{
                            print("onClose")
                            
                            //乾杯後のシェア画面 に 位置譲歩を設定して 開く
                            self.popDetailViewController = BottleOpener.sharedInstance.openPopUpShareView(self.view)
                            if let location = self.lastLocation {
                                (self.popDetailViewController as! SharePopUpViewControllerSwift).setLastLocation(location)
                            }
                    })
                }
                
                //乾杯時の効果音を鳴らす
                BottleOpener.sharedInstance.playAlarm("cheers")
                //ローカル通知をする
                BottleOpener.sharedInstance.addUserNotification()
                
                self.isReady = false
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private var onceTokenViewDidAppear: dispatch_once_t = 0
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        //一度だけ実行
        dispatch_once(&onceTokenViewDidAppear) {
            //print(self, "viewDidAppear")
            //Google Mapeを初期化 画面に追加
            let subView = self.view.viewWithTag(1)!
            self.googleMap = BottleOpener.sharedInstance.initGoogleMap(subView)
            self.googleMap.delegate = self
        }
        
        
        if let code = BottleOpener.sharedInstance.getSerialCode() {
            print("code \(code)")
        }
        else{
            print("show alert")
            //TODO: 未設定なのでダイアログを表示後に設定画面を開く
            BottleOpener.sharedInstance.showAlertOpenSettings(self)
        }
    }
    
    //戻るボタン タップ時
    @IBAction func clickBack(sender: AnyObject) {
        self.dismissViewController()
    }

    //位置情報トラッキング タップ時
    @IBAction func clickBtnTracking(sender: AnyObject) {
        isTracking = !isTracking
        if isTracking == true {
            //DEFAULT
            btnTracking.tintColor = BottleOpener.DefaultButtonColor
        }
        else{
            //背景の色を変更
            btnTracking.tintColor = UIColor.whiteColor()
        }
    }

    //設定 タップ時
    @IBAction func clickBtnSettings(sender: AnyObject) {
        //設定を開く
        BottleOpener.sharedInstance.openSettings()
    }
    
    //List タップ時
    @IBAction func clickBtnShowList(sender: AnyObject) {
        
    }
    
    //シェア タップ時
    @IBAction func clickBtnShare(sender: AnyObject) {
        BottleOpener.sharedInstance.share(self)
    }
    
    //ロケーションマネージャを初期化
    func initLocationManager(){
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.startUpdatingLocation()
    }
    
    // CLLocationManagerDelegate ----
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        switch status {
        case .NotDetermined:
            // ユーザが位置情報の使用を許可していない
            locationManager.requestAlwaysAuthorization()
        default:
            break
        }
    }
    
    //現在 位置情報を表示
    func locationManager(manager: CLLocationManager, didUpdateToLocation newLocation: CLLocation, fromLocation oldLocation: CLLocation){
        let currentLocation = CLLocationCoordinate2D(latitude:newLocation.coordinate.latitude,longitude:newLocation.coordinate.longitude)
        
        if isTracking == false {
            return
        }
        
        //地図のセンターを現在位置に変更
        if let map = self.googleMap {
            //中央に移動
            let now :GMSCameraPosition = GMSCameraPosition.cameraWithLatitude(currentLocation.latitude,longitude:currentLocation.longitude,zoom:17)
            map.camera = now
            
            if lastLocation != nil {
                if currentLocation.latitude == lastLocation?.latitude && currentLocation.longitude == lastLocation?.longitude {
                    //位置情報が同じだった場合 以下の処理をしない
                    return
                }
            }
            
            //オーバーレイされたMakerなどを削除
            BottleOpener.sharedInstance.clearGoogleMapMarker()
            map.clear()
            
            //現在位置 マーカを表示
            BottleOpener.sharedInstance.addGoogleMapMarker(map,position: currentLocation, title: "CURRENT")
            
            lastLocation = currentLocation

            let detail = Detail()
            BottleOpener.sharedInstance.getDetails(detail,callback:{(objects:[AnyObject]?,error:NSError?) in
                if let error = error {
                    print("error:\(error)")
                }
                if let objs = objects {
                    //print("details:\(objs)")
                    for obj in objs {
                        //詳細を指定した マーカーをマップに追加
                        let objId = obj.objectId
                        let title = obj.objectForKey("title") as! String
                        let loc = obj.objectForKey("location") as! NCMBGeoPoint
                        let coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude:loc.latitude,longitude:loc.longitude)
                        BottleOpener.sharedInstance.addGoogleMapMarker(map,position: coordinate, title: title, color: UIColor.blueColor(),userData: objId)
                    }
                }
            })
        }
    }
    
    // GMSMapViewDelegate -----
    func mapView(mapView: GMSMapView, didTapMarker marker: GMSMarker) -> Bool {
        //print("didTapMarker")
        //マーカーをタップ
        if let objId = marker.userData {
            //詳細を検索
            //print("objId:\(objId)")
            
            let detail = Detail()
            detail.setObjectId(objId as! String)
            BottleOpener.sharedInstance.getDetails(detail,callback:{(objects:[AnyObject]?,error:NSError?) in
                /*
                if let objs = objects {
                    //TODO: ポップアップ表示内容を考える事
                    //self.popDetailViewController = BottleOpener.sharedInstance.openPopUpDetailVie(self.view,detail: objs[0])
                }
                */
            })
        }
        
        return true
    }
}
