//
//  UserAgentGenerator.swift
//
//  Copyright (c) 2023 Katoemba Software, (https://rigelian.net/)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//
//  Created by Berrie Kremers on 08/01/2023.
//

import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct UserAgentGenerator {
    var UAString: String {
        "\(appNameAndVersion()) \(deviceName()) \(deviceVersion()) \(CFNetworkVersion()) \(DarwinVersion())"
    }

    //eg. Darwin/16.3.0
    private func DarwinVersion() -> String {
        var sysinfo = utsname()
        uname(&sysinfo)
        let dv = String(bytes: Data(bytes: &sysinfo.release, count: Int(_SYS_NAMELEN)), encoding: .ascii)!.trimmingCharacters(in: .controlCharacters)
        return "Darwin/\(dv)"
    }
    
    //eg. CFNetwork/808.3
    private func CFNetworkVersion() -> String {
        guard let dictionary = Bundle.main.infoDictionary else { return "CFNetwork/Unknown" }

        let version = dictionary["CFBundleShortVersionString"] as? String ?? "Unknown"
        return "CFNetwork/\(version)"
    }
    
    //eg. iOS/10_1
    private func deviceVersion() -> String {
#if canImport(UIKit)
        let currentDevice = UIDevice.current
        return "\(currentDevice.systemName)/\(currentDevice.systemVersion)"
#elseif canImport(AppKit)
        return "\(ProcessInfo.processInfo.operatingSystemVersion)"
#else
        return ""
#endif
    }
    
    //eg. iPhone5,2
    private func deviceName() -> String {
        var sysinfo = utsname()
        uname(&sysinfo)
        return String(bytes: Data(bytes: &sysinfo.machine, count: Int(_SYS_NAMELEN)), encoding: .ascii)!.trimmingCharacters(in: .controlCharacters)
    }
    
    //eg. MyApp/1
    private func appNameAndVersion() -> String {
        guard let dictionary = Bundle.main.infoDictionary else { return "Unknown/Unknown" }
        let version = dictionary["CFBundleShortVersionString"] as? String ?? "Unknown"
        let name = dictionary["CFBundleName"] as? String ?? "Unknown"
        return "\(name)/\(version)"
    }
}
