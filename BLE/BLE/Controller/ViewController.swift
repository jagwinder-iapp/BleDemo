//
//  ViewController.swift
//  BLE
//
//  Created by iapp on 20/09/23.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // Scanning for nearby devices and connected automatically via helper class.
        self.scanNearbyDevice()
    }
        
    func scanNearbyDevice() {
        // assign some roles to devices randomly.
        // Please call startScaning() method from BLEManager, This will init() ble and start process to connect nearby device with particular services and characteristics.
        
        if BLEManager.shared.finalRole == BLERoles.central.strings {
            BLEManager.shared.startScaning()
        }else {
            BLEManager.shared.startScaning()
        }
    }

}

