import SwiftUI
import Photos

/// A utility class to handle saving images and videos to the device's photo library.
class MediaSaver: NSObject {
    static let shared = MediaSaver()
    
    /// Saves an image to the photo library.
    func saveImage(_ image: UIImage, completion: @escaping (Bool, Error?) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized || status == .limited {
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                }) { success, error in
                    DispatchQueue.main.async {
                        completion(success, error)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completion(false, nil)
                }
            }
        }
    }
    
    /// Saves a video from a URL to the photo library.
    func saveVideo(at url: URL, completion: @escaping (Bool, Error?) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized || status == .limited {
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                }) { success, error in
                    DispatchQueue.main.async {
                        completion(success, error)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    completion(false, nil)
                }
            }
        }
    }
    
    /// Downloads a file from a URL and saves it.
    func downloadAndSaveMedia(url: URL, isVideo: Bool, completion: @escaping (Bool, Error?) -> Void) {
        URLSession.shared.downloadTask(with: url) { localURL, response, error in
            guard let localURL = localURL, error == nil else {
                completion(false, error)
                return
            }
            
            if isVideo {
                self.saveVideo(at: localURL, completion: completion)
            } else {
                if let data = try? Data(contentsOf: localURL), let image = UIImage(data: data) {
                    self.saveImage(image, completion: completion)
                } else {
                    completion(false, nil)
                }
            }
        }.resume()
    }
}
