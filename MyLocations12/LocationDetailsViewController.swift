//
//  LocationDetailsViewController.swift
//  MyLocations12
//
//  Created by Buck Rozelle on 12/17/20.
//

import UIKit
import CoreLocation
import CoreData

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}()

class LocationDetailsViewController: UITableViewController {
    
    @IBOutlet var descriptionTextView: UITextView!
    @IBOutlet var categoryLabel: UILabel!
    @IBOutlet var latitudeLabel: UILabel!
    @IBOutlet var longitudeLabel: UILabel!
    @IBOutlet var addressLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var addPhotoLabel: UILabel!
    @IBOutlet weak var imageHeight: NSLayoutConstraint!
    
    var coordinate = CLLocationCoordinate2D (latitude: 0,
                                              longitude: 0)
    var placemark: CLPlacemark?
    var categoryName = "No Category"
    var managedObjectContext: NSManagedObjectContext!
    var date = Date()
    var locationToEdit: Location? {
      didSet {
        if let location = locationToEdit {
          descriptionText = location.locationDescription
          categoryName = location.category
          date = location.date
          coordinate = CLLocationCoordinate2DMake(
            location.latitude,
            location.longitude)
          placemark = location.placemark
        }
      }
    }
    var descriptionText = ""
    var image: UIImage?
    var observer: Any!
    
    deinit {
        print("*** deinit \(self)")
        NotificationCenter.default.removeObserver(observer!)
    }


  // MARK: - Actions
    @IBAction func done() {
      guard let mainView = navigationController?.parent?.view
      else { return }
      let hudView = HudView.hud(inView: mainView,
                                animated: true)
      //hudView.text = "Tagged"
    let location: Location
          if let temp = locationToEdit {
            hudView.text = "Updated"
            location = temp
          } else {
            hudView.text = "Tagged"
            location = Location(context: managedObjectContext)
            location.photoID = nil
          }
        
        // Create a new location instance
        location.locationDescription = descriptionTextView.text
      // set the location properties
      location.locationDescription = descriptionTextView.text
      location.category = categoryName
      location.latitude = coordinate.latitude
      location.longitude = coordinate.longitude
      location.date = date
      location.placemark = placemark
        
//Save Image
    if let image = image {
          //Get a new ID and assign it to the Locatoion's photoID property
          if !location.hasPhoto {
            location.photoID = Location.nextPhotoID() as NSNumber
          }
          //Converts the image to jpg.
          if let data = image.jpegData(compressionQuality: 0.5) {
            //Saves the data object
            do {
              try data.write(to: location.photoURL, options: .atomic)
            } catch {
              print("Error writing file: \(error)")
            }
          }
        }
        
// takes the objects from the context and permanently writes them to the data store.
      do {
        try managedObjectContext.save()
        afterDelay(0.6) {hudView.hide()
            self.navigationController?.popViewController(
              animated: true)
          }
        } catch {
          // Output the error and terminate the app
          fatalCoreDataError(error)
        }
      }
    
    @IBAction func cancel() {
        navigationController?.popViewController(animated: true)
  }
    
