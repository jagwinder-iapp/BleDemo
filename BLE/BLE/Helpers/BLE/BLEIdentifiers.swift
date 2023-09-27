//
//  BLEIdentifiers.swift
//  Briar
//
//  Created by iapp on 12/09/23.
//

import CoreBluetooth

let uuidServiceIdentifier = "25AE1441-05D3-4C5B-8281-93D4E07420CC"
let uuidCharForReadIdentifier = "25AE1442-05D3-4C5B-8281-93D4E07420CF"
let uuidCharForWriteIdentifier = "25AE1443-05D3-4C5B-8281-93D4E07420CF"
let uuidCharForIndicateIdentifier = "25AE1444-05D3-4C5B-8281-93D4E07420CF"

struct BLEIds {
    static var uuidService: CBUUID {
        return CBUUID(string: uuidServiceIdentifier)
    }
    static var uuidCharForRead: CBUUID {
        return CBUUID(string: uuidCharForReadIdentifier)
    }
    static var uuidCharForWrite: CBUUID {
        return CBUUID(string: uuidCharForWriteIdentifier)
    }
    static var uuidCharForIndicate : CBUUID {
        return CBUUID(string: uuidCharForIndicateIdentifier)
    }
}
