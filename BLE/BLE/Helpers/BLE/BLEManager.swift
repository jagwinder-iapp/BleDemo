//
//  BLEManager.swift
//  Briar
//
//  Created by iapp on 23/08/23.
//

import Foundation
import CoreBluetooth
import UIKit

var isSentMedia = false
var dictForRealmObj : [String: Any] = [:]

enum BLERoles {
    case peripheral
    case central
    
    var strings: String {
        switch self {
        case .peripheral: return "peripheral"
        case .central: return "central"
        }
    }
}


class BLEManager {
    // MARK: - local variable
    
    // singleton
    static let shared = BLEManager()
    
    // class objects
    let centralObj = BLECentralViewController()
    let peripheralObj = BLEPeripheralViewController()
    
    var bleCentral: CBCentral?
    var blePeripheral: CBPeripheral?
    // variables.
    var finalRole = ""
    var isImageSent = false
    // closure
    var sendReceivedMessageToCentroller : (Bool, Data) -> Void = { (isSent,msg) in }
    var connectionState: (Bool) -> Void = { isConnected in }
    var dismissKeyboard: (Bool) -> Void = {isDismissed in}
    init() {
        self.checkForConnection()
    }
    
    // MARK: - custom methods
    
    // scan for central and peripheral using randomised roles.
    func startScaning() {
        var role = getRandomizedRoles()
        
        // finalRole is using in One-to-One chat VC.
        finalRole = role
        
        if role == BLERoles.central.strings {
            self.centralObj.initBLE()
            //            self.centralObj.bleScan()
            self.centralObj.scaningClosure = { state in
                if !state {
                    role = self.getRandomizedRoles()
                    // make this function recursive until connection is build between 2 devices.
                    self.startScaning()
                    
                } else {
                    // done.
                    debugPrint("Dict after connected \(dictForRealmObj)") //self.dictForRealmObj["userName"] as? String ?? ""
                }
            }
            self.receiveMessage()
        } else {
            peripheralObj.initBLE()
            //            peripheralObj.startAdvertising()
            peripheralObj.scaningClosure = { state in
                if state == false {
                    role = self.getRandomizedRoles()
                    // make this function recursive until connection is build between 2 devices.
                    self.startScaning()
                } else {
                    // done.
                    let ble = self.peripheralObj.subscribedCentrals
                    dictForRealmObj["bleID"] = self.bleCentral?.identifier.uuidString ?? ""
                    debugPrint("Dict after connected \(dictForRealmObj)")
                }
            }
            self.receiveMessage()
        }
    }
    
    func checkForConnection(){
        if finalRole == BLERoles.central.strings {
        } else {
            
        }
    }
    
    // get randomised roles for both devices
    // used this method to make one central and another peripheral by randomisation.
    func getRandomizedRoles() -> String {
        let roles = [BLERoles.central.strings, BLERoles.peripheral.strings]
        let randomRole = roles.randomElement()!
        return randomRole
    }
    
    // receive message from another user.
    func receiveMessage() {
        if finalRole == BLERoles.peripheral.strings {
        } else {
            // for Central
          
        }
    }
    
    // send message from another user.
    func sendMessage(message: Data, uuidCharForWrite : CBUUID?) {
        if finalRole == BLERoles.peripheral.strings {
            peripheralObj.bleSendIndication(message)
        } else {
            centralObj.bleWriteCharacteristic(uuid: uuidCharForWrite ?? BLEIds.uuidCharForWrite, data: message)
        }
    }
    
}

