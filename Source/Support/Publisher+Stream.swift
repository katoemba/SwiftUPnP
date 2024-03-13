//
//  Published+Stream.swift
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
//  Created by Guillaume BITAUDEAU - https://forums.swift.org/t/how-to-use-combine-publisher-with-swift-concurrency-publisher-values-could-miss-events/67193/5
//


import Foundation
import Combine

internal extension Publisher where Failure == Never {
    var stream: AsyncStream<Output> {
        AsyncStream { continuation in
            let cancellable = self.sink { completion in
                continuation.finish()
            } receiveValue: { value in
                 continuation.yield(value)
            }
            continuation.onTermination = { continuation in
                cancellable.cancel()
            }
        }
    }
}

internal extension Publisher where Failure: Error {
    var stream: AsyncThrowingStream<Output, Error> {
        AsyncThrowingStream<Output, Error> { continuation in
            let cancellable = self.sink { completion in
                switch completion {
                case .finished:
                    continuation.finish()
                case .failure(let error):
                    continuation.finish(throwing: error)
                }
            } receiveValue: { value in
                 continuation.yield(value)
            }
            continuation.onTermination = { continuation in
                cancellable.cancel()
            }
        }
    }
}
