//
//  SpeakerDevice.swift
//  Monitored.framework
//
//  Created by Gergely Sánta on 17/08/2020.
//  Copyright © 2020 Gergely Sánta. All rights reserved.
//

import CoreAudio

public class SpeakerDevice {

    /// Speaker device identifier
    public let identifier: AudioObjectID

    /// Speaker device name
    public private(set) var name: String = "?"

    /// Speaker device is on or off
    public private(set) var isOn: Bool = false {
        didSet {
            if isOn != oldValue {
                delegate?.speakerDevice(self, stateChangedTo: isOn)
            }
        }
    }

    public var isWatched: Bool = false {
        didSet {
            if isWatched {
                self.watch(property: .deviceIsRunningSomewhere, listener: speakerPropertyChanged(numberOfAddresses:addresses:))
            } else {
                self.unwatch()
            }
        }
    }

    internal var propertyWatcher: (AudioObjectPropertyAddress, AudioObjectPropertyListenerBlock)?

    /// Object which receives speaker state change reports
    public weak var delegate: MonitoredDelegate?

    /// Get array of speaker devices in the system
    /// - Returns: array of speaker devices
    static public func getDevices(delegatingTo delegate: MonitoredDelegate?) -> [SpeakerDevice] {
        var newDevices: [SpeakerDevice] = []

        var deviceRefs: UnsafeMutableRawPointer! = nil
        var dataSize: UInt32 = 0
        var opResult: OSStatus = 0

        // 1. Get all speaker devices

        // Get data size required for device list
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(kAudioHardwarePropertyDevices),
            mScope: AudioObjectPropertyScope(kAudioObjectPropertyScopeGlobal),
            mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMaster)
        )
        _ = AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, &dataSize)

        // We need to wait until we get some data
        repeat {
            if deviceRefs != nil {
                free(deviceRefs)
                deviceRefs = nil
            }
            deviceRefs = malloc(Int(dataSize))
            var size = dataSize
            opResult = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, &size, deviceRefs);
        } while opResult == OSStatus(kAudioHardwareBadPropertySizeError)

        // Get device IDs from unsafe pointer array
        if let devices = deviceRefs {
            for offset in stride(from: 0, to: dataSize, by: MemoryLayout<AudioObjectID>.size) {
                let current = devices.advanced(by: Int(offset)).assumingMemoryBound(to: AudioObjectID.self)

                let device = SpeakerDevice(withId: current.pointee)
                device.delegate = delegate
                newDevices.append(device)
            }
        }
        free(deviceRefs)

        return newDevices
    }

    /// Method called when a property changes
    /// - Parameters:
    ///   - numberOfAddresses: number of property addresses
    ///   - addresses: array of property addresses
    private func speakerPropertyChanged(numberOfAddresses: UInt32, addresses: UnsafePointer<AudioObjectPropertyAddress>?) {
        for index in 0..<Int(numberOfAddresses) {
            guard let propertyAddress = addresses?.advanced(by: index).pointee else { return }
            if propertyAddress.mSelector == AudioObjectPropertySelector(kAudioDevicePropertyDeviceIsRunningSomewhere) {
                // kAudioDevicePropertyDeviceIsRunningSomewhere changed
                self.isOn = (self.get(propertyAddress: propertyAddress) as? Bool) ?? false
            }
        }
    }

    /// Queue for watching speaker changes
    internal let watchSpeakerQueue: DispatchQueue

    init(withId identifier: AudioObjectID) {
        self.identifier = identifier
        self.watchSpeakerQueue = DispatchQueue(label: "WatchSpeakerQueue.\(identifier)")

        self.name = get(property: .name) as? String ?? "?"
        self.isOn = (get(property: .deviceIsRunningSomewhere) as? Bool) ?? false
    }

}
