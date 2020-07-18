//
//  CameraDevice.swift
//  Monitored.framework
//
//  Created by Gergely Sánta on 20/06/2020.
//  Copyright © 2020 Gergely Sánta. All rights reserved.
//

import CoreMediaIO

public protocol CameraDeviceDelegate: AnyObject {

    /// Delegate method sent when camera device state was changed
    /// - Parameters:
    ///   - camera: camera device
    ///   - enabled: new state
    func cameraDevice(_ device: CameraDevice, stateChangedTo enabled: Bool)

}

extension CameraDeviceDelegate {
    func cameraDevice(_ device: CameraDevice, stateChangedTo enabled: Bool) { }
}

public class CameraDevice {

    /// Camera device identifier
    public let identifier: CMIOObjectID

    /// Camera device name
    public private(set) var name: String = "?"

    /// Camera device location
    public private(set) var location: Location = .unknown

    /// Camera device is on or off
    public private(set) var isOn: Bool = false {
        didSet {
            if isOn != oldValue {
                delegate?.cameraDevice(self, stateChangedTo: isOn)
            }
        }
    }

    public var isWatched: Bool = false {
        didSet {
            if isWatched {
                self.watch(property: .deviceIsRunningSomewhere, listener: cameraPropertyChanged(numberOfAddresses:addresses:))
            } else {
                self.unwatch()
            }
        }
    }

    internal var propertyWatcher: (CMIOObjectPropertyAddress, CMIOObjectPropertyListenerBlock)?

    /// Object which receives camera state change reports
    public weak var delegate: CameraDeviceDelegate?

    /// Method called when a property changes
    /// - Parameters:
    ///   - numberOfAddresses: number of property addresses
    ///   - addresses: array of property addresses
    private func cameraPropertyChanged(numberOfAddresses: UInt32, addresses: UnsafePointer<CMIOObjectPropertyAddress>?) {
        for index in 0..<Int(numberOfAddresses) {
            guard let propertyAddress = addresses?.advanced(by: index).pointee else { return }
            if propertyAddress.mSelector == CMIOObjectPropertySelector(kCMIODevicePropertyDeviceIsRunningSomewhere) {
                // kCMIODevicePropertyDeviceIsRunningSomewhere changed
                self.isOn = (self.get(propertyAddress: propertyAddress) as? Bool) ?? false
            }
        }
    }

    /// Queue for watching camera changes
    internal let watchCameraQueue: DispatchQueue

    init(withId identifier: CMIOObjectID) {
        self.identifier = identifier
        self.watchCameraQueue = DispatchQueue(label: "WatchCameraQueue.\(identifier)")

        self.name = get(property: .name) as? String ?? "?"
        self.location = getLocation()
        self.isOn = (get(property: .deviceIsRunningSomewhere) as? Bool) ?? false
    }

}
