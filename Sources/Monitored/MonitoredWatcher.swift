//
//  MonitoredWatcher.swift
//  Monitored.framework
//
//  Created by Gergely Sánta on 20/06/2020.
//  Copyright © 2020 Gergely Sánta. All rights reserved.
//

import CoreMediaIO
import CoreAudio

public protocol MonitoredDelegate: AnyObject {

    /// Delegate method sent when camera device state was changed
    /// - Parameters:
    ///   - device: camera device
    ///   - enabled: new state
    func cameraDevice(_ device: CameraDevice, stateChangedTo enabled: Bool)

    /// Delegate method sent when microphone device state was changed
    /// - Parameters:
    ///   - device: microphone device
    ///   - enabled: new state
    func microphoneDevice(_ device: MicrophoneDevice, stateChangedTo enabled: Bool)

}

extension MonitoredDelegate {
    func cameraDevice(_ device: CameraDevice, stateChangedTo enabled: Bool) { }
    func microphoneDevice(_ device: MicrophoneDevice, stateChangedTo enabled: Bool) { }
}


public final class MonitoredWatcher {

    /// Singleton instance
    public static let shared = MonitoredWatcher()

    /// Dictionary of detected camera devices
    public private(set) var cameraDevices: [CameraDevice] = []

    /// Dictionary of detected microphone devices
    public private(set) var microphoneDevices: [MicrophoneDevice] = []

    /// Object which receives camera state change reports
    public weak var delegate: MonitoredDelegate? {
        didSet {
            for camera in cameraDevices {
                camera.delegate = delegate
            }
            for microphone in microphoneDevices {
                microphone.delegate = delegate
            }
        }
    }

    /// Start device watching
    public func start() {
        for camera in cameraDevices {
            camera.isWatched = true
        }
        for microphone in microphoneDevices {
            microphone.isWatched = true
        }
    }

    /// Stop device watching
    public func stop() {
        for camera in cameraDevices {
            camera.isWatched = false
        }
        for microphone in microphoneDevices {
            microphone.isWatched = false
        }
    }

    /// This is a singleton object accessible through SameraWatcher.shared, creating other instances is not allowed
    private init() {
        cameraDevices = CameraDevice.getDevices(delegatingTo: delegate)
        microphoneDevices = MicrophoneDevice.getDevices(delegatingTo: delegate)
    }

}
