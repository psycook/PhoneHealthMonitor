//
//  AppDelegate.swift
//  PhoneHealthMonitor
//
//  Created by Simon Cook on 21/07/2016.
//  Copyright © 2016 Simon Cook. All rights reserved.
//

import UIKit
import HealthKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    let healthKitStore = HKHealthStore();

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        requestHealthKitAccess();
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    
    func requestHealthKitAccess() {
        guard HKHealthStore.isHealthDataAvailable() == true else {
            print("HealthKit not available");
            return
        }
        
        // Specify our HealthKit object types to read
        let healthKitTypesToRead = NSSet(
            objects:
            HKObjectType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierDateOfBirth)!,
            HKObjectType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierBloodType)!,
            HKObjectType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierBiologicalSex)!,
            HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate)!,
            HKQuantityType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount)!
            ) as! Set<HKObjectType>
        
        print("request health kit permission");
        
        healthKitStore.requestAuthorizationToShareTypes(nil, readTypes: healthKitTypesToRead) { (success, error) -> Void in
            if success == false {
                print("Error requesting healthkit authorisation: " + error.debugDescription);
            } else {
                print("Healthkit allowed");
            }
        }
    }

}

