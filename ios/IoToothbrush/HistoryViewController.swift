//
//  HistoryViewController.swift
//  IoToothbrush
//
//  Created by Matthew Lewinski on 5/1/16.
//  Copyright © 2016 Matthew Lewinski. All rights reserved.
//

import UIKit

class HistoryViewController: UIViewController {
    @IBOutlet weak var webView: UIWebView!

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        let htmlFile = NSBundle.mainBundle().pathForResource("charts", ofType: "html")
        let htmlString = try! String(contentsOfFile: htmlFile!, encoding: NSUTF8StringEncoding)
        webView.loadHTMLString(htmlString, baseURL: nil)
    }

    func unwindToHistoryViewContainer() {
    }
}

