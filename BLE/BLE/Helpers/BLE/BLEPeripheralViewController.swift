//
//  ViewController.swift
//  BLEProofPeripheral
//
//  Created by Alexander Lavrushko on 22/03/2021.
//

/*
 Task: Worked on one-to-one connection using random CBUUID's .
 Task: Worked on reconnecting same users from DB is they're in range.
 */

import UIKit
import CoreBluetooth

class BLEPeripheralViewController: UIViewController {

    static let shared = BLEPeripheralViewController()
    var blePeripheral: CBPeripheralManager!
    var charForIndicate: CBMutableCharacteristic?
    var subscribedCentrals = [CBCentral]()
    let timeFormatter = DateFormatter()
    var timer : Timer?
    var timeValue = 0
    var connectedState = false
    var scaningClosure: (Bool) -> Void = { value in
        
    }
    var isMessageReceived: (Bool, Data) -> Void = { (isReceived, msg) in
        
    }
    var dismissKeyboard: (Bool) -> Void = { dismiss in }
    override func viewDidLoad() {
        super.viewDidLoad()

        initBLE()
    }
  
    
    // MARK: - Timer
    func startTimer() {
        if timer == nil {
            if timeValue <= 10 {
                timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { time in
                    self.timeValue += 1
                    debugPrint("Timer peripheral => \(self.timeValue)")
                    
                    if self.timeValue > 10 {
                        BLEManager.shared.connectionState(self.connectedState)
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
        scaningClosure(connectedState)
//        scaningClosure(true)
    }

    func startAdvertising() {
        bleStartAdvertising("Test Advertising Data")
        debugPrint("Scanning started")
        self.startTimer()
    }
    // MARK: - @IBActions
     func onSwitchChangeAdvertising(_ sender: Bool) {
        if sender == true {
            bleStartAdvertising("Test Advertising Data")
            self.startTimer()
        } else {
            bleStopAdvertising()
        }
    }

    @IBAction func onTapSendIndication(_ sender: Any) {
       // bleSendIndication("Test Indicate Data")
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
extension BLEPeripheralViewController {
    func appendLog(_ message: String) {
        let logLine = "\(timeFormatter.string(from: Date())) \(message)"
        print("DEBUG: \(logLine)")
        debugPrint(message)
        updateUIStatus()
    }
    
    func updateUIStatus() {
        //        textViewStatus.text = bleGetStatusString()
        debugPrint(#function)
    }
    
    func updateUIAdvertising() {
        debugPrint("From peripheralManagerDidStartAdvertising Method, \(#function)")
    }
    
    func updateUISubscribers() {
        //        labelSubscribersCount.text = "\(subscribedCentrals.count)"
        connectedState = true
        if connectedState == true {
            self.timer?.invalidate()
            self.timer = nil
            self.timeValue = 0

            
        }
    }
}


// MARK: - BLE related methods
extension BLEPeripheralViewController: CBPeripheralManagerDelegate {

    func initBLE() {
        // using DispatchQueue.main means we can update UI directly from delegate methods
        blePeripheral = CBPeripheralManager(delegate: self, queue: DispatchQueue.main)
    }

    func isAlreadyConnected() -> Bool {
        return connectedState
    }
    
    private func buildBLEService(id: CBUUID = BLEIds.uuidService) -> CBMutableService { //CBUUID(string: uuidServiceIdentifier)

        // create characteristics
        let charForRead = CBMutableCharacteristic(type: BLEIds.uuidCharForRead,
                                                  properties: .read,
                                                  value: nil,
                                                  permissions: .readable)
        let charForWrite = CBMutableCharacteristic(type: BLEIds.uuidCharForWrite,
                                                   properties: .write,
                                                   value: nil,
                                                   permissions: .writeable)
        let charForIndicate = CBMutableCharacteristic(type: BLEIds.uuidCharForIndicate,
                                                      properties: .indicate,
                                                      value: nil,
                                                      permissions: .readable)


        // create service
        let service = CBMutableService(type: id, primary: true)
        service.characteristics = [charForRead, charForWrite, charForIndicate]
        return service
    }

    private func bleStartAdvertising(_ advertisementData: String) {
        let dictionary = [CBAdvertisementDataServiceUUIDsKey: [BLEIds.uuidService],CBAdvertisementDataLocalNameKey: advertisementData] as [String : Any]
        appendLog("startAdvertising")
        blePeripheral.startAdvertising(dictionary)
    }

    private func bleStopAdvertising() {
        appendLog("stopAdvertising")
        blePeripheral.stopAdvertising()
    }
    
    func bleSendIndication(_ valueString: Data) {
        //Ashish on 11 Sept
//        guard let charForIndicate =  cbuuidDict["charForIndicate"], !subscribedCentrals.isEmpty else {
        guard let charForIndicate = charForIndicate, !subscribedCentrals.isEmpty else {
            appendLog("cannot indicate, characteristic is nil or central not Found")
            // Alert display
            return
        }

        let result = blePeripheral.updateValue(valueString, for: charForIndicate, onSubscribedCentrals: nil)
        let resultStr = result ? "true" : "false"
        appendLog("updateValue result = '\(resultStr)' value = '\(valueString)'")
    }

    private func bleGetStatusString() -> String {
        guard let blePeripheral = blePeripheral else { return "not initialized" }
        switch blePeripheral.state {
        case .unauthorized:
            return blePeripheral.state.stringValue + " (allow in Settings)"
        case .poweredOff:
            return "Bluetooth OFF"
        case .poweredOn:
            let advertising = blePeripheral.isAdvertising ? "advertising" : "not advertising"
            return "ON, \(advertising)"
        default:
            return blePeripheral.state.stringValue
        }
    }
}

// MARK: - CBPeripheralManagerDelegate
extension BLEPeripheralViewController {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        appendLog("didUpdateState: \(peripheral.state.stringValue)")
        if peripheral.state == .poweredOn {
            appendLog("adding BLE service")
            if peripheral.authorization == .allowedAlways {
                blePeripheral.add(buildBLEService(id: BLEIds.uuidService))
            }
        } else {
            debugPrint("Please allow access to BLE peripheral")
        }
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            appendLog("didStartAdvertising: error: \(error.localizedDescription)")
        } else {
            appendLog("didStartAdvertising: success")
        }
        self.updateUIAdvertising()
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let error = error {
            appendLog("didAddService: error: \(error.localizedDescription)")
        } else {
            appendLog("didAddService: success: \(service.uuid.uuidString)")
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager,
                           central: CBCentral,
                           didSubscribeTo characteristic: CBCharacteristic) {
        appendLog("didSubscribeTo UUID: \(characteristic.uuid.uuidString)")
        if characteristic.uuid == BLEIds.uuidCharForIndicate {
            updateUISubscribers()
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager,
                           central: CBCentral,
                           didUnsubscribeFrom characteristic: CBCharacteristic) {
        appendLog("didUnsubscribeFrom UUID: \(characteristic.uuid.uuidString)")
        BLEManager.shared.connectionState(false)
        if characteristic.uuid == BLEIds.uuidCharForIndicate {
            // device disconnected.
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        var log = "didReceiveRead UUID: \(request.characteristic.uuid.uuidString)"
        log += "\noffset: \(request.offset)"
        
        switch request.characteristic.uuid {
        case BLEIds.uuidCharForRead:
            
            request.value = "Updated Request Value in peripheral".data(using: .utf8)
            
        default:
            log += "\nresponding with attributeNotFound"
            
        }
        appendLog(log)
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        var log = "didReceiveWrite requests.count = \(requests.count)"
        requests.forEach { (request) in
            log += "\nrequest.offset: \(request.offset)"
            log += "\nrequest.char.UUID: \(request.characteristic.uuid.uuidString)"
            switch request.characteristic.uuid {
            case BLEIds.uuidCharForWrite:
                //            case CBUUID(string: cbuuidDict["uuidCharForWrite"] as! String):
                let data = request.value ?? Data()
                let textValue = String(data: data, encoding: .utf8) ?? ""
                //                textFieldDataForWrite.text = textValue
                log += "\nresponding with success, value = '\(textValue)'"
            default:
                log += "\nresponding with attributeNotFound"
            }
        }
        appendLog(log)
    }
    
    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        appendLog("isReadyToUpdateSubscribers")
    }
    
    
}


