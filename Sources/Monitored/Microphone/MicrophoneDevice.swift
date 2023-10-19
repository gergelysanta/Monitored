//
//  MicrophoneDevice.swift
//  Monitored.framework
//
//  Created by Gergely Sánta on 17/08/2020.
//  Copyright © 2020 Gergely Sánta. All rights reserved.
//

import CoreAudio

public class MicrophoneDevice {

    /// Microphone device identifier
    public let identifier: AudioObjectID

    /// Microphone device name
    public private(set) var name: String = "?"

    /// Microphone device is on or off
    public private(set) var isOn: Bool = false {
        didSet {
            if isOn != oldValue {
                delegate?.microphoneDevice(self, stateChangedTo: isOn)
            }
        }
    }

    /// Device property to be watched
    private let watchProperty = Property.deviceIsRunningSomewhere

    /// Is this device watched?
    public var isWatched: Bool = false {
        didSet {
            if isWatched {
                self.watch(property: watchProperty, listener: microphonePropertyChanged(numberOfAddresses:addresses:))
            } else {
                self.unwatch(property: watchProperty)
            }
        }
    }

    internal var propertyWatcher = [Property: (AudioObjectPropertyAddress, AudioObjectPropertyListenerBlock)]()

    /// Object which receives microphone state change reports
    public weak var delegate: MonitoredDelegate?

    /// Get array of microphone devices in the system
    /// - Returns: array of microphone devices
    static public func getDevices(delegatingTo delegate: MonitoredDelegate?) -> [MicrophoneDevice] {
        var newDevices: [MicrophoneDevice] = []

        var deviceRefs: UnsafeMutableRawPointer! = nil
        var dataSize: UInt32 = 0
        var opResult: OSStatus = 0

        // 1. Get all microphone devices

        // Get data size required for device list
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
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
                let deviceID = current.pointee
                var streamPropertySize: UInt32 = 0

                // Get the input stream configuration of the device. It's a list of audio buffers.
                var streamPropertyAddress = AudioObjectPropertyAddress(
                    mSelector: kAudioDevicePropertyStreamConfiguration,
                    mScope: kAudioDevicePropertyScopeInput,
                    mElement: kAudioObjectPropertyElementMaster
                )
                _ = AudioObjectGetPropertyDataSize(deviceID, &streamPropertyAddress, 0, nil, &streamPropertySize)

                let audioBufferList = AudioBufferList.allocate(maximumBuffers: Int(streamPropertySize))
                AudioObjectGetPropertyData(deviceID, &streamPropertyAddress, 0, nil, &streamPropertySize, audioBufferList.unsafeMutablePointer)

                // Get the number of channels in all the audio buffers in the audio buffer list
                var channelCount: Int = 0
                for i in 0 ..< Int(audioBufferList.unsafeMutablePointer.pointee.mNumberBuffers) {
                    channelCount = channelCount + Int(audioBufferList[i].mNumberChannels)
                }

                free(audioBufferList.unsafeMutablePointer)

                // If there are channels, it's an input device
                if channelCount > 0 {
                    let device = MicrophoneDevice(withId: deviceID)
                    device.delegate = delegate
                    newDevices.append(device)
                }
            }
        }
        free(deviceRefs)

        return newDevices
    }

    /// Method called when a property changes
    /// - Parameters:
    ///   - numberOfAddresses: number of property addresses
    ///   - addresses: array of property addresses
    private func microphonePropertyChanged(numberOfAddresses: UInt32, addresses: UnsafePointer<AudioObjectPropertyAddress>?) {
        for index in 0..<Int(numberOfAddresses) {
            guard let propertyAddress = addresses?.advanced(by: index).pointee else { return }
            if propertyAddress.mSelector == watchProperty.audioValue {
                // Watched property changed
                DispatchQueue.main.sync {
                    self.isOn = (self.get(propertyAddress: propertyAddress) as? Bool) ?? false
                }
            }
        }
    }

    /// Queue for watching microphone changes
    internal let watchMicrophoneQueue: DispatchQueue

    init(withId identifier: AudioObjectID) {
        self.identifier = identifier
        self.watchMicrophoneQueue = DispatchQueue(label: "WatchMicrophoneQueue.\(identifier)")

        self.name = get(property: .name) as? String ?? "?"
        self.isOn = (get(property: watchProperty) as? Bool) ?? false
    }

}
