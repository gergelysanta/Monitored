//
//  CameraDevice+Location.swift
//  Monitored.framework
//
//  Created by Gergely Sánta on 20/06/2020.
//  Copyright © 2020 Gergely Sánta. All rights reserved.
//

import CoreMediaIO

extension CameraDevice {

    /// Camera device location values
    public enum Location: Int {

        case builtInDisplay
        case externalDisplay
        case externalDevice
        case externalWirelessDevice
        case unknown

        public init(rawValue: Int) {
            switch rawValue {
            case kCMIODevicePropertyLocationBuiltInDisplay:
                self = .builtInDisplay
            case kCMIODevicePropertyLocationExternalDisplay:
                self = .externalDisplay
            case kCMIODevicePropertyLocationExternalDevice:
                self = .externalDevice
            case kCMIODevicePropertyLocationExternalWirelessDevice:
                self = .externalWirelessDevice
            default:
                self = .unknown
            }
        }

        public var description: String {
            switch self {
            case .builtInDisplay:
                return "Built-in"
            case .externalDisplay:
                return "External Display"
            case .externalDevice:
                return "External Device"
            case .externalWirelessDevice:
                return "External Wireless"
            case .unknown:
                return "Unknown"
            }
        }
    }

    /// Get Camera device location (available within framework)
    internal func getLocation() -> Location {
        if let locationInt = get(property: .location) as? Int {
            return Location(rawValue: locationInt)
        }
        return Location.unknown
    }

}
