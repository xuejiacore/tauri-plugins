import Foundation
@preconcurrency import CoreBluetooth
import Accelerate

let DeviceInformation = CBUUID(string:"180A")
let ManufacturerName = CBUUID(string:"2A29")
let ModelName = CBUUID(string:"2A24")
let ExposureNotification = CBUUID(string:"FD6F")
let HIDServiceUUID = CBUUID(string: "1812")

/// 常见 Bluetooth SIG Service UUID → 名称映射
let bluetoothServiceNames: [String: String] = [
    "1800": "Generic Access",
    "1801": "Generic Attribute",
    "1802": "Immediate Alert",
    "1803": "Link Loss",
    "1804": "Tx Power",
    "1805": "Current Time",
    "1806": "Reference Time Update",
    "1807": "Next DST Change",
    "1808": "Glucose",
    "1809": "Health Thermometer",
    "180A": "Device Information",
    "180D": "Heart Rate",
    "180E": "Phone Alert Status",
    "180F": "Battery Service",
    "1810": "Blood Pressure",
    "1811": "Alert Notification",
    "1812": "Human Interface Device",
    "1813": "Scan Parameters",
    "1814": "Running Speed and Cadence",
    "1815": "Automation IO",
    "1816": "Cycling Speed and Cadence",
    "1818": "Cycling Power",
    "1819": "Location and Navigation",
    "181A": "Environmental Sensing",
    "181B": "Body Composition",
    "181C": "User Data",
    "181D": "Weight Scale",
    "181E": "Bond Management",
    "181F": "Continuous Glucose Monitoring",
    "1820": "Internet Protocol Support",
    "1821": "Indoor Positioning",
    "1822": "Pulse Oximeter",
    "1823": "HTTP Proxy",
    "1824": "Transport Discovery",
    "1825": "Object Transfer"
]

/// 常见 Bluetooth SIG Characteristic UUID → 名称映射
let bluetoothCharacteristicNames: [String: String] = [
    // 通用
    "2A00": "Device Name",
    "2A01": "Appearance",
    "2A02": "Peripheral Privacy Flag",
    "2A03": "Reconnection Address",
    "2A04": "Peripheral Preferred Connection Parameters",
    "2A05": "Service Changed",

    // 设备信息
    "2A23": "System ID",
    "2A24": "Model Number String",
    "2A25": "Serial Number String",
    "2A26": "Firmware Revision String",
    "2A27": "Hardware Revision String",
    "2A28": "Software Revision String",
    "2A29": "Manufacturer Name String",

    // 电池
    "2A19": "Battery Level",

    // 心率
    "2A37": "Heart Rate Measurement",
    "2A38": "Body Sensor Location",
    "2A39": "Heart Rate Control Point",

    // 血压
    "2A35": "Blood Pressure Measurement",
    "2A36": "Intermediate Cuff Pressure",
    "2A49": "Blood Pressure Feature",

    // 温度
    "2A1C": "Temperature Measurement",
    "2A1D": "Temperature Type",
    "2A1E": "Intermediate Temperature",

    // 时间
    "2A2B": "Current Time",
    "2A0F": "Local Time Information",
    "2A14": "Reference Time Information",

    // 运动
    "2A53": "RSC Measurement",
    "2A54": "RSC Feature",
    "2A63": "Cycling Power Measurement",
    "2A64": "Cycling Power Vector",
    "2A65": "Cycling Power Feature",
    "2A66": "Cycling Power Control Point",

    // 健康
    "2A9D": "Weight Measurement",
    "2A9E": "Weight Scale Feature",
    "2A9F": "User Control Point",
    "2A99": "User Index",
]

func getMACFromUUID(_ uuid: String) -> String? {
    guard let plist = NSDictionary(contentsOfFile: "/Library/Preferences/com.apple.Bluetooth.plist") else { return nil }
    guard let cbcache = plist["CoreBluetoothCache"] as? NSDictionary else { return nil }
    guard let device = cbcache[uuid] as? NSDictionary else { return nil }
    return device["DeviceAddress"] as? String
}

func getNameFromMAC(_ mac: String) -> String? {
    guard let plist = NSDictionary(contentsOfFile: "/Library/Preferences/com.apple.Bluetooth.plist") else { return nil }
    guard let devcache = plist["DeviceCache"] as? NSDictionary else { return nil }
    guard let device = devcache[mac] as? NSDictionary else { return nil }
    if let name = device["Name"] as? String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if trimmed == "" { return nil }
        return trimmed
    }
    return nil
}

