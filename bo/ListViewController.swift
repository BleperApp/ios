//
//  ListViewController.swift
//  bo
//
//  Created by 古川信行 on 2016/09/21.
//  Copyright © 2016年 tf-web. All rights reserved.
//

import Foundation
import UIKit
import NCMB

class ListViewController :UIViewController,UITableViewDataSource,UITableViewDelegate {
    //ナビゲーションバー タイトル
    @IBOutlet weak var naviTitleItem: UINavigationItem!

    //Close ボタン
    @IBOutlet weak var btnCloseItem: UIBarButtonItem!
    
    //テーブル
    @IBOutlet weak var tableView: UITableView!
    
    var details:NSArray = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //リストログ
        let appName = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleName") as! String
        naviTitleItem.title = appName
        
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        //デリゲートを設定
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated:Bool){
        super.viewDidAppear(animated)
        print("viewDidAppear")
        
        //ここでデータ一覧を取得する
        BottleOpener.sharedInstance.getDetails(100) { (objects, error) in
            if let error = error {
                print("error \(error)")
                return
            }
            self.details = objects!
            //print("details \(self.details)")
            
            //テーブル再描画
            self.tableView.reloadData()
        }
    }
    
    //閉じるボタン タップ時
    @IBAction func clickBtnClose(sender: UIBarButtonItem) {
        print("clickBtnCloseItem")
        dismissViewControllerAnimated(true) {
            print("close")
        }
    }
    
    // UITableViewDataSource ----
    
    // セルの行数
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //print("count \(details.count)")
        return details.count
    }
    
    // セルのテキストを追加
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let detail:AnyObject = self.details[indexPath.row]
        //print("detail \(detail)")
        
        let location:NCMBGeoPoint = detail.objectForKey("location") as! NCMBGeoPoint
        let createDate = detail.objectForKey("createDate")

        let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "Cell")
        cell.textLabel!.text = "\(createDate!)"
        cell.detailTextLabel!.text = "\(location.latitude),\(location.longitude)"
        
        return cell
    }
    
    //行選択時のイベント
    func tableView(table: UITableView, didSelectRowAtIndexPath indexPath:NSIndexPath) {
        print("row \(indexPath.row)")
        //performSegueWithIdentifier("segueShowListView",sender: nil)
    }
    
    // Segueで遷移時の処理
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        //if (segue.identifier == "segueShowListView") {
        //
        //
        //}
    }
}
