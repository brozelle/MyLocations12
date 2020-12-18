//
//  CurrentLocationViewController.swift
//  MyLocations12
//
//  Created by Buck Rozelle on 12/17/20.
//

import UIKit
import CoreLocation

class CurrentLocationViewController: UIViewController, CLLocationManagerDelegate {
    let locationManager = CLLocationManager()
    var location: CLLocation?
    var updatingLocation = false
    var lastLocationError: Error?
    let geocoder = CLGeocoder()
    var placemark: CLPlacemark?
    var performingReverseGeocoding = false
    var lastGeocodingError: Error?
    var timer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        updateLabels()
    }

    @IBOutlet var messageLabel: UILabel!
    @IBOutlet var latitudeLabel: UILabel!
    @IBOutlet var longitudeLabel: UILabel!
    @IBOutlet var addressLabel: UILabel!
    @IBOutlet var tagButton: UIButton!
    @IBOutlet var getButton: UIButton!

    // MARK: - Actions
    @IBAction func getLocation() {
        //Checks current authorization status. If not authorized, then requests "When in Use."
        //Consider using always for WWITF
        let authStatus = locationManager.authorizationStatus
        if authStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
            return
        }
        //Shows the showLocationServicesDeniedAlert if auth is restricted or denied.
        if authStatus == .denied || authStatus == .restricted {
            showLocationServicesDeniedAlert()
            return
        }
        if updatingLocation {
          stopLocationManager()
        } else {
          location = nil
          lastLocationError = nil
          placemark = nil
          lastGeocodingError = nil
          startLocationManager()
        }
        startLocationManager()
        updateLabels()
    }
    
    //MARK:- CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error: Error) {
        print("didFailWithError \(error.localizedDescription)")
        //Error handling - can't find location but will keep trying
        if (error as NSError).code == CLError.locationUnknown.rawValue {
            return
        }
        //More serious errors are stored in error.
        lastLocationError = error
        stopLocationManager()
        updateLabels()
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        let newLocation = locations.last!
        print("didUpdateLocations \(newLocation)")
        //If the location was too long, then it is a cached result.
        if newLocation.timestamp.timeIntervalSinceNow < -5 {
            return
        }
        //If the horizontal accuracy is less than zero, ignore it.
        if newLocation.horizontalAccuracy < 0 {
            return
        }
        //Calculates the distance between the new reading and the previous one.
        var distance = CLLocationDistance(Double.greatestFiniteMagnitude)
        if let location = location {
            distance = newLocation.distance(from: location)
        }
        //If the new reading more useful than the previous one, then use it.
        //If the optional is not nil, then force unwrap it.
        if location == nil || location!.horizontalAccuracy > newLocation.horizontalAccuracy {
            //clear out the old error state.
            lastLocationError = nil
            location = newLocation
            
            //If the new location's accuracy is better than the desired accuracy, then stop asking for the location.
            if newLocation.horizontalAccuracy <= locationManager.desiredAccuracy {
                //Forces a reverse geocoding for final location when app is performin another geo request.
                if distance > 0 {
                    performingReverseGeocoding = false
                }
                print("***We're done!***")
                stopLocationManager()
            }
            updateLabels()
            
            if !performingReverseGeocoding {
                print("*** Going to geocode")
                performingReverseGeocoding = true
                //Closure performed after CLGeocoder finds an address or encounters an error.
                geocoder.reverseGeocodeLocation(newLocation)
                {placemarks, error in
                    //Handle reverse geocode errors
                    self.lastGeocodingError = error
                    if error == nil, let places = placemarks, !places.isEmpty {
                    self.placemark = places.last!
                  } else {
                    self.placemark = nil
                  }
                  self.performingReverseGeocoding = false
                  self.updateLabels()
                }
            }
        //If coord is not sign dif from prev reading and more than 10 sec stop.
        } else if distance < 1 {
            let timeInterval = newLocation.timestamp.timeIntervalSince(location!.timestamp)
            if timeInterval > 10 {
                print("*** Force Done!")
                stopLocationManager()
                updateLabels()
            }
        }
    }
    
    func updateLabels() {
        if let location = location {
            //%.8f takes a decimal number and puts it into a string.
            latitudeLabel.text = String(format: "%.8f",
                                        location.coordinate.latitude)
        longitudeLabel.text = String(format: "%.8f",
                                     location.coordinate.longitude)
        tagButton.isHidden = false
        messageLabel.text = ""
            if let placemark = placemark {
                addressLabel.text = string(from: placemark)
                } else if performingReverseGeocoding {
                  addressLabel.text = "Searching for Address..."
                } else if lastGeocodingError != nil {
                    addressLabel.text = "Error Finding Address"
                } else {
                    addressLabel.text = "No Address Found"
                }
        } else {
        latitudeLabel.text = ""
        longitudeLabel.text = ""
        addressLabel.text = ""
        tagButton.isHidden = true
        //messageLabel.text = "Tap 'Get My Location' to Start"
        
        let statusMessage: String
        if let error = lastLocationError as NSError? {
            if error.domain == kCLErrorDomain && error.code == CLError.denied.rawValue {
                statusMessage = "Location Services Disabled"
            } else {
                statusMessage = "Error in Getting Location"
            }
            } else if !CLLocationManager.locationServicesEnabled() {
                statusMessage = "Location Services Disabled"
            } else if updatingLocation {
                statusMessage = "Searching..."
            } else {
                statusMessage = "Tap 'Get My Location' to Start"
            }
        messageLabel.text = statusMessage
        }
        configureGetButton()
      }
    
    //MARK:- Helper Methods
    //Handles location permission error
    func showLocationServicesDeniedAlert() {
        let alert = UIAlertController(title: "Location Services Disabled",
                                      message: "Please enable location services for this app in Settings.",
                                      preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK",
                                     style: .default,
                                     handler: nil)
        alert.addAction(okAction)
        present(alert,
                animated: true,
                completion: nil)
    }
    
    //Starting the locatin manager
    func startLocationManager() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
            updatingLocation = true
            //Sends a timeout message to self after 60 seconds.
            timer = Timer.scheduledTimer(timeInterval: 60,
                                         target: self,
                                         selector: #selector(didTimeOut),
                                         userInfo: nil,
                                         repeats: false)
        }
    }
    
    //Tells location manager to stop if no location is found.
    func stopLocationManager(){
        if updatingLocation {
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil
            updatingLocation = false
            //Cancels timer if location manager is stopped before 60 secs.
            if let timer = timer {
                timer.invalidate()
            }
        }
    }
    
    func configureGetButton() {
    if updatingLocation {
    getButton.setTitle("Stop",
                        for: .normal)
} else {
getButton.setTitle("Get My Location",
                    for: .normal)
}
    
}
    
    func string(from placemark: CLPlacemark) -> String {
        //Create string variable for first line of address
        var line1 = ""
        //If subThoroughfare, then add
        if let tmp = placemark.subThoroughfare {
            line1 += tmp + ""
        }
        //If Street name, then add
        if let tmp = placemark.thoroughfare {
            line1 += tmp
        }
        //If city, then add.
        var line2 = ""
        if let tmp = placemark.locality {
            line2 += tmp + " "
        }
        if let tmp = placemark.postalCode {
            line2 += tmp
        }
        //Concatenated teh lines and return.
        return line1 + "\n" + line2
    }
    
    //Creats an error object
    @objc func didTimeOut() {
        print("*** Time Out")
        if location == nil {
            stopLocationManager()
            lastLocationError = NSError(domain: "MyLocations12ErrorDomain",
                                        code: 1,
                                        userInfo: nil)
            updateLabels()
        }
    }
}