class Device: NSObject {
    let uuid : UUID!
    var peripheral : CBPeripheral?
    var manufacture : String?
    var model : String?
    var advData: Data?
    var rssi: Int = 0
    var scanTimer: Timer?
    var macAddr: String?
    var blName: String?
    
    func getDescription() -> String {
        
        if macAddr == nil || blName == nil {
            //            if let info = await getLEDeviceInfoFromUUID(uuid.description) {
            //                blName = info.name
            //                macAddr = info.macAddr
            //            }
        }
        if macAddr == nil {
            macAddr = getMACFromUUID(uuid.description)
        }
        if let mac = macAddr {
            if blName == nil {
                blName = getNameFromMAC(mac)
            }
            if let name = blName {
                // If it's just "iPhone" or "iPad", there's a chance we can get the model name in the following code
                if name != "iPhone" && name != "iPad" {
                    return name
                }
            }
        }
        if let manu = manufacture {
            if let mod = model {
                if manu == "Apple Inc." && appleDeviceNames[mod] != nil {
                    return appleDeviceNames[mod]!
                }
                return String(format: "%@/%@", manu, mod)
            } else {
                return manu
            }
        }
        if let name = peripheral?.name {
            if name.trimmingCharacters(in: .whitespaces).count != 0 {
                return name
            }
        }
        if let mod = model {
            return mod
        }
        // iBeacon
        if let adv = advData {
            if adv.count >= 25 {
                var iBeaconPrefix : [uint16] = [0x004c, 0x01502]
                if adv[0...3] == Data(bytes: &iBeaconPrefix, count: 4) {
                    let major = uint16(adv[20]) << 8 | uint16(adv[21])
                    let minor = uint16(adv[22]) << 8 | uint16(adv[23])
                    let tx = Int8(bitPattern: adv[24])
                    let distance = pow(10, Double(Int(tx) - rssi)/20.0)
                    let d = String(format:"%.1f", distance)
                    return "iBeacon [\(major), \(minor)] \(d)m"
                }
            }
        }
        if let name = blName {
            return name
        }
        if let mac = macAddr {
            return mac // better than uuid
        }
        return uuid.description
        
    }
    
    init(uuid _uuid: UUID) {
        uuid = _uuid
    }
}

protocol BLEDelegate {
    func newDevice(device: Device)
    func updateDevice(device: Device)
    func removeDevice(device: Device)
    func updateRSSI(rssi: Int?, estimatedRSSI: Int?, active: Bool)
    func updatePresence(presence: Bool, reason: String)
    func bluetoothPowerWarn()
}

