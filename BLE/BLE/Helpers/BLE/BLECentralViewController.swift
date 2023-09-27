//
//  ViewController.swift
//  BLEProofCentral
//
//  Created by Alexander Lavrushko on 22/03/2021.
//

import UIKit
import CoreBluetooth

class BLECentralViewController: UIViewController {
    var bleCentral: CBCentralManager!
    var connectedPeripheral: CBPeripheral?
    var timer : Timer?
    var timeValue = 0
    
    enum BLELifecycleState: String {
        case bluetoothNotReady
        case disconnected
        case scanning
        case connecting
        case connectedDiscovering
        case connected
    }
    
    var lifecycleState = BLELifecycleState.bluetoothNotReady {
        didSet {
            guard lifecycleState != oldValue else { return }
            appendLog("state = \(lifecycleState)")
            if oldValue == .connected {
                //                labelSubscription.text = "Not subscribed"
            }
        }
    }
    var scaningClosure: (Bool) -> Void = { value in
        
    }
    var isMessageReceived: (Bool, Data) -> Void = { (isReceived, msg) in
        
    }
    
    var isSaveData: (Bool) -> Void = { isSaveNow in
        
    }
    // Closure to ensure connection state to enable or disable the refresh button state on oneToOneChatVC.
    var connectionState: (Bool) -> Void = { isConnected in
        
    }
    
    let timeFormatter = DateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initBLE()
        
    }
    
    deinit {
        timer?.invalidate()
        timer = nil
    }
    
    
    // MARK: - Timer
    func startTimer() {
        if timer == nil {
            if timeValue <= 10 {
                timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { time in
                    self.timeValue += 1
                    debugPrint("Timer central => \(self.timeValue)")
                    if self.timeValue > 10 {
                        BLEManager.shared.connectionState(self.connectedPeripheral?.state == .connected)
                        self.invalidateTimer()
                    }
                })
            }
        }
    }
    
    func invalidateTimer() {
        timer?.invalidate()
        timer = nil
        timeValue = 0
        debugPrint("connectedPeripheral?.state",connectedPeripheral?.state == .connected)
        scaningClosure(connectedPeripheral?.state == .connected)
        //        scaningClosure(true)
    }
    func isAlreadyConnected() -> Bool {
        switch connectedPeripheral?.state {
        case .connected: return true
        default: return false
        }
    }
    
    func onChangeSwitchConnect(_ sender: Bool) {
        bleRestartLifecycle()
    }
    
    @IBAction func onTapReadCharacteristic(_ sender: Any) {
        bleReadCharacteristic(uuid: BLEIds.uuidCharForRead)
    }
    
    @IBAction func onTapWriteCharacteristic(_ sender: Any) {
        //        let text = textFieldDataForWrite.text ?? ""
        //        appendLog("writing '\(text)'")
        let data = "onTapWriteCharacteristic".data(using: .utf8) ?? Data()
        debugPrint("data", data)
    }
    
    @IBAction func onTapOpenSettings(_ sender: Any) {
        let settingsUrl = URL(string: UIApplication.openSettingsURLString)!
        UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
    }
    
    @IBAction func onTapClearLog(_ sender: Any) {
        //        textViewLog.text = "Logs:"
        appendLog("log cleared")
    }
}

// MARK: - UI related methods
extension BLECentralViewController {
    func appendLog(_ message: String) {
        let logLine = "\(timeFormatter.string(from: Date())) \(message)"
        print("DEBUG: \(logLine)")
        debugPrint(#function)
        debugPrint(message)
    }
    
    func updateUIStatus() {
        debugPrint("connectedPeripheral => \(String(describing: connectedPeripheral))")
        debugPrint("Central => \(String(describing: bleCentral))")
    }
    
    var userWantsToScanAndConnect: Bool {
        true
    }
}


// MARK: - BLE related methods
extension BLECentralViewController: CBCentralManagerDelegate {
    func initBLE() {
        // using DispatchQueue.main means we can update UI directly from delegate methods
        bleCentral = CBCentralManager(delegate: self, queue: DispatchQueue.main)
    }
    
