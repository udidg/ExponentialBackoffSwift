//
//  ViewController.swift
//  BackoffTimerTests
//
//  Created by Udi Dagan on 4/20/16.
//  Copyright © 2016 Udi Dagan. All rights reserved.
//

import UIKit
import UDExponentialBackoffTimer


class ViewController: UIViewController, UDExponentialBackoffTimerDelegate{
    
    @IBOutlet weak var initialTimeInterval: UITextField!
    @IBOutlet weak var multiplierTextField: UITextField!
    
    @IBAction func resetBtnPressed(sender: AnyObject) {
        self.timer?.reset()
    }
    var timer : UDExponentialBackoffTimer?

    
    @IBAction func stopBtnPressed(sender: AnyObject) {
        self.timer?.stop()
    }
    
    @IBAction func nextBtnPressed(sender: AnyObject) {
        self.timer?.nextBackOffMillis()
    }
    @IBAction func startBtnPressed(sender: AnyObject) {
        self.timer?.start()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.timer = UDExponentialBackoffTimer(maxElapsedTimeMillis: 60*1000, initialIntervalMillis: 5*1000, maxIntervalMillis: 80*1000, multiplier: 2, randomizationFactor: nil, delegate: self)
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func backoffTimerFired (numberOfAttempts : Int, elapsedTime : Double){
        print("backoffTimerFired :: number of attempts \(numberOfAttempts), elapsed time: \(elapsedTime)")
        
    }
    func backoffTimerStop (reason : BackoffIvalidationType){
        print("backoffTimerStop :: reason: \(reason.rawValue)")
    }


}

