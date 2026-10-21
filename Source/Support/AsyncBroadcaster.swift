//
//  AsyncBroadcaster.swift
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

import Foundation

/// Hands everything it is given to each of its listeners, who each read from a stream of their own.
///
/// This is what a `PassthroughSubject` was used for before: one source, any number of listeners,
/// none of whom see what was sent before they started listening. A listener that goes away is
/// dropped, and listening from somewhere that no longer exists is not an error - devices announce
/// themselves and send state changes whether or not anybody is interested.
///
/// Values are buffered per listener rather than dropped, because every event carries a piece of
/// state that is reported once: a listener that is slow falls behind, it doesn't lose changes.
final class AsyncBroadcaster<Element: Sendable>: @unchecked Sendable {
    private let lock = NSLock()
    private var continuations = [UUID: AsyncStream<Element>.Continuation]()
    private var isFinished = false

    /// A stream of everything that is sent from now on. Every call returns a stream of its own, so
    /// one listener reading does not take values away from another.
    var stream: AsyncStream<Element> {
        AsyncStream(bufferingPolicy: .unbounded) { continuation in
            let id = UUID()

            lock.lock()
            guard isFinished == false else {
                lock.unlock()
                continuation.finish()
                return
            }
            continuations[id] = continuation
            lock.unlock()

            // Reached when the listener stops reading or its task is cancelled, which is the only
            // signal that a listener is gone.
            continuation.onTermination = { [weak self] _ in
                guard let self else { return }

                self.lock.lock()
                self.continuations.removeValue(forKey: id)
                self.lock.unlock()
            }
        }
    }

    /// Whether anybody is listening. Not a reason to skip sending, but it does say whether a
    /// subscription is being read by anyone.
    var hasListeners: Bool {
        lock.lock(); defer { lock.unlock() }
        return continuations.isEmpty == false
    }

    func send(_ element: Element) {
        lock.lock()
        let continuations = self.continuations
        lock.unlock()

        // Outside the lock: a listener's buffer is its own, and yielding must not block the thread
        // an event arrived on behind another listener.
        for continuation in continuations.values {
            continuation.yield(element)
        }
    }

    /// End every stream. Nothing can be sent afterwards, and a listener that starts later gets a
    /// stream that is immediately done.
    func finish() {
        lock.lock()
        let continuations = self.continuations
        self.continuations.removeAll()
        isFinished = true
        lock.unlock()

        for continuation in continuations.values {
            continuation.finish()
        }
    }
}
