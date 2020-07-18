//
//  CameraProperty.swift
//  Monitored.framework
//
//  Created by Gergely Sánta on 30/06/2020.
//  Copyright © 2020 Philipp Meier. All rights reserved.
//

import CoreMediaIO

extension CameraDevice {

    /// CoreMediaIO property
    public enum Property: Int, CaseIterable {
        case name
        case manufacturer
        case elementName
        case elementCategoryName
        case elementNumberName
        case location
        case plugin
        case deviceUID
        case modelUID
        case transportType
        case deviceIsAlive
        case deviceHasChanged
        case deviceIsRunning
        case deviceIsRunningSomewhere
        case deviceCanBeDefaultDevice
        case hogMode
        case latency
        case streams
        case streamConfiguration
        case deviceMaster

        /// Property value in CoreMediaIO framework
        internal var cmioValue: Int {
            switch self {
            case .name:
                // A CFString that contains the human readable name of the object.
                return kCMIOObjectPropertyName
            case .manufacturer:
                // A CFString that contains the human readable name of the manufacturer of the hardware the CMIOObject is a part of.
                return kCMIOObjectPropertyManufacturer
            case .elementName:
                // A CFString that contains a human readable name for the given element in the given scope.
                return kCMIOObjectPropertyElementName
            case .elementCategoryName:
                // A CFString that contains a human readable name for the category of the given element in the given scope.
                return kCMIOObjectPropertyElementCategoryName
            case .elementNumberName:
                // A CFString that contains a human readable name for the number of the given element in the given scope.
                return kCMIOObjectPropertyElementNumberName
            case .location:
                // A UInt32 indicating the location of the device (for values see kCMIODevicePropertyLocationUnknown, etc., below).
                return kCMIODevicePropertyLocation
            case .plugin:
                // The CMIOObjectID of the CMIOPlugIn that is hosting the device.
                return kCMIODevicePropertyPlugIn
            case .deviceUID:
                // A CFString that contains a persistent identifier for the CMIODevice. A CMIODevice's UID is persistent across boots. The content of the UID string is a black box
                // and may contain information that is unique to a particular instance of a CMIODevice's hardware or unique to the CPU. Therefore they are not suitable for passing
                // between CPUs or for identifying similar models of hardware.
                return kCMIODevicePropertyDeviceUID
            case .modelUID:
                // A CFString that contains a persistent identifier for the model of a CMIODevice. The identifier is unique such that the identifier from two CMIODevices are equal
                // if and only if the two CMIODevices are the exact same model from the same manufacturer. Further, the identifier has to be the same no matter on what machine the
                // CMIODevice appears.
                return kCMIODevicePropertyModelUID
            case .transportType:
                // A UInt32 whose value indicates how the CMIODevice is connected to the CPU. Constants for some of the values for this property can be found in
                // <IOKit/audio/IOAudioTypes.h>.
                return kCMIODevicePropertyTransportType
            case .deviceIsAlive:
                // A UInt32 where a value of 1 means the device is ready and available and 0 means the device is unusable and will most likely go away shortly.
                return kCMIODevicePropertyDeviceIsAlive
            case .deviceHasChanged:
                // The type of this property is a UInt32, but it's value has no meaning. This property exists so that clients can listen to it and be told when the configuration of the
                // CMIODevice has changed in ways that cannot otherwise be conveyed through other notifications. In response to this notification, clients should re-evaluate
                // everything they need to know about the device, particularly the layout and values of the controls.
                return kCMIODevicePropertyDeviceHasChanged
            case .deviceIsRunning:
                // A UInt32 where a value of 0 means the CMIODevice is not performing IO and a value of 1 means that it is.
                return kCMIODevicePropertyDeviceIsRunning
            case .deviceIsRunningSomewhere:
                // A UInt32 where 1 means that the CMIODevice is running in at least one process on the system and 0 means that it isn't running at all.
                return kCMIODevicePropertyDeviceIsRunningSomewhere
            case .deviceCanBeDefaultDevice:
                // A UInt32 where 1 means that the CMIODevice is a possible selection for kCMIOHardwarePropertyDefaultInputDevice or kCMIOHardwarePropertyDefaultOutputDevice
                // depending on the scope.
                return kCMIODevicePropertyDeviceCanBeDefaultDevice
            case .hogMode:
                // A pid_t indicating the process that currently owns exclusive access to the CMIODevice or a value of -1 indicating that the device is currently available to all
                // processes.
                return kCMIODevicePropertyHogMode
            case .latency:
                // A UInt32 containing the number of frames of latency in the CMIODevice. Note that input and output latency may differ. Further, the CMIODevice's CMIOStreams
                // may have additional latency so they should be queried as well. If both the device and the stream say they have latency, then the total latency for the stream is the
                // device latency summed with the stream latency.
                return kCMIODevicePropertyLatency
            case .streams:
                // An array of CMIOStreamIDs that represent the CMIOStreams of the CMIODevice. Note that if a notification is received for this property, any cached
                // CMIOStreamIDs for the device become invalid and need to be re-fetched.
                return kCMIODevicePropertyStreams
            case .streamConfiguration:
                // This property returns the stream configuration of the device in a CMIODeviceStreamConfiguration which describes the list of streams and the number of channels in
                // each stream.
                return kCMIODevicePropertyStreamConfiguration
            case .deviceMaster:
                // A pid_t indicating the process that currently owns exclusive rights to change operating properties of the device. A value of -1 indicating that the device is not
                // currently under the control of a master.
                return kCMIODevicePropertyDeviceMaster
            }
        }

