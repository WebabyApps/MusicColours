import Foundation
import WatchKit

enum HapticPlayer {
    static func playTick() {
        WKInterfaceDevice.current().play(.click)
    }

    static func playStart() {
        WKInterfaceDevice.current().play(.start)
    }
}
