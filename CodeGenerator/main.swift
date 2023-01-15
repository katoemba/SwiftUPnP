//
//  main.swift
//  UPnPGenerator
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
        
        let url = URL(filePath: filePath)
        let data = try! Data(contentsOf: url)
        let decoder = XMLDecoder()
        decoder.shouldProcessNamespaces = true
        do {
            let scdp = try decoder.decode(scdp.self, from: data)
            if let serviceData = scdp.generateSource(serviceName: serviceName).data(using: .utf8) {
                let targetURL = URL(filePath: "\(path)/\(serviceName).swift")
                try serviceData.write(to: targetURL)
            }
        }
        catch {
            print(error.localizedDescription)
        }
    }
}
