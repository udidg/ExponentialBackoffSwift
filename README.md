# ExponentialBackoffSwift

INTRODUCTION
------------
UDExponentialBackOffTimer is a Swift implementation of a backoff algorithem commonly used for retry mechanism.  
The Timer is initiazlied with interval parameters, a multiplier and two threashhold parameters maxElapsedTimeMillis and maxIntervalMillis that whould cause the timer to stop. 
* Find more info about Backoff Algorithem in: 
- (https://en.wikipedia.org/wiki/Exponential_backoff)
- (https://developers.google.com/api-client-library/java/google-http-java-client/backoff)

REQUIREMENTS
------------
Swift 2.2
Xcode 7.3 + 

INSTALLATION
------------
 * Copy UDExponentialBackoffTimer.swift to your project. 

INITIALIZATION AND CONFIGURATION
------------
The timer uses the following parameters (passed during initiazliation): 
 * initialIntervalMillis - The first time interval that is used in the first iteration. [Milliseconds]
 * multiplier - The interval will be multiplied by this variable on each iteration. 
 * randomizationFactor - A small random factor is added to each interval. The random factor generated between [0-randomizationFactor]
 * maxElapsedTimeMillis - The timer will stop if it reaches a total time of maxElapsedTimeMillis counting all the iterations all together. 
 * maxIntervalMillis - The timer will stop if it reaches an interval time that is greater than or equal to maxIntervalMillis. The timer stops after the interval is set and no after the interval has passed. [Milliseconds]

UDExponentialBackoffTimerDelegate
------------
Implementing the following protocol is essential for operating the backofftimer: 
* func backoffTimerFired (numberOfAttempts : Int, elapsedTime : Double)
* func backoffTimerStop (reason : BackoffIvalidationType)
- Backoff Ivalidation Types: [MAX_INTERVAL_TIME_REACHED, MAX_TIME_EPLAPSED_REACHED]

Public API
------------
* start - Schedule the timer. Can be called only when the timer is not running. 
* stop - Invalidate the timer. Calling Start will schedule the next interval. 
* nextBackOffMillis - Schedule the next interval. Can be called only when the timer is not running. 
* reset - Reset to timer initial interval and elapsed time is set to 0. Can be called only when the timer is not running. 

The following scheme demonstrate the allowed transitions between the states: 
![alt tag](http://www.gliffy.com/go/publish/image/10486535/L.png)

