import Foundation
import os

/// Locks the Mac like ⌃⌘Q, through `SACLockScreenImmediate` from the private `login.framework` (ADR 0024).
enum ScreenLock {
    private static let logger = Logger(subsystem: "dev.guilhermemendes.CineKit", category: "ScreenLock")

    static func lock() {
        guard let handle = dlopen("/System/Library/PrivateFrameworks/login.framework/login", RTLD_LAZY),
              let symbol = dlsym(handle, "SACLockScreenImmediate") else {
            logger.error("SACLockScreenImmediate not found")
            return
        }
        let lockScreen = unsafeBitCast(symbol, to: (@convention(c) () -> Int32).self)
        let status = lockScreen()
        if status != 0 {
            logger.error("SACLockScreenImmediate failed: \(status)")
        }
    }
}
