//
//  SpeakerDevice+Property.swift
//  Monitored.framework
//
//  Created by Gergely Sánta on 17/08/2020.
//  Copyright © 2020 Philipp Meier. All rights reserved.
//

import CoreAudio

extension SpeakerDevice {

    /// CoreAudio property
    public enum Property: Int, CaseIterable {
        case name
        case manufacturer
        case deviceIsRunningSomewhere

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
            }
        }

        internal func getValue(fromData data: UnsafeMutableRawPointer) -> Any {
            switch self {
            case .name,
                 .manufacturer:
                return data.assumingMemoryBound(to: CFString.self).pointee as String
            case .deviceIsRunningSomewhere:
                return data.assumingMemoryBound(to: UInt32.self).pointee != 0
            }
        }
    }

    /// Get generic CoreAudio property
    /// - Parameter property: property
    /// - Returns: property data
    public func get(property: Property) -> Any? {
        let propertyAddress = AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(property.audioValue),
            mScope: AudioObjectPropertyScope(kAudioObjectPropertyScopeWildcard),
            mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementWildcard)
        )
        return get(property: property, propertyAddress: propertyAddress)
    }

    /// Watch CoreAudio property
    /// - Parameters:
    ///   - property: property
    ///   - listener: block to be called when property changes
    internal func watch(property: Property, listener: AudioObjectPropertyListenerBlock!) {
        // Remove old listener if exists
        unwatch()
        // Register listener
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(property.audioValue),
            mScope: AudioObjectPropertyScope(kAudioObjectPropertyScopeWildcard),
            mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementWildcard)
        )
        AudioObjectAddPropertyListenerBlock(self.identifier, &propertyAddress, self.watchSpeakerQueue, listener)
        propertyWatcher = (propertyAddress, listener)
    }

    internal func unwatch() {
        guard let watcher = propertyWatcher else { return }
        var oldAddress = watcher.0
        AudioObjectRemovePropertyListenerBlock(self.identifier, &oldAddress, self.watchSpeakerQueue, watcher.1)
        propertyWatcher = nil
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