    func bleRestartLifecycle() {
        guard bleCentral.state == .poweredOn else {
            connectedPeripheral = nil
            lifecycleState = .bluetoothNotReady
            return
        }
        
        if userWantsToScanAndConnect {
            if let oldPeripheral = connectedPeripheral {
                bleCentral.cancelPeripheralConnection(oldPeripheral)
            }
            connectedPeripheral = nil
            bleScan()
        } else {
            bleDisconnect()
        }
    }
    
    func bleScan() {
        bleCentral.scanForPeripherals(withServices: [BLEIds.uuidService], options: nil)
        debugPrint("Scanning started.")
        self.startTimer()
    }
    
    func bleConnect(to peripheral: CBPeripheral) {
        connectedPeripheral = peripheral
        lifecycleState = .connecting
        bleCentral.connect(peripheral, options: nil)
    }
    
    func bleDisconnect() {
        guard bleCentral != nil else {
            self.initBLE()
            self.bleDisconnect()
            return }
        if bleCentral.isScanning {
            bleCentral.stopScan()
        }
        if let peripheral = connectedPeripheral {
            bleCentral.cancelPeripheralConnection(peripheral)
        }
        lifecycleState = .disconnected
    }
    
    func bleReadCharacteristic(uuid: CBUUID) {
        guard let characteristic = getCharacteristic(uuid: uuid) else {
            appendLog("ERROR: read failed, characteristic unavailable, uuid = \(uuid.uuidString)")
            return
        }
        connectedPeripheral?.readValue(for: characteristic)
    }
    
    func bleWriteCharacteristic(uuid: CBUUID, data: Data) {
        guard let characteristic = getCharacteristic(uuid: uuid) else {
            appendLog("ERROR: write failed, characteristic unavailable, uuid = \(uuid.uuidString)")
            return
        }
        connectedPeripheral?.writeValue(data, for: characteristic, type: .withResponse)
    }
    
    func getCharacteristic(uuid: CBUUID) -> CBCharacteristic? {
        guard let service = connectedPeripheral?.services?.first(where: { $0.uuid == BLEIds.uuidService }) else {
            appendLog(" connectedPeripheral or services not available, uuid = \(uuid.uuidString)")
            // display Alert.
            return nil
        }
        return service.characteristics?.first { $0.uuid == uuid }
    }
    
    private func bleGetStatusString() -> String {
        guard let bleCentral = bleCentral else { return "not initialized" }
        switch bleCentral.state {
        case .unauthorized:
            return bleCentral.state.stringValue + " (allow in Settings)"
        case .poweredOff:
            return "Bluetooth OFF"
        case .poweredOn:
            return "ON, \(lifecycleState)"
        default:
            return bleCentral.state.stringValue
        }
    }
    
    func sendAcknowledgementOfMessageReceived() {
        let ackData = "Ack_MessageReceived".data(using: .utf8)!
        debugPrint("Acknowledgement to sender", ackData)
    }
}

// MARK: - CBCentralManagerDelegate
extension BLECentralViewController {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        appendLog("central didUpdateState: \(central.state.stringValue)")
        if central.authorization == .allowedAlways {
            self.bleRestartLifecycle()
        } else {
            debugPrint("please allow access to BLE central")
        }
    }
    
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        appendLog("didDiscover {name = \(peripheral)}")
        
        guard connectedPeripheral == nil else {
            appendLog("didDiscover ignored (connectedPeripheral already set)")
            return
        }
        //        let data = DBManager.shared.readDataFromDB(model: AddedContactsListDBModel())
        //        if let d = data.first(where: {$0.bleIdentifier == peripheral.identifier.uuidString}) {
        //            user = d
        //        }
        bleCentral.stopScan()
        /*let users = DBManager.shared.readDataFromDB(model: AddedContactsListDBModel())
         for user in users {
         let uuid = UUID(uuidString: user.bleIdentifier ?? "") ?? UUID()
         self.retrievePeripherals(withIdentifiers: [uuid])
         }*/
        bleConnect(to: peripheral)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        appendLog("didConnect")
        