        internal func getValue(fromData data: UnsafeMutableRawPointer) -> Any {
            switch self {
            case .name,
                 .manufacturer,
                 .elementName,
                 .elementCategoryName,
                 .elementNumberName,
                 .deviceUID,
                 .modelUID:
                return data.assumingMemoryBound(to: CFString.self).pointee as String

            case .plugin:
                return data.assumingMemoryBound(to: CMIOObjectID.self).pointee

            case .location,
                 .transportType,
                 .deviceHasChanged,
                 .latency:
                return Int(data.assumingMemoryBound(to: UInt32.self).pointee)

            case .deviceIsAlive,
                 .deviceIsRunning,
                 .deviceIsRunningSomewhere,
                 .deviceCanBeDefaultDevice,
                 .hogMode:
                return data.assumingMemoryBound(to: UInt32.self).pointee != 0

            case .streams:
                return data.assumingMemoryBound(to: [CMIOStreamID].self).pointee

            case .streamConfiguration:
                return data.assumingMemoryBound(to: CMIODeviceStreamConfiguration.self).pointee

            case .deviceMaster:
                return data.assumingMemoryBound(to: pid_t.self).pointee
            }
        }

    }

    /// Get generic CoreMediaIO property
    /// - Parameter property: property
    /// - Returns: property data
    public func get(property: Property) -> Any? {
        let propertyAddress = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(property.cmioValue),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeWildcard),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementWildcard)
        )
        return get(property: property, propertyAddress: propertyAddress)
    }

    /// Watch CoreMediaIO property
    /// - Parameters:
    ///   - property: property
    ///   - listener: block to be called when property changes
    internal func watch(property: Property, listener: CMIOObjectPropertyListenerBlock!) {
        // Remove old listener if exists
        unwatch()
        // Register listener
        var propertyAddress = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(property.cmioValue),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeWildcard),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementWildcard)
        )
        CMIOObjectAddPropertyListenerBlock(self.identifier, &propertyAddress, self.watchCameraQueue, listener)
        propertyWatcher = (propertyAddress, listener)
    }

    internal func unwatch() {
        guard let watcher = propertyWatcher else { return }
        var oldAddress = watcher.0
        CMIOObjectRemovePropertyListenerBlock(self.identifier, &oldAddress, self.watchCameraQueue, watcher.1)
        propertyWatcher = nil
    }

    /// Get generic CoreMediaIO property. Call this method from property watcher blocks
    /// - Parameter propertyAddress: property address
    /// - Returns: property data
    internal func get(propertyAddress: CMIOObjectPropertyAddress) -> Any? {
        guard let property = Property.allCases.filter({$0.cmioValue==propertyAddress.mSelector}).first else { return nil }
        return get(property: property, propertyAddress: propertyAddress)
    }

    /// Method used by internally available methods for getting property value
    /// - Parameters:
    ///   - property: CamWatch property name
    ///   - propertyAddress: CoreMediaIO property address
    /// - Returns: property data
    private func get(property: Property, propertyAddress: CMIOObjectPropertyAddress) -> Any? {
        var dataSize: UInt32 = 0
        var dataUsed: UInt32 = 0
        var pAddress = propertyAddress
        var value: Any?

        // Get property data size
        var opResult = CMIOObjectGetPropertyDataSize(self.identifier, &pAddress, 0, nil, &dataSize)
        if (opResult == OSStatus(kCMIOHardwareNoError)) {
            // Allocate data and get property data
            if let data = malloc(Int(dataSize)) {
                opResult = CMIOObjectGetPropertyData(self.identifier, &pAddress, 0, nil, dataSize, &dataUsed, data)
                value = property.getValue(fromData: data)
                free(data)
            }
        }

        return value
    }

}
