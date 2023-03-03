//
//  SSDPNetworkDiscovery.swift
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
//  Created by Berrie Kremers on 31/12/2022.
//

import Foundation
import Network
import Combine
import os.log

class SSDPNetworkDiscovery: SSDPDiscovery {
    private var multicastGroup: NWMulticastGroup?
    private var connectionGroup: NWConnectionGroup?
    
    func startDiscovery(forTypes types: [String]) throws {
        guard multicastGroup == nil else { throw UPnPError.alreadyConnected }
        let multicastGroup = try NWMulticastGroup(for:[.hostPort(host: .init(multicastGroupAddress), port: .init(integerLiteral: multicastUDPPort))])
        let params = NWParameters.udp
        params.allowLocalEndpointReuse = true
        let connectionGroup = NWConnectionGroup(with: multicastGroup, using: params)
        
        connectionGroup.stateUpdateHandler = { [weak self] (newState) in
            Logger.swiftUPnP.debug("Connection group entered state \(String(describing: newState))")
            
            switch newState {
            case let .failed(error):
                Logger.swiftUPnP.error("\(error.localizedDescription)")
            case .cancelled:
                self?.multicastGroup = nil
                self?.connectionGroup = nil
            default:
                break
            }
        }
        connectionGroup.setReceiveHandler(maximumMessageSize: 65535, rejectOversizedMessages: true) { (message, content, isComplete) in
            if let content = content {
                self.processData(content)
            }
        }
        
        connectionGroup.start(queue: .main)
        
        self.types = types
        self.multicastGroup = multicastGroup
        self.connectionGroup = connectionGroup
    }
    
    func stopDiscovery() {
        guard let connectionGroup = connectionGroup else { return }
        connectionGroup.cancel()
        multicastGroup = nil
        self.connectionGroup = nil
        types = []
    }
    
    func searchRequest() {
        guard let connectionGroup = connectionGroup else { return }

        for type in types {
            if let data = self.searchRequestData(forType: type) {
                connectionGroup.send(content: data) { error in
                    if let error = error as? NSError {
                        self.stopDiscovery()
                        Logger.swiftUPnP.error("\(error.localizedDescription)")
                    }
                }
            }
        }
    }
}


