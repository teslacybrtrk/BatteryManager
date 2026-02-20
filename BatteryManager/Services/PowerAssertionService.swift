import Foundation
import IOKit.pwr_mgt

final class PowerAssertionService {
    private var assertionID: IOPMAssertionID = 0
    private var isAsserted: Bool = false

    func preventSleep(reason: String) {
        guard !isAsserted else { return }
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypeNoIdleSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason as CFString,
            &assertionID
        )
        isAsserted = (result == kIOReturnSuccess)
    }

    func allowSleep() {
        guard isAsserted else { return }
        IOPMAssertionRelease(assertionID)
        isAsserted = false
        assertionID = 0
    }

    deinit {
        allowSleep()
    }
}
