#if canImport(UIKit)
import UIKit
public typealias PlatformImage = UIImage
#elseif canImport(WatchKit)
import WatchKit
public typealias PlatformImage = UIImage
#endif
import Foundation

enum AvatarStore {
    static let customImageKey: String = "customAvatarData"

    static func saveCustomImageData(_ data: Data) {
        UserDefaults.standard.set(data, forKey: customImageKey)
    }

    static func loadCustomImage() -> PlatformImage? {
        guard let data = UserDefaults.standard.data(forKey: customImageKey),
              !data.isEmpty,
              let image = PlatformImage(data: data) else {
            return nil
        }
        return image
    }
}
