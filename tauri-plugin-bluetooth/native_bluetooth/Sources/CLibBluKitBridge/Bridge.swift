import Foundation
import CoreBluetooth

class SharedBLE {
    @MainActor static let shared = BLE();
    @MainActor static let shareDelegate = BLEDelegateImpl();
}

// MARK: - BLE Function Delegation

class BLEDelegateImpl: BLEDelegate {
    var onDeviceNew: DeviceCallback;
    var onDeviceUpdate: DeviceCallback;
    var onDeviceRemoved: DeviceCallback;
    var onRssiUpdated: RssiUpdateCallback;
    var presenceUpdated: PresenceUpdateCallback;
    var blePowerWarn: BlePowerWarnCallback;
    
    func newDevice(device: Device) {
        callDeviceCallback(device, callback: self.onDeviceNew)
    }
    
    func updateDevice(device: Device) {
        callDeviceCallback(device, callback: self.onDeviceUpdate)
    }
    
    func removeDevice(device: Device) {
        callDeviceCallback(device, callback: self.onDeviceRemoved)
    }
    
    func updateRSSI(rssi: Int?, estimatedRSSI: Int?, active: Bool) {
        let rssiValue: Int32 = rssi.map { Int32($0) } ?? 0
        let estimatedRSSIValue: Int32 = estimatedRSSI.map { Int32($0) } ?? 0
        self.onRssiUpdated(rssiValue, estimatedRSSIValue, active)
        
    }
    
    func updatePresence(presence: Bool, reason: String) {
        
    }
    
    func bluetoothPowerWarn() {
        
    }
    
    init(onDeviceNew: @escaping DeviceCallback = { _,_,_,_,_,__,_,_,_ in },
         onDeviceUpdate: @escaping DeviceCallback = { _,_,_,_,_,_,_,_,_ in },
         onDeviceRemoved: @escaping DeviceCallback = { _,_,_,_,_,_,_,_,_ in },
         onRssiUpdated: @escaping RssiUpdateCallback = { _,_,_ in },
         presenceUpdated: @escaping PresenceUpdateCallback = { _,_ in },
         bluetoothPowerWarn: @escaping BlePowerWarnCallback = { }
    ) {
        self.onDeviceNew = onDeviceNew
        self.onDeviceUpdate = onDeviceUpdate
        self.onDeviceRemoved = onDeviceRemoved
        self.onRssiUpdated = onRssiUpdated
        self.presenceUpdated = presenceUpdated
        self.blePowerWarn = bluetoothPowerWarn
    }
}

public typealias DeviceCallback = @convention(c) @Sendable (
    UnsafePointer<CChar>, // uuid
    UnsafePointer<CChar>, // manufacture
    UnsafePointer<CChar>, // model
    Int64,                // advData (as length)
    Int32,                // rssi
    UnsafePointer<CChar>, // macAddr
    UnsafePointer<CChar>, // blName
    UnsafePointer<CChar>, // name
    UnsafePointer<CChar>  // state
) -> Void;

public typealias RssiUpdateCallback = @convention(c) @Sendable (
    Int32, // rssi
    Int32, // estimatedRSSI
    Bool
) -> Void;

public typealias PresenceUpdateCallback = @convention(c) @Sendable (
    Bool,
    String
) -> Void;

public typealias BlePowerWarnCallback = @convention(c) @Sendable () -> Void;

// MARK: - Bridge Function Definition

@_cdecl("echo")
public func echo(value: UnsafePointer<CChar>) -> UnsafeMutablePointer<CChar>? {
    return strdup(value)
}

@_cdecl("initialize")
public func initialize() {
    DispatchQueue.main.async {
        SharedBLE.shared.delegate = SharedBLE.shareDelegate;
    }
}

@_cdecl("start_scanning")
public func startScanning() -> Bool {
    DispatchQueue.main.async {
        SharedBLE.shared.startScanning();
    }
    return true
}

@_cdecl("stop_scanning")
public func stopScanning() -> Bool {
    DispatchQueue.main.async{
        SharedBLE.shared.stopScanning();
    }
    return true
}

@_cdecl("set_passive_mode")
public func setPassiveMode(mode: Bool) {
    DispatchQueue.main.async {
        SharedBLE.shared.setPassiveMode(mode)
    }
}

@_cdecl("connect_device")
public func connectDevice(identifier: UnsafePointer<CChar>) -> Bool {
    guard let uuid = UUID(uuidString: String(cString: identifier)) else {return false}
    return DispatchQueue.main.sync {
        return SharedBLE.shared.connectDevice(identifier: uuid)
    }
}

@_cdecl("disconnect_device")
public func disconnectDevice(identifier: UnsafePointer<CChar>) -> Bool {
    guard let uuid = UUID(uuidString: String(cString: identifier)) else {return false}
    
    return DispatchQueue.main.sync {
        return SharedBLE.shared.disconnectDevice(identifier: uuid)
    }
}

@_cdecl("read_rssi")
public func readRssi(identifier: UnsafePointer<CChar>) -> Void {
    guard let uuid = UUID(uuidString: String(cString: identifier)) else {return}
    DispatchQueue.main.async {
        SharedBLE.shared.readRssi(identifier: uuid)
    }
}

@_cdecl("set_delegate")
public func setDelegate(onDeviceNew: DeviceCallback,
                        onDeviceUpdate: DeviceCallback,
                        onDeviceRemoved: DeviceCallback,
                        onRssiUpdated: RssiUpdateCallback,
                        presenceUpdated: PresenceUpdateCallback,
                        bluetoothPowerWarn: BlePowerWarnCallback
) {
    DispatchQueue.main.async {
        SharedBLE.shareDelegate.onDeviceNew = onDeviceNew
        SharedBLE.shareDelegate.onDeviceUpdate = onDeviceUpdate
        SharedBLE.shareDelegate.onDeviceRemoved = onDeviceRemoved
        SharedBLE.shareDelegate.onRssiUpdated = onRssiUpdated
        SharedBLE.shareDelegate.presenceUpdated = presenceUpdated
        SharedBLE.shareDelegate.blePowerWarn = bluetoothPowerWarn
    }
}

func callDeviceCallback(_ device: Device, callback: DeviceCallback) {
    // 1. UUID
    let uuidCStr = strdup(device.uuid.uuidString)
    
    // 2. manufacture
    let manufactureCStr = strdup(device.manufacture ?? "")
    
    // 3. model
    let modelCStr = strdup(device.model ?? "")
    
    // 4. advData length
    let advLength = Int64(device.advData?.count ?? 0)
    
    // 5. rssi
    let rssi = Int32(device.rssi)
    
    // 6. macAddr
    let macAddrCStr = strdup(device.macAddr ?? "")
    
    // 7. blName
    let blNameCStr = device.getDescription();
    let name = strdup(device.peripheral?.name ?? "");
    let state = peripheralStateString(device.peripheral?.state);
    
    // 调用回调
    callback(
        uuidCStr!,
        manufactureCStr!,
        modelCStr!,
        advLength,
        rssi,
        macAddrCStr!,
        blNameCStr,
        name!,
        String(describing: state)
    )
}

func peripheralStateString(_ state: CBPeripheralState?) -> String {
    switch state {
    case .disconnected: return "disconnected"
    case .connecting: return "connecting"
    case .connected: return "connected"
    case .disconnecting: return "disconnecting"
    case .none:
        return "none"
    @unknown default: return "unknown"
    }
}
