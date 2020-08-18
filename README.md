Monitored is a macOS framework for detecting when you're being monitored. Actually supports only camera and speaker detection (microphones TBD).

## Installation

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate Monitored into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "gergelysanta/Monitored"
```

Run `carthage` to build the framework and drag the built `Monitored.framework` into your Xcode project.

## Usage

Monitored provides a singleton object for monitoring events from camera and from speakers. Just set it up to delegate events to your object and start the watcher:

```swift
MonitoredWatcher.shared.delegate = self
MonitoredWatcher.shared.start()
```

You'll receive camera and speaker state reports through `MonitoredDelegate` delegate methods:

```swift
func cameraDevice(_ device: CameraDevice, stateChangedTo enabled: Bool) {
    NSLog("Camera: \(device.name) -> \(enabled ? "ON" : "OFF")")
}

func speakerDevice(_ device: SpeakerDevice, stateChangedTo enabled: Bool) {
    NSLog("Speaker: \(device.name) -> \(enabled ? "ON" : "OFF")")
}
```

## License

Monitored is released under the MIT License.  
See [LICENSE](https://github.com/gergelysanta/Monitored/blob/master/LICENSE) for details.
