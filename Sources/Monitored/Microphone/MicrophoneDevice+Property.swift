//
//  MicrophoneDevice+Property.swift
//  Monitored.framework
//
//  Created by Gergely Sánta on 17/08/2020.
//  Copyright © 2020 Philipp Meier. All rights reserved.
//

import CoreAudio

extension MicrophoneDevice {

    /// CoreAudio property
    public enum Property: Int, CaseIterable {
        case name
        case manufacturer
        case deviceIsRunningSomewhere
        case hogMode

        var isWatchable: Bool {
            switch self {
            case .deviceIsRunningSomewhere:
                return true
            default:
                return false
            }
        }

        /// Property value in CoreAudio framework
        internal var audioValue: UInt32 {
            switch self {
            case .name:
                // A CFStringRef that contains the human readable name of the AudioDevice. The caller is responsible for releasing the returned CFObject.
                return kAudioDevicePropertyDeviceNameCFString
            case .manufacturer:
                // A CFString that contains the human readable name of the manufacturer of the hardware the CMIOObject is a part of.
                return kAudioDevicePropertyDeviceManufacturerCFString
            case .deviceIsRunningSomewhere:
                // A UInt32 where 1 means that the AudioDevice is running in at least one process on the system and 0 means that it isn't running at all.
                return kAudioDevicePropertyDeviceIsRunningSomewhere
            case .hogMode:
                // A pid_t indicating the process that currently owns exclusive access to the
                // AudioDevice or a value of -1 indicating that the device is currently
                // available to all processes. If the AudioDevice is in a non-mixable mode,
                // the HAL will automatically take hog mode on behalf of the first process to
                // start an IOProc.
                // Note that when setting this property, the value passed in is ignored. If
                // another process owns exclusive access, that remains unchanged. If the
                // current process owns exclusive access, it is released and made available to
                // all processes again. If no process has exclusive access (meaning the current
                // value is -1), this process gains ownership of exclusive access.  On return,
                // the pid_t pointed to by inPropertyData will contain the new value of the//
                // property.
                return kAudioDevicePropertyHogMode
            }
        }

        internal func getValue(fromData data: UnsafeMutableRawPointer) -> Any {
            switch self {
            case .name,
                 .manufacturer:
                return data.assumingMemoryBound(to: CFString.self).pointee as String
            case .deviceIsRunningSomewhere:
                return data.assumingMemoryBound(to: UInt32.self).pointee != 0
            case .hogMode:
                return data.assumingMemoryBound(to: pid_t.self).pointee
            }
        }
    }

    /// Get generic CoreAudio property
    /// - Parameter property: property
    /// - Returns: property data
    public func get(property: Property) -> Any? {
        let propertyAddress = AudioObjectPropertyAddress(
            mSelector: property.audioValue,
            mScope: kAudioObjectPropertyScopeWildcard,
            mElement: kAudioObjectPropertyElementWildcard
        )
        return get(property: property, propertyAddress: propertyAddress)
    }

    /// Watch CoreAudio property
    /// - Parameters:
    ///   - property: property
    ///   - listener: block to be called when property changes
    internal func watch(property: Property, listener: AudioObjectPropertyListenerBlock!) {
        guard property.isWatchable else { return }

        // Remove old listener if exists
        unwatch(property: property)

        // Register listener
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: property.audioValue,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMaster
        )
        AudioObjectAddPropertyListenerBlock(self.identifier, &propertyAddress, self.watchMicrophoneQueue, listener)
        propertyWatcher[property] = (propertyAddress, listener)
    }

    /// Stop watching all CoreAudio properties
    internal func unwatchAll() {
        for property in propertyWatcher.keys {
            unwatch(property: property)
        }
    }

    /// Stop watching CoreAudio property
    /// - Parameter property: property
    internal func unwatch(property: Property) {
        guard let watcher = propertyWatcher[property] else { return }
        var oldAddress = watcher.0
        AudioObjectRemovePropertyListenerBlock(self.identifier, &oldAddress, self.watchMicrophoneQueue, watcher.1)
        propertyWatcher[property] = nil
    }

    /// Get generic CoreAudio property. Call this method from property watcher blocks
    /// - Parameter propertyAddress: property address
    /// - Returns: property data
    internal func get(propertyAddress: AudioObjectPropertyAddress) -> Any? {
        guard let property = Property.allCases.filter({$0.audioValue==propertyAddress.mSelector}).first else { return nil }
        return get(property: property, propertyAddress: propertyAddress)
    }

    /// Method used by internally available methods for getting property value
    /// - Parameters:
    ///   - property: CamWatch property name
    ///   - propertyAddress: CoreAudio property address
    /// - Returns: property data
    private func get(property: Property, propertyAddress: AudioObjectPropertyAddress) -> Any? {
        var dataSize: UInt32 = 0
        var pAddress = propertyAddress
        var value: Any?

        // Get property data size
        var opResult = AudioObjectGetPropertyDataSize(self.identifier, &pAddress, 0, nil, &dataSize)
        if (opResult == OSStatus(kAudioHardwareNoError)) {
            // Allocate data and get property data
            if let data = malloc(Int(dataSize)) {
                opResult = AudioObjectGetPropertyData(self.identifier, &pAddress, 0, nil, &dataSize, data)
                value = property.getValue(fromData: data)
                free(data)
            }
        }

        return value
    }

}
