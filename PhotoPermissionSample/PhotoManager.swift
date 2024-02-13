//
//  PhotoManager.swift
//  PhotoPermissionTest
//  by Appmetry - www.appmetry.com
//

import PhotosUI

class PhotoManager {
    var currentRestrictedAssetListener: (([String]) -> Void)? = nil
    static let sharedInstance = PhotoManager()

    // MARK: - PhotoPermissions
    
    // This app uses user defaults to know if permission has been
    // decided by the user; becuase the first time you query the PHAuthorizationStatus
    // the system shows prompt to the user, without the callback
    
    func isFirstTimePermissionGranted() -> Bool {
        return UserDefaults.standard.bool(forKey: "isFirstTimePermissionGranted")
    }
    
    func setFirstTimePermissionGranted() {
        UserDefaults.standard.set(true, forKey: "isFirstTimePermissionGranted")
    }
    
    func checkPhotoPermissionStatus() -> PHAuthorizationStatus {
        return PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }
    
    // MARK: - PhotoPermissions
    func requestPhotoPermission(_ fullAccessHandler: @escaping (Bool) -> Void, limitedAccessHandler: @escaping (() -> Void)) {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) {[weak self] status in
                print("User selected access: \(status)")
                self?.setFirstTimePermissionGranted()
                DispatchQueue.main.async {
                    switch status {
                    case .notDetermined:
                        fullAccessHandler(false)
                    case .restricted:
                        fullAccessHandler(false)
                    case .denied:
                        fullAccessHandler(false)
                    case .authorized:
                        fullAccessHandler(true)
                    case .limited:
                        limitedAccessHandler()
                    @unknown default:
                        print("Unknown Status")
                    }
                }
            }
    }
    
    // MARK: - LimitedAssets
    
    // loads assets from allowed assets using their identifiers
    func loadRestrictedAssets(identifiers: [String]) -> [PHAsset] {
        let allowedAssets = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
        let assetCount = allowedAssets.count
        var collectionAssets: [PHAsset] = []
        for i in 0..<assetCount {
            let asset = allowedAssets.object(at: i)
            collectionAssets.append(asset)
        }
        
        return collectionAssets
    }
    
    // loads all assets that can be accessed
    func loadRestrictedAssets()  -> [PHAsset] {
        let allowedAssets = PHAsset.fetchAssets(with: nil)
        let assetCount = allowedAssets.count
        var collectionAssets: [PHAsset] = []
        for i in 0..<assetCount {
            let asset = allowedAssets.object(at: i)
            collectionAssets.append(asset)
        }
        
        return collectionAssets
    }
}

// MARK: - LimitedAccessPicker
extension PhotoManager: PHPickerViewControllerDelegate {
    // A bug in iOS 17 -- presenting limited access picker can lead to a crash, if PHPickerViewControllerDelegate
    // is not used
    // (may not be needed or behave differently if future versions fix this)
    // (in that case simply use PHPhotoLibrary.shared().presentLimitedLibraryPicker(from:) )
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        let identifiers = results.map{$0.assetIdentifier ?? ""}
        self.currentRestrictedAssetListener?(identifiers)
    }
    
    
    // shows the native picker for modifying selection
    func presentLimitedAccessPicker(on vc: UIViewController, listener: (([String]) -> Void)? = nil) {
        PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: vc) {[listener] assetIds in
            listener?(assetIds)
        }
    }
    
    // In case limited access picker does not show
    // Or if you're using previous iOS versions
    func presentSimplePhotoLibrary(on vc: UIViewController, listener: (([String]) -> Void)? = nil) {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.preferredAssetRepresentationMode = .current
        configuration.selectionLimit = 0
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        self.currentRestrictedAssetListener = listener
        vc.present(picker, animated: true)
    }
}
