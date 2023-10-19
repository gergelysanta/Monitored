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

    public enum DeviceType: Int8 {
        case camera
        case microphone
    }

    /// Dictionary of detected camera devices
    public private(set) var cameraDevices: [CameraDevice] = []

    /// Dictionary of detected microphone devices
    public private(set) var microphoneDevices: [MicrophoneDevice] = []

    /// Are the devices actually watched?
    public var isWatching: Bool {
        return (cameraDevices.filter({ $0.isWatched }).count > 0) ||
               (microphoneDevices.filter({ $0.isWatched }).count > 0)
    }

    /// Object which receives camera state change reports
    public weak var delegate: MonitoredDelegate? {
        didSet {
            for camera in cameraDevices {
                camera.delegate = camera.isWatched ? delegate : nil
            }
            for microphone in microphoneDevices {
                microphone.delegate = microphone.isWatched ? delegate : nil
            }
        }
    }

    /// Start device watching
    public func start() {
        for camera in cameraDevices {
            camera.delegate = delegate
            camera.isWatched = true
        }
        for microphone in microphoneDevices {
            microphone.delegate = delegate
            microphone.isWatched = true
        }
    }

    /// Stop device watching
    public func stop() {
        for camera in cameraDevices {
            camera.delegate = nil
            camera.isWatched = false
        }
        for microphone in microphoneDevices {
            microphone.delegate = nil
            microphone.isWatched = false
        }
    }

    public init(watchDevices: [DeviceType] = [.camera, .microphone], delegate: MonitoredDelegate? = nil) {
        let watch = watchDevices.isEmpty ? [.camera, .microphone] : watchDevices
        self.delegate = delegate
        if watch.contains(.camera) {
            cameraDevices = CameraDevice.getDevices(delegatingTo: delegate)
        }
        if watch.contains(.microphone) {
            microphoneDevices = MicrophoneDevice.getDevices(delegatingTo: delegate)
        }
    }

    deinit {
        stop()
    }

}