    @IBAction func categoryPickerDidPickCategory (_ segue: UIStoryboardSegue) {
        let controller = segue.source as! CategoryPickerViewController
        categoryName = controller.selectedCategoryName
        categoryLabel.text = categoryName
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let location = locationToEdit {
            title = "Edit Location"
//If the Location has a photo, show it in the photo cell.
            if location.hasPhoto {
                if let theImage = location.photoImage{
                    show(image: theImage)
                }
            }
          }
        descriptionTextView.text = descriptionText
        categoryLabel.text = categoryName
        
        latitudeLabel.text = String(format: "%.8f",
                                    coordinate.latitude)
        longitudeLabel.text = String(format: "%.8f",
                                     coordinate.longitude)
        if let placemark = placemark {
            addressLabel.text = string(from: placemark)
        } else {
            addressLabel.text = "No Address Found"
        }
        dateLabel.text = format(date: date)
        listenForBackgroundNotification()
// Hide keyboard
        let gestureRecognizer = UITapGestureRecognizer(target: self,
                                                       action: #selector(hideKeyboard))
        gestureRecognizer.cancelsTouchesInView = false
        tableView.addGestureRecognizer(gestureRecognizer)
    }
    
    //MARK:- Helper Methods
    func string(from placemark: CLPlacemark) -> String {
        var text = ""
        if let tmp = placemark.subThoroughfare {
            text += tmp + " "
        }
        if let tmp = placemark.thoroughfare {
            text += tmp + ", "
        }
        if let tmp = placemark.locality {
            text += tmp + ", "
        }
        if let tmp = placemark.administrativeArea {
            text += tmp + " "
        }
        if let tmp = placemark.postalCode {
            text += tmp + ", "
        }
        if let tmp = placemark.country {
            text += tmp
        }
        return text
    }
    
    func format(date: Date) -> String {
        return dateFormatter.string(from: date)
    }
    
    @objc func hideKeyboard(_ gestureRecognizer: UIGestureRecognizer) {
      let point = gestureRecognizer.location(in: tableView)
      let indexPath = tableView.indexPathForRow(at: point)

      if indexPath != nil && indexPath!.section == 0 &&
      indexPath!.row == 0 {
        return
      }
      descriptionTextView.resignFirstResponder()
    }
    
    func show(image: UIImage) {
        imageView.image = image
        imageView.isHidden = false
        addPhotoLabel.text = ""
        imageHeight.constant = 260
        tableView.reloadData()
    }
//If the image picker is open and user presses the home button, the LocationDetailViewController is shown when the app is active.
    func listenForBackgroundNotification() {
      observer = NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification,
                                             object: nil,
                                             queue: OperationQueue.main) { [weak self] _ in
        if let weakSelf = self {
            if weakSelf.presentedViewController != nil {
                weakSelf.dismiss(animated: false,
                                 completion: nil)
            }
            weakSelf.descriptionTextView.resignFirstResponder()
        }
       /* if self.presentedViewController != nil {
          self.dismiss(animated: false,
                       completion: nil)
        }
        //self.descriptionTextView.resignFirstResponder()*/
      }
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue,
                          sender: Any?) {
      if segue.identifier == "PickCategory" {
        let controller = segue.destination as! CategoryPickerViewController
        controller.selectedCategoryName = categoryName
      }
    }
    
    // MARK: - Table View Delegates
    override func tableView(_ tableView: UITableView,
                            willSelectRowAt indexPath: IndexPath) -> IndexPath? {
    //Limits taps to just the cells from the first two sections
      if indexPath.section == 0 || indexPath.section == 1 {
        return indexPath
      } else {
        return nil
      }
    }

    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
    //Handles the actual taps on the rows.
      if indexPath.section == 0 && indexPath.row == 0 {
        descriptionTextView.becomeFirstResponder()
      } else if indexPath.section == 1 && indexPath.row == 0 {
        //takePhotoWithCamera()
        //choosePhotoFromLibrary()
        tableView.deselectRow(at: indexPath, animated: true)
        pickPhoto()
      }
    }
}

extension LocationDetailsViewController: UIImagePickerControllerDelegate,
  UINavigationControllerDelegate {
    
// MARK: - Image Helper Methods
  func takePhotoWithCamera() {
    let imagePicker = UIImagePickerController()
    imagePicker.sourceType = .camera
    imagePicker.delegate = self
    imagePicker.allowsEditing = true
    present(imagePicker, animated: true,
            completion: nil)
  }
    
func choosePhotoFromLibrary() {
      let imagePicker = UIImagePickerController()
      imagePicker.sourceType = .photoLibrary
      imagePicker.delegate = self
      imagePicker.allowsEditing = true
      present(imagePicker, animated: true, completion: nil)
    }
    
//Creates/Displays action sheet.
    func pickPhoto() {
        //Insert before running on iPhone if UIImagePickerController.isSourceTypeAvailable(.camera) {
        //take out when deploying for iPhone.
        if true || UIImagePickerController.isSourceTypeAvailable(.camera) {
        showPhotoMenu()
      } else {
        choosePhotoFromLibrary()
      }
    }

    func showPhotoMenu() {
      let alert = UIAlertController(title: nil,
                                    message: nil,
                                    preferredStyle: .actionSheet)

      let actCancel = UIAlertAction(title: "Cancel",
                                    style: .cancel,
                                    handler: nil)
      alert.addAction(actCancel)

      let actPhoto = UIAlertAction(title: "Take Photo",
                                   style: .default) { _ in self.takePhotoWithCamera()
      }
      alert.addAction(actPhoto)

      let actLibrary = UIAlertAction(title: "Choose From Library",
                                     style: .default) { _ in self.choosePhotoFromLibrary()
        
      }
        
      alert.addAction(actLibrary)
        
        present(alert, animated: true,
                completion: nil)
        }
    
// MARK: - Image Picker Delegates
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
          image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage
          if let theImage = image {
            show(image: theImage)
          }
//Makes the cancel and done button on the image selection work.
        dismiss(animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
      dismiss(animated: true, completion: nil)
    }
}

