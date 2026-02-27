import Foundation
#if os(watchOS)
import WatchKit
#endif

enum HapticPlayer {
    static func playTick() {
        #if os(watchOS)
        WKInterfaceDevice.current().play(.click)
        #endif
    }

    static func playStart() {
        #if os(watchOS)
        WKInterfaceDevice.current().play(.start)
        #endif
    }
}
