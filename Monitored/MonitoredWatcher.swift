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

    /// Delegate method sent when speaker device state was changed
    /// - Parameters:
    ///   - device: speaker device
    ///   - enabled: new state
    func speakerDevice(_ device: SpeakerDevice, stateChangedTo enabled: Bool)

}

extension MonitoredDelegate {
    func cameraDevice(_ device: CameraDevice, stateChangedTo enabled: Bool) { }
    func speakerDevice(_ device: SpeakerDevice, stateChangedTo enabled: Bool) { }
}


public final class MonitoredWatcher {

    /// Singleton instance
    public static let shared = MonitoredWatcher()

    /// Dictionary of detected camera devices
    public private(set) var cameraDevices: [CameraDevice] = []

    /// Dictionary of detected speaker devices
    public private(set) var speakerDevices: [SpeakerDevice] = []

    /// Object which receives camera state change reports
    public weak var delegate: MonitoredDelegate? {
        didSet {
            for camera in cameraDevices {
                camera.delegate = delegate
            }
            for speaker in speakerDevices {
                speaker.delegate = delegate
            }
        }
    }

    /// Start device watching
    public func start() {
        for camera in cameraDevices {
            camera.isWatched = true
        }
        for speaker in speakerDevices {
            speaker.isWatched = true
        }
    }

    /// Stop device watching
    public func stop() {
        for camera in cameraDevices {
            camera.isWatched = false
        }
        for speaker in speakerDevices {
            speaker.isWatched = false
        }
    }

    /// This is a singleton object accessible through SameraWatcher.shared, creating other instances is not allowed
    private init() {
        cameraDevices = CameraDevice.getDevices(delegatingTo: delegate)
        speakerDevices = SpeakerDevice.getDevices(delegatingTo: delegate)
    }

}
