//
//  CurrentLocationViewController.swift
//  MyLocations12
//
//  Created by Buck Rozelle on 12/17/20.
//

import UIKit
import CoreData
import AudioToolbox

class CurrentLocationViewController: UIViewController, CLLocationManagerDelegate, CAAnimationDelegate {
    @IBOutlet var messageLabel: UILabel!
    @IBOutlet var latitudeLabel: UILabel!
    @IBOutlet var longitudeLabel: UILabel!
    @IBOutlet var addressLabel: UILabel!
    @IBOutlet var tagButton: UIButton!
    @IBOutlet var getButton: UIButton!
    @IBOutlet var latitudeTextLabel: UILabel!
    @IBOutlet var longitudeTextLabel: UILabel!
    @IBOutlet var containerView: UIView!
    
    let locationManager = CLLocationManager()
    var location: CLLocation?
    var updatingLocation = false
    var lastLocationError: Error?
    let geocoder = CLGeocoder()
    var placemark: CLPlacemark?
    var performingReverseGeocoding = false
    var lastGeocodingError: Error?
    var timer: Timer?
    var managedObjectContext: NSManagedObjectContext!
    //Var for the logo image which is a button
    var logoVisible = false
    var soundID: SystemSoundID = 0

    lazy var logoButton: UIButton = {
      let button = UIButton(type: .custom)
      button.setBackgroundImage(
        UIImage(named: "Logo"), for: .normal)
      button.sizeToFit()
      button.addTarget(
        self, action: #selector(getLocation), for: .touchUpInside)
      button.center.x = self.view.bounds.midX
      button.center.y = 220
      return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateLabels()
        loadSoundEffect("Sound.caf")
    }
    
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
        if logoVisible {
            hideLogoView()
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
        //startLocationManager()
        updateLabels()
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
            latitudeTextLabel.isHidden = false
            longitudeTextLabel.isHidden = false
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
                statusMessage = ""
                showLogoView()
            }
            latitudeTextLabel.isHidden = true
            longitudeTextLabel.isHidden = true
        messageLabel.text = statusMessage
        }
        configureGetButton()
      }
    
    /*func configureGetButton() {
        if updatingLocation {getButton.setTitle("Stop",
                                                for: .normal)
        } else {
            getButton.setTitle("Get My Location",
                               for: .normal)
        }
}*/
    
func configureGetButton() {
      let spinnerTag = 1000
    if updatingLocation {
    getButton.setTitle("Stop",
                       for: .normal)

        if view.viewWithTag(spinnerTag) == nil {
          let spinner = UIActivityIndicatorView(style: .medium)
          spinner.center = messageLabel.center
          spinner.center.y += spinner.bounds.size.height / 2 + 25
          spinner.startAnimating()
          spinner.tag = spinnerTag
          containerView.addSubview(spinner)
        }
      } else {
        getButton.setTitle("Get My Location",
                           for: .normal)

        if let spinner = view.viewWithTag(spinnerTag) {
          spinner.removeFromSuperview()
        }
      }
    }
    
    //Starting the location manager
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
    
    func string(from placemark: CLPlacemark) -> String {
        var line1 = ""
          line1.add(text: placemark.subThoroughfare)
          line1.add(text: placemark.thoroughfare, separatedBy: " ")

          var line2 = ""
          line2.add(text: placemark.locality)
          line2.add(text: placemark.administrativeArea, separatedBy: " ")
          line2.add(text: placemark.postalCode, separatedBy: " ")

          line1.add(text: line2, separatedBy: "\n")
          return line1
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
    
    func showLogoView() {
      if !logoVisible {
        logoVisible = true
        containerView.isHidden = true
        view.addSubview(logoButton)
      }
    }
    
    func hideLogoView() {
      if !logoVisible { return }
        logoVisible = false
        containerView.isHidden = false
        containerView.center.x = view.bounds.size.width * 2
        containerView.center.y = 40 + containerView.bounds.size.height / 2
//Container view is placed outside the screen and moved to the center
        let centerX = view.bounds.midX

        let panelMover = CABasicAnimation(keyPath: "position")
        panelMover.isRemovedOnCompletion = false
        panelMover.fillMode = CAMediaTimingFillMode.forwards
        panelMover.duration = 0.6
        panelMover.fromValue = NSValue(cgPoint: containerView.center)
        panelMover.toValue = NSValue(
        cgPoint: CGPoint(x: centerX,
                         y:containerView.center.y))
        panelMover.timingFunction = CAMediaTimingFunction(
        name: CAMediaTimingFunctionName.easeOut)
        panelMover.delegate = self
        containerView.layer.add(panelMover,
                                forKey: "panelMover")
//The logo image slides out of the screen
        let logoMover = CABasicAnimation(keyPath: "position")
        logoMover.isRemovedOnCompletion = false
        logoMover.fillMode = CAMediaTimingFillMode.forwards
        logoMover.duration = 0.5
        logoMover.fromValue = NSValue(cgPoint: logoButton.center)
        logoMover.toValue = NSValue(
        cgPoint: CGPoint(x: -centerX,
                         y:logoButton.center.y))
        logoMover.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeIn)
        logoButton.layer.add(logoMover,
                             forKey: "logoMover")
//The logo image rotates around its center.
        let logoRotator = CABasicAnimation(keyPath: "transform.rotation.z")
        logoRotator.isRemovedOnCompletion = false
        logoRotator.fillMode = CAMediaTimingFillMode.forwards
        logoRotator.duration = 0.5
        logoRotator.fromValue = 0.0
        logoRotator.toValue = -2 * Double.pi
        logoRotator.timingFunction = CAMediaTimingFunction(
        name: CAMediaTimingFunctionName.easeIn)
        logoButton.layer.add(logoRotator,
                             forKey: "logoRotator")
}
    
// MARK: - Sound effects
    func loadSoundEffect(_ name: String) {
      if let path = Bundle.main.path(forResource: name,
                                     ofType: nil) {
        let fileURL = URL(fileURLWithPath: path,
                          isDirectory: false)
        let error = AudioServicesCreateSystemSoundID(fileURL as CFURL, &soundID)
        if error != kAudioServicesNoError {
          print("Error code \(error) loading sound: \(path)")
        }
      }
    }

    func unloadSoundEffect() {
      AudioServicesDisposeSystemSoundID(soundID)
      soundID = 0
    }

    func playSoundEffect() {
      AudioServicesPlaySystemSound(soundID)
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
                        if self.placemark == nil {
                            print("First Time!")
                            self.playSoundEffect()
                        }
                    self.placemark = places.last!
                  } else {
                    self.placemark = nil
                  }
                    if let places = placemarks {
                        print("*** Found Places: \(places)")
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isNavigationBarHidden = false
    }
    
// MARK: - Animation Delegate Methods
    //Cleans up the animation and removes the logo button.
    func animationDidStop(_ anim: CAAnimation,
                          finished flag: Bool) {
      containerView.layer.removeAllAnimations()
      containerView.center.x = view.bounds.size.width / 2
      containerView.center.y = 40 + containerView.bounds.size.height / 2
      logoButton.layer.removeAllAnimations()
      logoButton.removeFromSuperview()
    }
    
    //Mark:- Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "TagLocation" {
            let controller = segue.destination as! LocationDetailsViewController
            controller.coordinate = location!.coordinate
            controller.placemark = placemark
            controller.managedObjectContext = managedObjectContext
        }
    }
}

