//
//  MonitoredWatcher.swift
//  Monitored.framework
//
//  Created by Gergely Sánta on 20/06/2020.
//  Copyright © 2020 Gergely Sánta. All rights reserved.
//

// To README.md:
// https://github.com/johnboiles/coremediaio-dal-minimal-example/blob/master/CMIOMinimalSample/Device.mm

// Microphone:
// This method cannot be directly used to detect microphone use, but detecting microphone use is actually not as difficult as camera.
// You can use AMCoreAudio for most of the heavy lifting. The way I did it was listen for the nameDidChange
// and isRunningSomewhereDidChange to update internal state, and to detect when the microphone is in use somewhere.
// I hope that's enough information to get you started, comments are only so long.

import CoreMediaIO

public final class MonitoredWatcher {

    /// Singleton instance
    public static let shared = MonitoredWatcher()

    /// Object which receives camera state change reports
    public weak var delegate: CameraDeviceDelegate? {
        didSet {
            for camera in cameraDevices {
                camera.delegate = delegate
            }
        }
    }

    /// Should devices be watched?
    public var watchDevices: Bool = false {
        didSet {
            for camera in cameraDevices {
                camera.isWatched = watchDevices
            }
        }
    }

    /// Dictionary of found camera devices
    private var cameraDevices: [CameraDevice] = []

    /// This is a singleton object accessible through SameraWatcher.shared, creating other instances is not allowed
    private init() {
        cameraDevices = getCameraDevices()
    }

    private func getCameraDevices() -> [CameraDevice] {
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
            if deviceRefs != nil {
                free(deviceRefs)
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
        free(deviceRefs)

        return newDevices
    }

}
