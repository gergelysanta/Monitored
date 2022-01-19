//
//  CameraDevice.swift
//  Monitored.framework
//
//  Created by Gergely Sánta on 20/06/2020.
//  Copyright © 2020 Gergely Sánta. All rights reserved.
//

// Inspired by:
// https://github.com/johnboiles/coremediaio-dal-minimal-example/blob/master/CMIOMinimalSample/Device.mm

import CoreMediaIO

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
                self.unwatch(property: .deviceIsRunningSomewhere)
            }
        }
    }

    internal var propertyWatcher = [Property: (CMIOObjectPropertyAddress, CMIOObjectPropertyListenerBlock)]()

    /// Object which receives camera state change reports
    public weak var delegate: MonitoredDelegate?

    /// Get array of camera devices in the system
    /// - Returns: array of camera devices
    static public func getDevices(delegatingTo delegate: MonitoredDelegate?) -> [CameraDevice] {
        var newDevices: [CameraDevice] = []

        var deviceRefs: UnsafeMutableRawPointer? = nil
        var dataSize: UInt32 = 0
        var dataUsed: UInt32 = 0
        var opResult: OSStatus = 0

        // 1. Get all camera devices

        // Get data size required for device list
        var propertyAddress = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyDevices),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMaster)
        )
        _ = CMIOObjectGetPropertyDataSize(CMIOObjectID(kCMIOObjectSystemObject), &propertyAddress, 0, nil, &dataSize)

        // We need to wait until we get some data
        repeat {
            if let devRefs = deviceRefs {
                free(devRefs)
                deviceRefs = nil
            }
            deviceRefs = malloc(Int(dataSize))
            opResult = CMIOObjectGetPropertyData(CMIOObjectID(kCMIOObjectSystemObject), &propertyAddress, 0, nil, dataSize, &dataUsed, deviceRefs);
        } while opResult == OSStatus(kCMIOHardwareBadPropertySizeError)

        // Get device IDs from unsafe pointer array
        if let devices = deviceRefs {
            for offset in stride(from: 0, to: dataSize, by: MemoryLayout<CMIOObjectID>.size) {
                let current = devices.advanced(by: Int(offset)).assumingMemoryBound(to: CMIOObjectID.self)

                let device = CameraDevice(withId: current.pointee)
                device.delegate = delegate
                newDevices.append(device)
            }
        }
        if let devRefs = deviceRefs {
            free(devRefs)
        }

        return newDevices
    }

    /// Method called when a property changes
    /// - Parameters:
    ///   - numberOfAddresses: number of property addresses
    ///   - addresses: array of property addresses
    private func cameraPropertyChanged(numberOfAddresses: UInt32, addresses: UnsafePointer<CMIOObjectPropertyAddress>?) {
        for index in 0..<Int(numberOfAddresses) {
            guard let propertyAddress = addresses?.advanced(by: index).pointee else { return }
            if propertyAddress.mSelector == CMIOObjectPropertySelector(kCMIODevicePropertyDeviceIsRunningSomewhere) {
                // kCMIODevicePropertyDeviceIsRunningSomewhere changed
                DispatchQueue.main.sync {
                    self.isOn = (self.get(propertyAddress: propertyAddress) as? Bool) ?? false
                }
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
