//
//  ViewController.swift
//  PhotoPermissionSample
//
//

import UIKit
import PhotosUI

class ViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var photosLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        photosLabel.numberOfLines = 0
    }

    
    // MARK: - Actions
    @IBAction func selectPhotosTapped(_ sender: Any) {
        checkAndSelectImages()
    }
    
    func checkAndSelectImages() {
        // if user has chosen acess type already
        if PhotoManager.sharedInstance.isFirstTimePermissionGranted() {
            let permissionStatus = PhotoManager.sharedInstance.checkPhotoPermissionStatus()
            // Do something if limited access
            // Show picker to expand or change selection
            if permissionStatus == .limited {
                PhotoManager.sharedInstance.presentLimitedAccessPicker(on: self) {[weak self] assetIds in
                    guard let `self` = self else { return }
                    
                    //Fetch selected assets
                    let newAssets = PhotoManager.sharedInstance.loadRestrictedAssets(identifiers: assetIds)
                    let allAssets = PhotoManager.sharedInstance.loadRestrictedAssets()
                    
                    self.photosLabel.text = "\(newAssets.count) New Assets \n \(allAssets.count) Total Assets"
                   
                    self.dismiss(animated: true)
                }
            }
        } else {
        // if showing prompt for the first time
            PhotoManager.sharedInstance.requestPhotoPermission { [weak self] authorized in
                guard let `self` = self else { return }
                if authorized {
                    self.photosLabel.text = "Full Acess Granted"
                } else {
                    self.photosLabel.text = "Access Denied"
                }
            } limitedAccessHandler: { [weak self]  in
                guard let `self` = self else { return }
                
                // If limited acess, fetch all selected assets
                let assets = PhotoManager.sharedInstance.loadRestrictedAssets()
                self.photosLabel.text = "\(assets.count) Assets Granted"
            }
        }
    }
}

