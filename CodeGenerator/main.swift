//
//  main.swift
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
//  Created by Berrie Kremers on 06/01/2023.
//

import Foundation
import XMLCoder

guard CommandLine.argc == 2 else {
    fatalError("Expected path argument")
}
let path = CommandLine.arguments[1]
let fileManager = FileManager()
guard let dirEnumerator = fileManager.enumerator(atPath: path) else {
    fatalError("Couldn't get files at path \(path)")
}
while let file = dirEnumerator.nextObject() as? String {
    if file.hasSuffix(".xml") {
        let filePath = path + "/" + file
        let serviceName = file.replacingOccurrences(of: ".xml", with: "")
        print("Processing \(serviceName) in \(filePath)")
        
        let url = URL(fileURLWithPath: filePath)
        let data = try! Data(contentsOf: url)
        let decoder = XMLDecoder()
        decoder.shouldProcessNamespaces = true
        do {
            let scdp = try decoder.decode(scdp.self, from: data)
            if let serviceData = scdp.generateSource(serviceName: serviceName).data(using: .utf8) {
                let targetURL = URL(fileURLWithPath: "\(path)/\(serviceName).swift")
                try serviceData.write(to: targetURL)
            }
        }
        catch {
            print(error.localizedDescription)
        }
    }
}
