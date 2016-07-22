//
//  ViewController.swift
//  PhoneHealthMonitor
//
//  Created by Simon Cook on 21/07/2016.
//  Copyright © 2016 Simon Cook. All rights reserved.
//

import UIKit
import HealthKit

class ViewController: UIViewController {
    
    @IBOutlet weak var ageTextField: UITextField!
    @IBOutlet weak var DoBTextField: UITextField!
    @IBOutlet weak var sexTextField: UITextField!
    @IBOutlet weak var bloodTypeTextField: UITextField!
    @IBOutlet weak var startStopButton: UIButton!
    
    @IBOutlet weak var heartRateLabel: UILabel!
    @IBOutlet weak var stepsLabel: UILabel!
    
    let healthKitStore = HKHealthStore()
    var anchor = HKQueryAnchor(fromValue: Int(HKAnchoredObjectQueryNoAnchor))
    var isSessionActive = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        print("view did load")
        self.ageTextField.text = "NA"
        self.DoBTextField.text = "NA"
        self.sexTextField.text = "NA"
        self.bloodTypeTextField.text = "NA"
        self.heartRateLabel.text = "---";
        self.stepsLabel.text = "---";
        
    }
    
    override func viewWillAppear(animated: Bool) {
        // Set up our Profile Characteristics

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func startStopButtonPressed(sender: AnyObject) {
        if (self.isSessionActive)
        {
            // Finish the current session
            self.isSessionActive = false
            self.startStopButton.setTitle("Start Monitoring", forState: .Normal)
            self.didSessionEnd(NSDate())
        } else {
            // Start a new session
            self.isSessionActive = true
            self.startStopButton.setTitle("Stop Monitoring", forState: .Normal)
            self.didSessionStart(NSDate())
        }
    }
    
    
    // Get the Date Of Birth Information
    func getProfileDOB() -> String? {
        var dateOfBirth: String?
        
        do {
            // Request the user's Birthday and calculate the age
            let birthdate = try healthKitStore.dateOfBirth()
            // Get the Date Of Birth and format it
            let dateFormatter = NSDateFormatter()
            dateFormatter.dateStyle = .ShortStyle
            dateOfBirth = dateFormatter.stringFromDate(birthdate)
        }
        catch { return nil }
        
        // Return our Date Of Birth Information
        return dateOfBirth
    }
    
    // Calculate the Age based on the Date Of Birth
    func calculateAgeOfPerson(birthDate: String) -> Int?
    {
        // Request the user's Birthday and calculate the age
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .ShortStyle
        
        let today = NSDate()
        let calendar = NSCalendar.currentCalendar()
        let dateComponents = calendar.components(NSCalendarUnit.Year,
                                                 fromDate: dateFormatter.dateFromString(birthDate)!,
                                                 toDate: today,
                                                 options: NSCalendarOptions.WrapComponents)
        
        // Calculate the Age and return
        return dateComponents.year
    }
    
    // Get the Biological Sex Information
    func getProfileSexType()-> String? {
        
        var biologicalSexType: String?
        
        do {
            let biologicalSex = try healthKitStore.biologicalSex()
            switch biologicalSex.biologicalSex {
            case .Female:
                biologicalSexType = "Female"
            case .Male:
                biologicalSexType = "Male"
            case .NotSet:
                biologicalSexType = ""
            default:
                biologicalSexType = ""
            }
        }
        catch { return nil }
        
        // Return our information back
        return biologicalSexType
    }
    
    // Get the Biological Blood Type Information
    func getProfileBloodType()-> String? {
        
        var biologicalBloodType: String?
        
        do {
            let bloodType = try healthKitStore.bloodType()
            
            switch bloodType.bloodType {
            case .APositive:
                biologicalBloodType = "A+"
            case .ANegative:
                biologicalBloodType = "A-"
            case .BPositive:
                biologicalBloodType = "B+"
            case .BNegative:
                biologicalBloodType = "B-"
            case .ABPositive:
                biologicalBloodType = "AB+"
            case .ABNegative:
                biologicalBloodType = "AB-"
            case .OPositive:
                biologicalBloodType = "O+"
            case .ONegative:
                biologicalBloodType = "O-"
            case .NotSet:
                biologicalBloodType = ""
            }
        }
        catch { return nil }
        
        return biologicalBloodType
    }
    
    
    //
    // Query functions
    //
    // Create our Heart Rate Query
    func heartRateStreamingQuery(workoutStartDate: NSDate) -> HKQuery?
    {
        guard let heartRateSample = HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeartRate) else { return nil }
        
        let heartRateQuery = HKAnchoredObjectQuery(type: heartRateSample,
                                                   predicate: nil,
                                                   anchor: anchor,
                                                   limit: Int(HKObjectQueryNoLimit)) { (query, sampleObjects, deletedObjects, newAnchor, error) -> Void in
            self.anchor = newAnchor!
            
            guard let heartRateSamples = sampleObjects as? [HKQuantitySample] else { return }
            
            dispatch_async(dispatch_get_main_queue()) {
                guard let sample = heartRateSamples.last else { return }
                let value = sample.quantity.doubleValueForUnit(HKUnit(fromString: "count/min"))
                
                let df: NSDateFormatter = NSDateFormatter();
                df.dateStyle = NSDateFormatterStyle.ShortStyle
                df.timeStyle = .MediumStyle
                let startDate = sample.startDate
                let endDate = sample.endDate
                print("initial heart rate of " + String(value) + " from " + df.stringFromDate(startDate) + " until " + df.stringFromDate(endDate))
                self.heartRateLabel.text = String(UInt16(value))
            }
        }
        
        heartRateQuery.updateHandler = {(query, samples, deleteObjects, newAnchor, error) -> Void in
            
            print("updating heart rate")

            self.anchor = newAnchor!
            guard let heartRateSamples = samples as? [HKQuantitySample] else { return }
            
            dispatch_async(dispatch_get_main_queue()) {
                guard let sample = heartRateSamples.last else { return }
                let value = sample.quantity.doubleValueForUnit(HKUnit(fromString: "count/min"))
                self.heartRateLabel.text = String(UInt16(value))
            }
        }
        return heartRateQuery
    }
    
    // Query the HealthKit store to return the total number of steps attempted for a given day
    func dailyStepsStreamingQuery(workoutStartDate: NSDate) -> HKQuery?
    {
        // Call our Sample type for our HealthKit class to return
        guard let dailyStepsSample = HKSampleType.quantityTypeForIdentifier(HKQuantityTypeIdentifierStepCount) else { return nil }
        
        let calendar = NSCalendar.currentCalendar()
        
        let startDate = calendar.dateBySettingHour(0, minute: 0, second: 0, ofDate: workoutStartDate, options: NSCalendarOptions.WrapComponents)
        
        //let startDate = calendar.dateByAddingUnit(NSCalendarUnit.Day, value: -1, toDate: workoutStartDate, options: NSCalendarOptions.WrapComponents)
        
        let predicate = HKQuery.predicateForSamplesWithStartDate(startDate, endDate: workoutStartDate, options: HKQueryOptions.StrictEndDate)
        let dailyStepsQuery = HKSampleQuery(sampleType: dailyStepsSample, predicate: predicate, limit: 0, sortDescriptors: nil) {
            [unowned self] (query, results, error) in
            guard let dailyStepsSamples = results as? [HKQuantitySample] else { return }
            guard dailyStepsSamples.count > 0 else { return }
            
            dispatch_async(dispatch_get_main_queue()) {
                print("updating steps")
                var dailySteps : Double = 0
                
                let df: NSDateFormatter = NSDateFormatter();
                df.dateStyle = NSDateFormatterStyle.ShortStyle
                df.timeStyle = .MediumStyle
                for steps in dailyStepsSamples {
                    let stepCount = steps.quantity.doubleValueForUnit(HKUnit.countUnit())
                    let startDate = steps.startDate
                    let endDate = steps.endDate
                    print("adding steps " + String(stepCount) + " starting at " + df.stringFromDate(startDate) + " until " + df.stringFromDate(endDate))
                    dailySteps += stepCount
                }
                self.stepsLabel.text = String(UInt16(dailySteps))
            }
        }
        
        // Return our Query string back to the calling method
        return dailyStepsQuery
    }
    
    //
    // UI Button Functions
    //
    
    // Start a workout
    func didSessionStart(date : NSDate) {
        
        // Start a Step Counter WorkOut
        if let dailyStepsQuery = dailyStepsStreamingQuery(date) {
            healthKitStore.executeQuery(dailyStepsQuery)
        }
        
        // Start a Heart Rate WorkOut
        if let heartRateQuery = heartRateStreamingQuery(date) {
            healthKitStore.executeQuery(heartRateQuery)
        }
        
        // update components
        let dateOfBirth = getProfileDOB()!
        let calculatedAge = calculateAgeOfPerson(dateOfBirth)
        let sexType = getProfileSexType()!
        let bloodType = getProfileBloodType()!
        
        self.ageTextField.text = dateOfBirth
        self.DoBTextField.text = String(UInt16(calculatedAge!))
        self.sexTextField.text = sexType
        self.bloodTypeTextField.text = bloodType
    }
    
    func didSessionEnd(date : NSDate) {
        // Stop Heart Rate Query from Running
        if let heartRateQuery = heartRateStreamingQuery(date) {
            healthKitStore.stopQuery(heartRateQuery)
            self.heartRateLabel.text = "---"
        }
        if let dailyStepsQuery = dailyStepsStreamingQuery(date) {
            healthKitStore.stopQuery(dailyStepsQuery)
            self.stepsLabel.text = "---"
        }
    }
}