//
//  DataLoader.swift
//  WeatherLocator
//
//  Created by Mikhail Larionov on 7/29/14.
//  Copyright (c) 2014 Mikhail Larionov. All rights reserved.
//

import Foundation
import MapKit

struct WeatherData
{
    var cityName: String
    var cityGeo: CLLocationCoordinate2D
    var temperature: Float // C
    var humidity: Float // %
    var pressure: Float // hPa
    
    init(data: NSDictionary) {
        
        cityName = data["name"] as String
        
        let coord: NSDictionary = data["coord"] as NSDictionary
        cityGeo = CLLocationCoordinate2DMake(coord["lat"].doubleValue, coord["lon"].doubleValue)
        
        let main:NSDictionary = data["main"] as NSDictionary
        temperature = main["temp"].floatValue - 273.15 // to convert from Kelvin to Celcius
        humidity = main["humidity"].floatValue
        pressure = main["pressure"].floatValue
    }
}

class DataLoader {
    
    let apiKey = "4f62abb283ead7e46e4ffa41d7fc0c7c"
    
    var requestData: NSMutableData? = nil
    var isLoading: Bool = false
    
    private func loadData(query: String, closure: ((json: NSDictionary?) -> Void) ) {
        isLoading = true
        let endpoint = "http://api.openweathermap.org"
        let path = "/data/2.5/weather?" + query.stringByReplacingOccurrencesOfString(" ", withString: "-")
        
        // Create request
        let url = NSURL(string: endpoint + path)
        var request = NSMutableURLRequest(URL: url)
        
        // Start session
        var session = NSURLSession.sharedSession()
        var task = session.dataTaskWithRequest(request, completionHandler:{
            data, response, error -> Void in
            
            if let data:NSData = data {
                
                // Create string and dictionary from NSData
                var dataString = NSString(data: data, encoding: NSUTF8StringEncoding)
                if dataString.length > 0
                {
                    NSLog("Data: \(dataString).")
                    
                    var err: NSError?
                    var jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &err) as NSDictionary
                    if let error = err {
                        NSLog("Error: \(error.localizedDescription)")
                    }
                    else {
                        
                        if jsonResult["message"]
                        {
                            NSLog(jsonResult["message"] as String)
                        }
                        else
                        {
                            closure(json: jsonResult)
                            return
                        }
                    }
                }
            }
            
            closure(json: nil)
            })
        
        task.resume()
    }
    
    func getDataByCity(city: String, closure: (weather: WeatherData?) -> Void)
    {
        // Example: http://api.openweathermap.org/data/2.5/weather?q=London
        self.loadData("q=\(city)", closure: {
            (json: NSDictionary?) -> Void in
            
            var result:WeatherData?
            if let weatherData = json
            {
                result = WeatherData(data: weatherData)
            }
            closure(weather: result)
        })
    }
    
    func getDataByLocation(lat: CLLocationDegrees, lon: CLLocationDegrees, closure: (weather: WeatherData?) -> Void)
    {
        // Example: http://api.openweathermap.org/data/2.5/weather?lat=35&lon=139
        self.loadData("lat=\(lat)&lon=\(lon)", closure: {
            (json: NSDictionary?) -> Void in
            
            var result:WeatherData?
            if let weatherData = json
            {
                result = WeatherData(data: weatherData)
            }
            closure(weather: result)
        })
    }
}