        lifecycleState = .connectedDiscovering
        self.invalidateTimer()
        peripheral.delegate = self
        peripheral.discoverServices([BLEIds.uuidService])
        if peripheral.state == .connected {
            // do what you want after building connection.
        }
    }
    
    
    func retrievePeripherals(withIdentifiers identifiers: [UUID]) -> [CBPeripheral] {
        let data = self.bleCentral.retrievePeripherals(withIdentifiers: identifiers)
        
        print("Data retrieved: \(data)")
        for peripheral in data as [CBPeripheral] {
            print("Peripheral : \(peripheral)")
            peripheral.delegate = self
            bleCentral.connect(peripheral, options: nil)
        }
        return data
    }
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if peripheral === connectedPeripheral {
            appendLog("didFailToConnect")
            self.connectionState(false)
            connectedPeripheral = nil
            bleRestartLifecycle()
        } else {
            appendLog("didFailToConnect, unknown peripheral, ingoring")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        debugPrint("didDisconnectPeripheral: \(peripheral)")
        if peripheral === connectedPeripheral {
            appendLog("didDisconnect")
            //            self.connectionState(false)
            BLEManager.shared.connectionState(false)
            connectedPeripheral = nil
            //            DispatchQueue.main.asyncAfter(deadline: .now()+5.0){
            self.bleRestartLifecycle()
            //            }
        } else {
            appendLog("didDisconnect, unknown peripheral, ingoring")
        }
    }
}

extension BLECentralViewController: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        let service = peripheral.services?.first(where: { $0.uuid == BLEIds.uuidService })
        peripheral.discoverCharacteristics([BLEIds.uuidCharForRead, BLEIds.uuidCharForWrite, BLEIds.uuidCharForIndicate], for: service!)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        appendLog("didModifyServices")
        // usually this method is called when Android application is terminated
        if let _ = invalidatedServices.first(where: { $0.uuid == BLEIds.uuidService }) {
            appendLog("disconnecting because peripheral removed the required service")
            bleCentral.cancelPeripheralConnection(peripheral)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        appendLog("didDiscoverCharacteristics \(error == nil ? "OK" : "error: \(String(describing: error))")")
        
        if let charIndicate = service.characteristics?.first(where: { $0.uuid == BLEIds.uuidCharForIndicate }) {
            peripheral.setNotifyValue(true, for: charIndicate)
        } else {
            appendLog("WARN: characteristic for indication not found")
            lifecycleState = .connected
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            appendLog("didUpdateValue error: \(String(describing: error))")
            return
        }
        
        let data = characteristic.value ?? Data()
        let stringValue = String(data: data, encoding: .utf8) ?? ""
        if characteristic.uuid == BLEIds.uuidCharForRead {
            // Reading from other device.
        } else if characteristic.uuid == BLEIds.uuidCharForIndicate {
            // writing to other device.
        }
        appendLog("didUpdateValue '\(stringValue)'")
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didWriteValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        appendLog("didWrite \(error == nil ? "OK" : "error: \(String(describing: error))")")
    }
    
    func peripheral(_ peripheral: CBPeripheral,
                    didUpdateNotificationStateFor characteristic: CBCharacteristic,
                    error: Error?) {
        guard error == nil else {
            appendLog("didUpdateNotificationState error\n\(String(describing: error))")
            lifecycleState = .connected
            return
        }
        
        if characteristic.uuid == BLEIds.uuidCharForIndicate {
            let info = characteristic.isNotifying ? "Subscribed" : "Not subscribed"
            //            labelSubscription.text = info
            appendLog(info)
        }
        lifecycleState = .connected
    }
}

// MARK: - Other extensions
extension CBManagerState {
    var stringValue: String {
        switch self {
        case .unknown: return "unknown"
        case .resetting: return "resetting"
        case .unsupported: return "unsupported"
        case .unauthorized: return "unauthorized"
        case .poweredOff: return "poweredOff"
        case .poweredOn: return "poweredOn"
        @unknown default: return "\(rawValue)"
        }
    }
}

