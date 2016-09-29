//
//  ViewController.swift
//  bo
//
//  Created by 古川信行 on 2016/07/25.
//  Copyright © 2016年 tf-web. All rights reserved.
//

import UIKit
import NCMB

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //ログイン状態を確認する
        loginTwitter({(user) in
                print("success")
                //ログイン成功したので メイン画面へ遷移
                BottleOpener.sharedInstance.presentModalViewController(self, identifier: "MainView")
            },
            failure:{()
                print("failure")
            })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //Twitter Login
    func loginTwitter(success:(user:NCMBUser)->Void,failure:()->Void){
        BottleOpener.sharedInstance.loginTwitter { user, error in
            if (user == nil) {
                failure()
            }
            else if (user.isNew) {
                success(user:user)
            }
            else {
                success(user:user)
            }
        }
    }
    
    //Twitter Login ボタン
    @IBAction func clickTwitterLogin(sender: AnyObject) {
        //TODO: 利用規約表示
        //Twitter Login
        loginTwitter({(user) in
                print("success")
                //ログイン成功したので メイン画面へ遷移
                BottleOpener.sharedInstance.presentModalViewController(self, identifier: "MainView")
            },
            failure:{()
                print("failure")
                //TODO: ログイン失敗 アラート表示
            })
    }
}