class BLE: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    let UNLOCK_DISABLED = 1
    let LOCK_DISABLED = -100
    var centralMgr : CBCentralManager!
    var devices : [UUID : Device] = [:]
    var delegate: BLEDelegate?
    var scanMode = false
    var monitoredUUID: UUID?
    var monitoredPeripheral: CBPeripheral?
    var proximityTimer : Timer?
    var signalTimer: Timer?
    var presence = false
    var lockRSSI = -75
    var unlockRSSI = -60
    var proximityTimeout = 5.0
    var signalTimeout = 60.0
    var lastReadAt = 0.0
    var powerWarn = true
    var passiveMode = false
    var thresholdRSSI = -70
    var latestRSSIs: [Double] = []
    var latestN: Int = 5
    var activeModeTimer : Timer? = nil
    var connectionTimer : Timer? = nil
    // RSSI 样本
    private var rssiSamples: [Int] = []
    private var filteredRSSI: Double?

    // 滤波参数
    private let alpha: Double = 0.15  // EMA 平滑系数 α取值 0.1~0.3 比较常用，能平滑瞬时波动
    
    // 校准参数
    private let A: Double = -54  // 1米处 RSSI 可测量
    private let n: Double = 2.0  // 路径损耗指数 环境相关，1.6~3.5
    
    func scanForPeripherals() {
        guard !centralMgr.isScanning else { return }
        centralMgr.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        print("Start scanning")
    }
    
    func startScanning() {
        scanMode = true
        scanForPeripherals()
    }
    
    func stopScanning() {
        scanMode = false
        if activeModeTimer != nil {
            centralMgr.stopScan()
        }
    }
    
    func setPassiveMode(_ mode: Bool) {
        passiveMode = mode
        if passiveMode {
            activeModeTimer?.invalidate()
            activeModeTimer = nil
            if let p = monitoredPeripheral {
                centralMgr.cancelPeripheralConnection(p)
            }
        }
        scanForPeripherals()
    }
    
    func startMonitor(uuid: UUID) {
        if let p = monitoredPeripheral {
            centralMgr.cancelPeripheralConnection(p)
        }
        monitoredUUID = uuid
        proximityTimer?.invalidate()
        resetSignalTimer()
        presence = true
        monitoredPeripheral = nil
        activeModeTimer?.invalidate()
        activeModeTimer = nil
        scanForPeripherals()
    }
    
    func resetSignalTimer() {
        signalTimer?.invalidate()
        signalTimer = Timer.scheduledTimer(withTimeInterval: signalTimeout, repeats: false, block: { _ in
            print("Device is lost")
            self.delegate?.updateRSSI(rssi: nil, estimatedRSSI: nil, active: false)
            if self.presence {
                self.presence = false
                self.delegate?.updatePresence(presence: self.presence, reason: "lost")
            }
        })
        if let timer = signalTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Bluetooth powered on")
            if activeModeTimer == nil {
                scanForPeripherals()
            }
            powerWarn = false
        case .poweredOff:
            print("Bluetooth powered off")
            presence = false
            signalTimer?.invalidate()
            signalTimer = nil
            if powerWarn {
                powerWarn = false
                delegate?.bluetoothPowerWarn()
            }
        default:
            break
        }
    }
    
    func getEstimatedRSSI(rssi: Int) -> Int {
        if latestRSSIs.count >= latestN {
            latestRSSIs.removeFirst()
        }
        latestRSSIs.append(Double(rssi))
        var mean: Double = 0.0
        var sddev: Double = 0.0
        vDSP_normalizeD(latestRSSIs, 1, nil, 1, &mean, &sddev, vDSP_Length(latestRSSIs.count))
        return Int(mean)
    }
    
    func updateMonitoredPeripheral(_ rssi: Int) {
        // 滤波器平滑+校准环境
        handleRSSI(rssi);
        
        if rssi >= (unlockRSSI == UNLOCK_DISABLED ? lockRSSI : unlockRSSI) && !presence {
            print("Device is close")
            presence = true
            delegate?.updatePresence(presence: presence, reason: "close")
            latestRSSIs.removeAll() // Avoid bouncing
        }
        
        let estimatedRSSI = getEstimatedRSSI(rssi: rssi)
        delegate?.updateRSSI(rssi: rssi, estimatedRSSI: estimatedRSSI, active: activeModeTimer != nil)
        
        if estimatedRSSI >= (lockRSSI == LOCK_DISABLED ? unlockRSSI : lockRSSI) {
            if let timer = proximityTimer {
                timer.invalidate()
                print("Proximity timer canceled")
                proximityTimer = nil
            }
        } else if presence && proximityTimer == nil {
            proximityTimer = Timer.scheduledTimer(withTimeInterval: proximityTimeout, repeats: false, block: { _ in
                print("Device is away")
                self.presence = false
                self.delegate?.updatePresence(presence: self.presence, reason: "away")
                self.proximityTimer = nil
            })
            RunLoop.main.add(proximityTimer!, forMode: .common)
            print("Proximity timer started")
        }
        resetSignalTimer()
    }
    
    func resetScanTimer(device: Device) {
        device.scanTimer?.invalidate()
        device.scanTimer = Timer.scheduledTimer(withTimeInterval: signalTimeout, repeats: false, block: { _ in
            self.delegate?.removeDevice(device: device)
            if let p = device.peripheral {
                self.centralMgr.cancelPeripheralConnection(p)
            }
            self.devices.removeValue(forKey: device.uuid)
        })
        if let timer = device.scanTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    func connectMonitoredPeripheral() {
        guard let p = monitoredPeripheral else { return }
        
        // Idk why but this works like a charm when 'didConnect' won't get called.
        // However, this generates warnings in the log.
        p.readRSSI()
        
        guard p.state == .disconnected else { return }
        print("Connecting")
        centralMgr.connect(p, options: nil)
        connectionTimer?.invalidate()
        connectionTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: false, block: { _ in
            if p.state == .connecting {
                print("Connection timeout")
                self.centralMgr.cancelPeripheralConnection(p)
            }
        })
        RunLoop.main.add(connectionTimer!, forMode: .common)
    }
    
    //MARK:- CBCentralManagerDelegate start
    
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber)
    {
        let rssi = RSSI.intValue > 0 ? 0 : RSSI.intValue
        if let uuid = monitoredUUID {
            if peripheral.identifier.description == uuid.description {
                if monitoredPeripheral == nil {
                    monitoredPeripheral = peripheral
                }
                if activeModeTimer == nil {
                    print("Discover \(rssi)dBm")
                    updateMonitoredPeripheral(rssi)
                    if !passiveMode {
                        connectMonitoredPeripheral()
                    }
                }
            }
        }
        
        let type = detectPeripheralType(peripheral: peripheral, advertisementData: advertisementData)
        //print("设备类型: \(type)")
        
        if (scanMode) {
            if let uuids = advertisementData["kCBAdvDataServiceUUIDs"] as? [CBUUID] {
                for uuid in uuids {
                    if uuid == ExposureNotification {
                        print("Device \(peripheral.identifier) Exposure Notification")
                        return
                    }
                }
            }
            let dev = devices[peripheral.identifier]
            var device: Device
            if (dev == nil) {
                device = Device(uuid: peripheral.identifier)
                
                if (rssi >= thresholdRSSI) {
                    device.peripheral = peripheral
                    device.rssi = rssi
                    device.advData = advertisementData["kCBAdvDataManufacturerData"] as? Data
                    
                    let parsed = parseAdvertisementData(advertisementData)
                    print("发现设备: \(peripheral.identifier.uuidString)")
                    print("广播信息: \(parsed)")
        
                    
                    devices[peripheral.identifier] = device
                    central.connect(peripheral, options: nil)
                    delegate?.newDevice(device: device)
                    
                    let desc = device.getDescription()
                    //print("Device \(String(describing: device.uuid)), rssi = \(rssi) >= thresholdRSSI = \(thresholdRSSI), \(desc)")
                }
            } else {
                device = dev!
                device.rssi = rssi
                delegate?.updateDevice(device: device)
                
                let desc = device.getDescription()
                //print("Update \(String(describing: device.uuid)), rssi = \(rssi) >= thresholdRSSI = \(thresholdRSSI), \(desc)")
            }
            resetScanTimer(device: device)
        }
    }
    
    func detectPeripheralType(peripheral: CBPeripheral, advertisementData: [String: Any]) -> String {
        // 1️⃣ 检查 Service UUIDs
        if let serviceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] {
            for uuid in serviceUUIDs {
                if uuid == CBUUID(string: "1812") {
                    // HID Service 存在，进一步可在连接后读取 HID Report Map
                    return "HID Device (Keyboard/Mouse/Other)"
                }
            }
        }
        
        // 2️⃣ 根据名称做简单判断
        if let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            let lowerName = name.lowercased()
            if lowerName.contains("keyboard") {
                return "Keyboard"
            }
            if lowerName.contains("mouse") {
                return "Mouse"
            }
            
            print("未知的类型：\(lowerName) ==============================>")
        }
        
        return "Unknown"
    }
    
    /// 把 Characteristic UUID 转换为名称
    func describeCharacteristicUUID(_ uuid: CBUUID) -> String {
        let key = uuid.uuidString.uppercased()
        if let name = bluetoothCharacteristicNames[key] {
            return "\(name) (\(key))"
        }
        return key
    }

    /// 把 UUID 转换为 `名称 (UUID)` 格式
    func describeUUID(_ uuid: CBUUID) -> String {
        let key = uuid.uuidString.uppercased()
        if let name = bluetoothServiceNames[key] {
            return "\(name) (\(key))"
        }
        return key
    }

    /// 广播数据解析
    func parseAdvertisementData(_ advertisementData: [String: Any]) -> [String: Any] {
        var result: [String: Any] = [:]

        // Local Name
        if let localName = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            result["LocalName"] = localName
        }

        // Manufacturer Data
        if let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data {
            result["ManufacturerData"] = manufacturerData.map { String(format: "%02hhX", $0) }.joined()
        }

        // Service UUIDs
        if let serviceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID] {
            result["ServiceUUIDs"] = serviceUUIDs.map { describeUUID($0) }
        }

        // Solicited Service UUIDs
        if let solicitedUUIDs = advertisementData[CBAdvertisementDataSolicitedServiceUUIDsKey] as? [CBUUID] {
            result["SolicitedServiceUUIDs"] = solicitedUUIDs.map { describeUUID($0) }
        }

        // Service Data
        if let serviceData = advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data] {
            var dict: [String: String] = [:]
            for (uuid, data) in serviceData {
                dict[describeUUID(uuid)] = data.map { String(format: "%02hhX", $0) }.joined()
            }
            result["ServiceData"] = dict
        }

        // Tx Power
        if let txPower = advertisementData[CBAdvertisementDataTxPowerLevelKey] as? NSNumber {
            result["TxPowerLevel"] = txPower
        }

        // Connectable
        if let connectable = advertisementData[CBAdvertisementDataIsConnectable] as? NSNumber {
            result["IsConnectable"] = (connectable.boolValue ? "Yes" : "No")
        }

        // Overflow UUIDs
        if let overflowUUIDs = advertisementData[CBAdvertisementDataOverflowServiceUUIDsKey] as? [CBUUID] {
            result["OverflowServiceUUIDs"] = overflowUUIDs.map { describeUUID($0) }
        }

        return result
    }
    
    // MARK: - RSSI 处理
    
    private func handleRSSI(_ rssi: Int) {
        // 1. 存入样本
        rssiSamples.append(rssi)
        if rssiSamples.count > 20 {
            rssiSamples.removeFirst()
        }
        
        // 2. EMA 平滑
        let currentRSSI = Double(rssi)
        if let prev = filteredRSSI {
            filteredRSSI = alpha * currentRSSI + (1 - alpha) * prev
        } else {
            filteredRSSI = currentRSSI
        }
        
        // 3. 计算距离
        if let filtered = filteredRSSI {
            let distance = rssiToDistance(rssi: filtered)
            print(String(format: "RSSI: %d, 平滑RSSI: %.2f, 距离: %.2f m", rssi, filtered, distance))
        }
    }
    
    private func rssiToDistance(rssi: Double) -> Double {
        // RSSI = -10 * n * log10(d) + A
        // d = 10^((A - RSSI) / (10 * n))
        let exponent = (A - rssi) / (10 * n)
        return pow(10, exponent)
    }
    
    func centralManager(_ central: CBCentralManager,
                        didConnect peripheral: CBPeripheral)
    {
        peripheral.delegate = self
        if scanMode {
            peripheral.discoverServices([DeviceInformation])
        }
        if peripheral == monitoredPeripheral && !passiveMode {
            print("Connected")
            connectionTimer?.invalidate()
            connectionTimer = nil
            peripheral.readRSSI()
        }
    }
    
    //MARK:CBCentralManagerDelegate end -
    
    //MARK:- CBPeripheralDelegate start
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        guard peripheral == monitoredPeripheral else { return }
        let rssi = RSSI.intValue > 0 ? 0 : RSSI.intValue
        //print("readRSSI \(rssi)dBm")
        updateMonitoredPeripheral(rssi)
        lastReadAt = Date().timeIntervalSince1970
        
        if activeModeTimer == nil && !passiveMode {
            print("Entering active mode")
            if !scanMode {
                centralMgr.stopScan()
            }
            activeModeTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true, block: { _ in
                if Date().timeIntervalSince1970 > self.lastReadAt + 10 {
                    print("Falling back to passive mode")
                    self.centralMgr.cancelPeripheralConnection(peripheral)
                    self.activeModeTimer?.invalidate()
                    self.activeModeTimer = nil
                    self.scanForPeripherals()
                } else if peripheral.state == .connected {
                    peripheral.readRSSI()
                } else {
                    self.connectMonitoredPeripheral()
                }
            })
            RunLoop.main.add(activeModeTimer!, forMode: .common)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                if service.uuid == DeviceInformation {
                    peripheral.discoverCharacteristics([ManufacturerName, ModelName], for: service)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didDiscoverCharacteristicsFor service: CBService,
                    error: Error?)
    {
        if let chars = service.characteristics {
            for chara in chars {
                if chara.uuid == ManufacturerName || chara.uuid == ModelName {
                    peripheral.readValue(for:chara)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?)
    {
        if let value = characteristic.value {
            let str: String? = String(data: value, encoding: .utf8)
            if let s = str {
                if let device = devices[peripheral.identifier] {
                    if characteristic.uuid == ManufacturerName {
                        device.manufacture = s
                        delegate?.updateDevice(device: device)
                    }
                    if characteristic.uuid == ModelName {
                        device.model = s
                        delegate?.updateDevice(device: device)
                    }
                    if device.model != nil && device.model != nil && device.peripheral != monitoredPeripheral {
                        centralMgr.cancelPeripheralConnection(peripheral)
                    }
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didModifyServices invalidatedServices: [CBService])
    {
        peripheral.discoverServices([DeviceInformation])
    }
    //MARK:CBPeripheralDelegate end -
    
    override init() {
        super.init()
        centralMgr = CBCentralManager(delegate: self, queue: nil)
        monitoredUUID = UUID.init(uuidString: "E337A089-2E40-C91B-9153-869A90FFA727");
    }
}
