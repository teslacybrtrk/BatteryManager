import Foundation

@objc protocol SMCHelperProtocol {
    func ping(reply: @escaping (Bool) -> Void)
    func getVersion(reply: @escaping (String) -> Void)
    func readBatteryChargeLevel(reply: @escaping (UInt8) -> Void)
    func setBatteryChargeLimit(_ limit: UInt8, reply: @escaping (Bool) -> Void)
    func setChargingEnabled(_ enabled: Bool, reply: @escaping (Bool) -> Void)
    func setChargeInhibit(_ inhibit: Bool, reply: @escaping (Bool) -> Void)
    func setForceCharging(_ force: Bool, reply: @escaping (Bool) -> Void)
    func readTemperatures(reply: @escaping ([Double]) -> Void)
}
