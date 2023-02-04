//
//  IPHelper.swift
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
//  Created by Berrie Kremers on 20/01/2023.
//

import Foundation
import os.log

struct IPHelper {
    private enum AddressRequestType {
        case ipAddress
        case netmask
    }
    
    // From BDS ioccom.h
    // Macro to create ioctl request
    private static func _IOC (_ io: UInt32, _ group: UInt32, _ num: UInt32, _ len: UInt32) -> UInt32 {
        let rv = io | (( len & UInt32(IOCPARM_MASK)) << 16) | ((group << 8) | num)
        return rv
    }
    
    // Macro to create read/write IOrequest
    private static func _IOWR (_ group: Character , _ num : UInt32, _ size: UInt32) -> UInt32 {
        return _IOC(IOC_INOUT, UInt32 (group.asciiValue!), num, size)
    }
    
    private static func _interfaceAddressForName (_ name: String, _ requestType: AddressRequestType) throws -> String {
        
        var ifr = ifreq ()
        ifr.ifr_ifru.ifru_addr.sa_family = sa_family_t(AF_INET)
        
        // Copy the name into a zero padded 16 CChar buffer
        
        let ifNameSize = Int (IFNAMSIZ)
        var b = [CChar] (repeating: 0, count: ifNameSize)
        strncpy (&b, name, ifNameSize)
        
        // Convert the buffer to a 16 CChar tuple - that's what ifreq needs
        ifr.ifr_name = (b [0], b [1], b [2], b [3], b [4], b [5], b [6], b [7], b [8], b [9], b [10], b [11], b [12], b [13], b [14], b [15])
        
        let ioRequest: UInt32 = {
            switch requestType {
            case .ipAddress: return _IOWR("i", 33, UInt32(MemoryLayout<ifreq>.size))    // Magic number SIOCGIFADDR - see sockio.h
            case .netmask: return _IOWR("i", 37, UInt32(MemoryLayout<ifreq>.size))      // Magic number SIOCGIFNETMASK
            }
        } ()
        
        if ioctl(socket(AF_INET, SOCK_DGRAM, 0), UInt(ioRequest), &ifr) < 0 {
            throw POSIXError (POSIXErrorCode (rawValue: errno) ?? POSIXErrorCode.EINVAL)
        }
        
        let sin = unsafeBitCast(ifr.ifr_ifru.ifru_addr, to: sockaddr_in.self)
        let rv = String (cString: inet_ntoa (sin.sin_addr))
        
        return rv
    }
    
    public static func getInterfaceIPAddress (interfaceName: String) throws -> String {
        return try _interfaceAddressForName(interfaceName, .ipAddress)
    }
    
    public static func getInterfaceNetMask (interfaceName: String) throws -> String {
        return try _interfaceAddressForName(interfaceName, .netmask)
    }
    
    public static func getInterfaceIPAddress(interfaceNames: [String]) -> String? {
        for name in interfaceNames {
            if let ipAddress = try? getInterfaceIPAddress(interfaceName: name) {
                return ipAddress
            }
        }
        return nil
    }
    
    private static func isPortAvailable(port: in_port_t) -> Bool {
        let socketFileDescriptor = socket(AF_INET, SOCK_STREAM, 0)
        if socketFileDescriptor == -1 {
            return false
        }

        var addr = sockaddr_in()
        let sizeOfSockkAddr = MemoryLayout<sockaddr_in>.size
        addr.sin_len = __uint8_t(sizeOfSockkAddr)
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = Int(OSHostByteOrder()) == OSLittleEndian ? _OSSwapInt16(port) : port
        addr.sin_addr = in_addr(s_addr: inet_addr("0.0.0.0"))
        addr.sin_zero = (0, 0, 0, 0, 0, 0, 0, 0)
        var bind_addr = sockaddr()
        memcpy(&bind_addr, &addr, Int(sizeOfSockkAddr))

        if Darwin.bind(socketFileDescriptor, &bind_addr, socklen_t(sizeOfSockkAddr)) == -1 {
            return false
        }
        let isAvailable = listen(socketFileDescriptor, SOMAXCONN ) != -1
        Darwin.close(socketFileDescriptor)
        return isAvailable
    }
    
    public static func freePortFromRange(range: Range<UInt16>) -> UInt16 {
        // Try at most 10 times to find a random port that is available within the specified range
        for _ in 0..<10 {
            let port = UInt16.random(in: range)
            if isPortAvailable(port: port) {
                return port
            }
        }
        
        return 0
    }
}

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!

    /// Logs the view cycles like viewDidLoad.
    static let swiftUPnP = Logger(subsystem: subsystem, category: "SwiftUPnP")
    
    static func indent(_ indent: Int) -> String {
        var indentLine = ""
        for _ in 0..<indent {
            indentLine += "  "
        }
        
        return indentLine
    }
}
