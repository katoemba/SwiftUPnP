//
//  SSDPCocoaAsyncSocketDiscovery.swift
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
//  Created by Berrie Kremers on 03/03/2022.
//

import Foundation
import Combine
import CocoaAsyncSocket
import Network
import os.log

class SSDPCocoaAsyncSocketDiscovery: SSDPDiscovery {
    private var multicastSocket: GCDAsyncUdpSocket?
    /// Bumped on every start and stop, so work scheduled for an earlier session (repeated searches, reopening the
    /// socket) is dropped.
    private var generation = 0
    private var pathMonitor: NWPathMonitor?
    /// The pending reopen, so that a burst of network changes leads to one reopen.
    private var reopenWorkItem: DispatchWorkItem?
    /// The repeated searches of the last searchRequest.
    private var searchWorkItems = [DispatchWorkItem]()

    func startDiscovery(forTypes types: [String]) throws {
        guard multicastSocket == nil else { throw UPnPError.alreadyConnected }

        self.types = types
        generation += 1
        startMonitoringNetworkChanges()
        do {
            try openSocket()
        }
        catch {
            // Typically there is no network yet (e.g. the app starts before Wi-Fi is up). Keep trying, rather than
            // not discovering anything for the rest of the session.
            Logger.swiftUPnP.error("Could not open the SSDP socket: \(error.localizedDescription)")
            reopenSocket(after: 5)
        }
    }
    
    func stopDiscovery() {
        generation += 1
        reopenWorkItem?.cancel()
        reopenWorkItem = nil
        searchWorkItems.forEach { $0.cancel() }
        searchWorkItems = []
        pathMonitor?.cancel()
        pathMonitor = nil
        types = []
        guard let multicastSocket = multicastSocket else { return }
        
        // Cleared before closing, so the close callback knows the socket was closed on purpose.
        self.multicastSocket = nil
        multicastSocket.close()
    }
    
    func searchRequest() {
        sendSearchRequests()

        // A single M-SEARCH over UDP is easily lost, and fails outright while the system is still asking for access
        // to the local network. Repeat it a few times.
        searchWorkItems.forEach { $0.cancel() }
        searchWorkItems = [3.0, 10.0].map { delay in
            let workItem = DispatchWorkItem { [weak self] in
                self?.sendSearchRequests()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
            return workItem
        }
    }

    private func openSocket() throws {
        let multicastSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: DispatchQueue.main)
        multicastSocket.setIPv4Enabled(true)
        multicastSocket.setIPv6Enabled(true)

        do {
            try multicastSocket.enableReusePort(true)
            try multicastSocket.enableBroadcast(true)
            try multicastSocket.bind(toPort: multicastUDPPort)
            try multicastSocket.joinMulticastGroup(multicastGroupAddress)
            try multicastSocket.beginReceiving()
        }
        catch {
            // Not stored yet, so the close callback ignores it.
            multicastSocket.close()
            throw error
        }

        self.multicastSocket = multicastSocket
    }

    private func sendSearchRequests() {
        guard let multicastSocket = multicastSocket else { return }

        for type in types {
            if let data = self.searchRequestData(forType: type) {
                multicastSocket.send(data, toHost: multicastGroupAddress, port: multicastUDPPort, withTimeout: 3, tag: type.hashValue)
            }
        }
    }

    /// Open a new socket and search again, after the old one closed without being asked to (e.g. the network went
    /// away), or after a network change (the multicast group has to be joined on the new interface).
    private func reopenSocket(after delay: TimeInterval) {
        reopenWorkItem?.cancel()
        let generation = self.generation
        let workItem = DispatchWorkItem { [weak self] in
            guard let self, self.generation == generation, !self.types.isEmpty else { return }
            if let multicastSocket = self.multicastSocket {
                self.multicastSocket = nil
                multicastSocket.close()
            }
            do {
                try self.openSocket()
                self.searchRequest()
            }
            catch {
                Logger.swiftUPnP.error("Could not reopen the SSDP socket: \(error.localizedDescription)")
                self.reopenSocket(after: 5)
            }
        }
        reopenWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
    }

    private func startMonitoringNetworkChanges() {
        pathMonitor?.cancel()
        let monitor = NWPathMonitor()
        var isFirstUpdate = true
        monitor.pathUpdateHandler = { [weak self] path in
            // The first update only reports the current situation.
            guard !isFirstUpdate else {
                isFirstUpdate = false
                return
            }
            guard path.status == .satisfied else { return }
            self?.reopenSocket(after: 1)
        }
        monitor.start(queue: DispatchQueue.main)
        pathMonitor = monitor
    }
}

extension SSDPCocoaAsyncSocketDiscovery: GCDAsyncUdpSocketDelegate {
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didNotSendDataWithTag tag: Int, dueToError error: Error?) {
        // Not a reason to give up: searches are repeated, and the socket still receives announcements.
        Logger.swiftUPnP.error("Could not send SSDP search: \(error?.localizedDescription ?? "unknown error")")
    }
    
    public func udpSocketDidClose(_ sock: GCDAsyncUdpSocket, withError error: Error?) {
        // Closed by stopDiscovery or reopenSocket: nothing to do.
        guard sock === multicastSocket else { return }
        multicastSocket = nil
        reopenSocket(after: 2)
    }
    
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        processData(data)
    }
}
