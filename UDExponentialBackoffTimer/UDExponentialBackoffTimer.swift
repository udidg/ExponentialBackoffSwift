//
//  UDExponentialBackoffTimer.swift
//  UDExponentialBackoffTimer
//
//  Created by Udi Dagan on 4/20/16.
//  Copyright © 2016 Udi Dagan. All rights reserved.
//

import Foundation

public enum BackoffIvalidationType: String {
    case MAX_INTERVAL_TIME_REACHED = "MAX_INTERVAL_TIME_REACHED"
    case MAX_TIME_EPLAPSED_REACHED = "MAX_TIME_EPLAPSED_REACHED"
    case UNKNOWEN = "UNKNOWEN"
}

enum BackoffStatus: String {
    case INITIALIZED = "INITIALIZED" //Init without calling start
    case STARTED = "STARTED"  //Timer was scheduled
    case RUNNING = "RUNNING"  //Timer is counting down
    case IDLE = "IDLE"        //Timer fired and paused
    case STOPPED = "STOPPED"  //Timer was stopped invalidated by the user
    case FINISHED = "FINISHED"  //Timer was stopped invalidated after reaching the limit
    
}



public protocol UDExponentialBackoffTimerDelegate : class {
    func backoffTimerFired (numberOfAttempts : Int, elapsedTime : Double)
    func backoffTimerStop (reason : BackoffIvalidationType)
}


public class UDExponentialBackoffTimer {
    
    // MARK: Properties
    /**
     Max Timer for which the backoff should reach its limit and stop. The backoff could stop also if it reaches an interval that is longer than maxIntervalMillis
     */
    var maxElapsedTimeMillis : Double
    
    /**
     First attemt in the backoff should fire after initialIntervalMillis miliseconds
     */
    var initialIntervalMillis : Double
    
    /**
     Max interval in milisecond for which the backoff should reach its limit and stop. The backoff could stop if it reaches a total maxElapsedTimeMillis as well
     */
    var maxIntervalMillis : Double
    
    /**
     On each iteretion the backoff is multiplied by 'multiplier'
     */
    var multiplier : Double
    
    
    
    /**
     On each iteration the backoff is adding a random value between [0-randomizationFactor]
     */
    var randomizationFactor : Double
    
    /**
     Cumulative sum of all attempts
     */
    var cumsum : Double = 0
    
    /**
     The number of times the backoff timer is scheduled (not fired, scheduled)
     */
    var numberOfAttemps : Int = 0
    
    /**
     Last time the time was scheduled (not fired, scheduled)
     */
    var lastSchedualedTime : NSDate?
    
    
    weak var backoffTimerDelegate : UDExponentialBackoffTimerDelegate?
    
    
    
    private var backoffTimer : NSTimer?
    
    private var backoffStatus : BackoffStatus
    
    
    // MARK: Public API
    public init(maxElapsedTimeMillis : Double, initialIntervalMillis : Double, maxIntervalMillis : Double, multiplier : Double, randomizationFactor : Double?, delegate : UDExponentialBackoffTimerDelegate){
        self.maxIntervalMillis = maxIntervalMillis
        self.initialIntervalMillis = initialIntervalMillis
        self.maxElapsedTimeMillis = maxElapsedTimeMillis
        self.multiplier = multiplier
        self.randomizationFactor = randomizationFactor ?? 0
        self.backoffTimerDelegate = delegate
        self.backoffStatus = .INITIALIZED
    }
    
    public func nextBackOffMillis (){
        //TODO add the random factor
        guard self.backoffStatus == .IDLE || self.backoffStatus == .STARTED else {
            print("Next can be called only on IDLE or started times")
            return
        }
        
        if self.timerIsValid(){
            return
        }
        let nextBackoffInterval = max(self.initialIntervalMillis, self.cumsum * self.multiplier)
        if nextBackoffInterval > self.maxIntervalMillis {
            self.timerStoppedWithReason(.MAX_INTERVAL_TIME_REACHED)
            self.finish()
            return
        }else if cumsum + nextBackoffInterval > self.maxElapsedTimeMillis {
            self.timerStoppedWithReason(.MAX_TIME_EPLAPSED_REACHED)
            self.finish()
            return
        }
        
        self.schduleNextAttept(nextBackoffInterval)
    }
    
    public func reset (){
        self.numberOfAttemps = 0
        self.cumsum = 0
        self.backoffStatus = .STOPPED
        self.backoffTimer?.invalidate()
        self.backoffStatus = .INITIALIZED
    }
    
    public func start () {
        guard self.backoffStatus == .INITIALIZED || self.backoffStatus == .STOPPED else {
            print("Next can be called only on INITIALIZED or STOPPED times")
            return
        }
        
        if timerIsValid() {
            return
        }
      
        self.backoffStatus = .STARTED
        self.nextBackOffMillis()
    }
    
    public func stop(){
        self.backoffStatus = .STOPPED
        self.backoffTimer?.invalidate()
        print ("backoff timer invalidated. after \(self.numberOfAttemps) attempts and \(self.getElapsedTimeSinceLastScheduledTimer()) total time spent is \(self.cumsum) millis")
    }
    
    
    // MARK: Events
    @objc private func timerFired () {
        
        self.backoffStatus = .IDLE
        guard let timeElapsed = self.getElapsedTimeSinceLastScheduledTimer() else{
            return
        }
        self.cumsum += (timeElapsed)
        self.backoffTimerDelegate?.backoffTimerFired(self.numberOfAttemps, elapsedTime: self.cumsum)
    }
    
    private func timerStoppedWithReason (reason : BackoffIvalidationType){
        self.backoffTimerDelegate?.backoffTimerStop(reason)
    }
    
    
    // MARK: Helpers
    /**
     Returns the time interval in milllis from the last time the timer has been initialized. Nil is return in case the last scheduled time is unknown (nil)
     */
    private func getElapsedTimeSinceLastScheduledTimer ()-> Double? {
        guard self.lastSchedualedTime != nil else {
            print("last scheduled time is nil, timer stopped")
            self.backoffTimerDelegate?.backoffTimerStop(.UNKNOWEN)
            return nil
        }
        let timeIntervalSeconds = NSDate().timeIntervalSinceDate(self.lastSchedualedTime!) //time since the timer was scehduled
        
        return timeIntervalSeconds*1000
    }
    
    private func schduleNextAttept (timeIntevalInMillis : Double){
        numberOfAttemps += 1
        self.backoffStatus = .RUNNING
        backoffTimer = NSTimer.scheduledTimerWithTimeInterval(timeIntevalInMillis/1000, target: self, selector: #selector(timerFired), userInfo: nil, repeats: false)
        self.lastSchedualedTime = NSDate()
    }
    /**
     check and return true if the time is alreay scheduled
     */
    private func timerIsValid () -> Bool{
        //if let timer = self.backoffTimer where timer.valid {
        if self.backoffStatus == .RUNNING {
            print("Timer already scheduled")
            return true
        }
        return false
    }
    
    private func finish (){
        self.backoffStatus = .FINISHED
        self.backoffTimer?.invalidate()
        print ("backoff timer invalidated. after \(self.numberOfAttemps) attempts and \(self.getElapsedTimeSinceLastScheduledTimer()) total time spent is \(self.cumsum) millis")
    }
    
    deinit{
        self.backoffStatus = .STOPPED
        self.backoffTimer?.invalidate()
        self.backoffTimer = nil
        self.backoffTimerDelegate = nil
    }
    
    
    
    
    
}