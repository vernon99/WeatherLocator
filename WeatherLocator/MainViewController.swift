//
//  MainViewController.swift
//  WeatherLocator
//
//  Created by Mikhail Larionov on 7/29/14.
//  Copyright (c) 2014 Mikhail Larionov. All rights reserved.
//

import UIKit
import MapKit

class MainViewController: UIViewController, UITextFieldDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var cityTextField: UITextField?
    
    @IBOutlet weak var resultsCard: UIView?
    @IBOutlet weak var resultsCityName: UILabel?
    @IBOutlet weak var resultsTemperature: UILabel?
    @IBOutlet weak var resultsHumidity: UILabel?
    @IBOutlet weak var resultsPressure: UILabel?
    @IBOutlet weak var resultsMap: MKMapView?
    @IBOutlet weak var noResults: UILabel?
    
    var locationManager: CLLocationManager?
    var currentLocation: CLLocationCoordinate2D?
    var stillUpdatingLocation = false
    
    // MARK: - UIView overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager = CLLocationManager()
        locationManager!.delegate = self
        locationManager!.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        if locationManager!.respondsToSelector(Selector("requestWhenInUseAuthorization"))
        {
            locationManager!.requestWhenInUseAuthorization()
        }
    }
    
    // MARK: - CLLocationManager delegate
    func locationManager(manager:CLLocationManager, didUpdateLocations locations:[AnyObject]) {
        var locationArray = locations as NSArray
        var locationObj = locationArray.lastObject as CLLocation
        currentLocation = locationObj.coordinate
        stillUpdatingLocation = false
    }
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.AuthorizedWhenInUse
        {
            locationManager!.startUpdatingLocation()
            stillUpdatingLocation = true
        }
    }
    
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        NSLog(error.localizedDescription)
    }
    
    // MARK: - UI setup
    func loadData(weather: WeatherData?)
    {
        if let weather = weather
        {
            UIView.animateWithDuration(0.3, animations: {
                () -> Void in
                
                self.resultsCard!.alpha = 1.0
                self.noResults!.alpha = 0.0
                
                let format = ".1"
                self.resultsCityName!.text = weather.cityName
                self.resultsTemperature!.text = NSString(format:"%.1f°", weather.temperature)
                self.resultsHumidity!.text = NSString(format:"%.0f%%", weather.humidity)
                self.resultsPressure!.text = NSString(format:"%.0f hPa", weather.pressure)
                var span = MKCoordinateSpanMake(0.0, 0.1);
                self.resultsMap!.setRegion(MKCoordinateRegionMake(weather.cityGeo, span), animated: true)
                })
        }
        else
        {
            UIView.animateWithDuration(0.3, animations: {
                () -> Void in
                
                self.resultsCard!.alpha = 0.0
                self.noResults!.alpha = 1.0
                self.noResults!.text = "No results found"
                })
        }
    }
    
    // MARK: - Search requests
    @IBAction func searchForTheCityTapped(sender: AnyObject) {
        
        var cityName:String? = cityTextField?.text
        if cityName
        {
            var dataLoader = DataLoader()
            dataLoader.getDataByCity(cityName!, closure: {
                (result: WeatherData?) -> Void in
                
                // To update UI on the main thread
                dispatch_async(dispatch_get_main_queue(), {
                
                    self.loadData(result)
                })
            })
        }
    }
    
    @IBAction func searchForMyLocationTapped(sender: AnyObject) {
        
        if currentLocation
        {
            var dataLoader = DataLoader()
            dataLoader.getDataByLocation(currentLocation!.latitude, lon: currentLocation!.longitude, closure: {
                (result: WeatherData?) -> Void in
                
                // To update UI on the main thread
                dispatch_async(dispatch_get_main_queue(), {
                    
                    self.loadData(result)
                    })
                })
        }
        else
        {
            UIView.animateWithDuration(0.3, animations: {
                () -> Void in
                
                self.resultsCard!.alpha = 0.0
                self.noResults!.alpha = 1.0
                if stillUpdatingLocation
                {
                    self.noResults!.text = "Still updating geo-location"
                }
                else
                {
                    self.noResults!.text = "Geo-location is not available"
                }
                self.locationManager!.startUpdatingLocation() // Just in case
                })

        }
    }
    
    // MARK: - UITextField delegate
    func textFieldShouldReturn(textField: UITextField!) -> Bool
    {
        self.searchForTheCityTapped(cityTextField!)
        cityTextField?.resignFirstResponder()
        return true
    }
}
