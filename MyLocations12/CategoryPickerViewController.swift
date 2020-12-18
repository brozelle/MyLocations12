//
//  CategoryPickerViewController.swift
//  MyLocations12
//
//  Created by Buck Rozelle on 12/18/20.
//

import UIKit

class CategoryPickerViewController: UITableViewController {
  var selectedCategoryName = ""

  let categories = [
    "No Category",
    "Apple Store",
    "Bar",
    "Bookstore",
    "Club",
    "Grocery Store",
    "Historic Building",
    "House",
    "Icecream Vendor",
    "Landmark",
    "Park"
  ]
// Used to get the row with a checkmark.
  var selectedIndexPath = IndexPath()

  override func viewDidLoad() {
    super.viewDidLoad()
//Loop through the array of categories for the row with a checkmark, then break out.
    for i in 0..<categories.count {
        if categories[i] == selectedCategoryName {
            selectedIndexPath = IndexPath(row: i, section: 0)
            break
          }
        }
      }
    
// MARK:- Nagivation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PickedCategory" {
            let cell = sender as! UITableViewCell
            if let indexPath = tableView.indexPath(for: cell) {
                selectedCategoryName = categories[indexPath.row]
            }
        }
    }

// MARK: - Table View Delegates
    
    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        return categories.count
      }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell",
                                                 for: indexPath)
        let categoryName = categories[indexPath.row]
        cell.textLabel!.text = categoryName

        if categoryName == selectedCategoryName {
          cell.accessoryType = .checkmark
        } else {cell.accessoryType = .none
    }
        return cell
}

    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
//Removes the checkmark from one row when another row is tapped.
        if indexPath.row != selectedIndexPath.row {
        if let newCell = tableView.cellForRow(at: indexPath) {
            newCell.accessoryType = .checkmark
    }
        if let oldCell = tableView.cellForRow(at: selectedIndexPath) {
        oldCell.accessoryType = .none
        }
        selectedIndexPath = indexPath
        }
    }
}
