Monitored is a macOS framework for detecting when you're being monitored. It detect state changes on camera and microphone devices.

## Usage

Monitored provides a singleton object for monitoring events from camera and from microphones. Just set it up to delegate events to your object and start the watcher:

```swift
MonitoredWatcher.shared.delegate = self
MonitoredWatcher.shared.start()
```

You'll receive camera and microphone state reports through `MonitoredDelegate` delegate methods:

```swift
func cameraDevice(_ device: CameraDevice, stateChangedTo enabled: Bool) {
    NSLog("Camera: \(device.name) -> \(enabled ? "ON" : "OFF")")
}

func microphoneDevice(_ device: MicrophoneDevice, stateChangedTo enabled: Bool) {
    NSLog("Microphone: \(device.name) -> \(enabled ? "ON" : "OFF")")
}
```

### Sandboxing

Sandboxed applications using `Monitored.framework` will need to enable the following entitlements:

1. `com.apple.security.device.camera` for detecting camera devices
2. `com.apple.security.device.audio-input` for detecting microphone devices 

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

## License

Monitored is released under the MIT License.  
See [LICENSE](https://github.com/gergelysanta/Monitored/blob/master/LICENSE) for details.
