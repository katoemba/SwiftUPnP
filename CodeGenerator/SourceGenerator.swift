//
//  SourceGenerator.swift
//  UPnPGenerator
//
//  Created by Berrie Kremers on 07/01/2023.
//

import Foundation

extension scdp {
    func generateSource(serviceName: String) -> String {
        var code = ""
        
        code += generateHeader(serviceName: serviceName)
        code += "\n"
        code += generateEnums()
        code += generateActions()
        code += "}\n"
        code += "\n"
        code += generateEvent(serviceName: serviceName)

        return code
    }
    
    func generateHeader(serviceName: String) -> String {
        var code = ""
        
        code += "import Foundation\n"
        code += "import Combine\n"
        code += "import XMLCoder\n"
        code += "\n"
        code += "public class \(serviceName): UPnPService {\n"
        code += "\tstruct Envelope<T: Codable>: Codable {\n"
        code += "\t\tenum CodingKeys: String, CodingKey {\n"
        code += "\t\t\tcase body = \"s:Body\"\n"
        code += "\t\t}\n"
        code += "\n"
        code += "\t\tvar body: T\n"
        code += "\t}\n"

        return code
    }
    
    func generateEnums() -> String {
        var code = ""
        
        for enumVariable in serviceStateTable.stateVariable {
            if enumVariable.useEnum {
                code += "\tpublic enum \(enumVariable.swiftType): String, Codable {\n"
                for value in enumVariable.allowedValueList?.allowedValue ?? [] {
                    code += "\t\tcase \(value.uncapitalizeFirstLetter()) = \"\(value)\"\n"
                }
                code += "\t}\n"
                code += "\n"
            }
        }
        
        return code
    }
    
    func generateActions() -> String {
        var code = ""
        
        for action in actionList.action {
            if action.hasOutput {
                code += generateResponseStruct(action)
            }
            code += generateActionFunc(action)
        }
        
        return code
    }
    
    func generateResponseStruct(_ action: Action) -> String {
        var code = ""
        
        code += "\tpublic struct \(action.name)Response: Codable {\n"
        code += "\t\tenum CodingKeys: String, CodingKey {\n"
        for argument in action.outArguments {
            if typeFor(argument) == .bin_base64 {
                code += "\t\t\tcase \(argument.name.uncapitalizeFirstLetter())Data = \"\(argument.name)\"\n"
            }
            else {
                code += "\t\t\tcase \(argument.name.uncapitalizeFirstLetter()) = \"\(argument.name)\"\n"
            }
        }
        code += "\t\t}\n"
        code += "\n"
        
        for argument in action.outArguments {
            if typeFor(argument) == .bin_base64 {
                code += "\t\tpublic var \(argument.name.uncapitalizeFirstLetter())Data: Data?\n"
                code += "\t\tpublic var \(argument.name.uncapitalizeFirstLetter()): [UInt32]? {\n"
                code += "\t\t\t\(argument.name.uncapitalizeFirstLetter())Data?.toArray(type: UInt32.self).map { $0.bigEndian }\n"
                code += "\t\t}\n"
            }
            else {
                code += "\t\tpublic var \(argument.name.uncapitalizeFirstLetter()): \(swiftTypeFor(argument))\n"
            }
        }
        code += "\t}\n"

        return code
    }
    
    func generateActionFunc(_ action: Action) -> String {
        var code = ""
        var separator = ""
        
        code += "\tpublic func \(action.name.uncapitalizeFirstLetter())("
        for argument in action.inArguments {
            code += "\(separator)\(argument.name.uncapitalizeFirstLetter()): \(swiftTypeFor(argument))"
            separator = ", "
        }
        if action.hasOutput {
            code += ") async throws -> \(action.name)Response {\n"
        }
        else {
            code += ") async throws {\n"
        }
        code += generateSoapActionStruct(action)
        code += generateBodyStruct(action)
        
        if action.hasOutput {
            code += "\t\tlet result: Envelope<Body> = try await postWithResult(action: \"\(action.name)\", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)"
            for argument in action.inArguments {
                code += ", \(argument.name.uncapitalizeFirstLetter()): \(argument.name.uncapitalizeFirstLetter())"
            }
            code += "))))\n"
            code += "\n"
            code += "\t\tguard let response = result.body.response else { throw ServiceParseError.noValidResponse }\n"
            code += "\t\treturn response\n"
        }
        else {
            code += "\t\ttry await post(action: \"\(action.name)\", envelope: Envelope(body: Body(action: SoapAction(urn: Attribute(serviceType)"
            for argument in action.inArguments {
                code += ", \(argument.name.uncapitalizeFirstLetter()): \(argument.name.uncapitalizeFirstLetter())"
            }
            code += "))))\n"
        }
        code += "\t}\n"
        code += "\n"

        return code
    }
    
    func generateSoapActionStruct(_ action: Action) -> String {
        var code = ""
        
        code += "\t\tstruct SoapAction: Codable {\n"
        code += "\t\t\tenum CodingKeys: String, CodingKey {\n"
        code += "\t\t\t\tcase urn = \"xmlns:u\"\n"
        for argument in action.inArguments {
            code += "\t\t\t\tcase \(argument.name.uncapitalizeFirstLetter()) = \"\(argument.name)\"\n"
        }
        code += "\t\t\t}\n"
        code += "\n"
        
        code += "\t\t\t@Attribute var urn: String\n"
        for argument in action.inArguments {
            code += "\t\t\tpublic var \(argument.name.uncapitalizeFirstLetter()): \(swiftTypeFor(argument))\n"
        }
        code += "\t\t}\n"

        return code
    }
    
    func generateBodyStruct(_ action: Action) -> String {
        var code = ""
        
        code += "\t\tstruct Body: Codable {\n"
        code += "\t\t\tenum CodingKeys: String, CodingKey {\n"
        code += "\t\t\t\tcase action = \"u:\(action.name)\"\n"
        code += "\t\t\t}\n"
        code += "\n"
        
        if action.hasOutput {
            code += "\t\t\tvar action: SoapAction?\n"
            code += "\t\t\tvar response: \(action.name)Response?\n"
        }
        else {
            code += "\t\t\tvar action: SoapAction\n"
        }
        code += "\t\t}\n"

        return code
    }

    func generateEvent(serviceName: String) -> String {
        var code = ""

        code += "// Event parser\n"
        code += "extension \(serviceName) {\n"
        code += generateStateStruct(serviceName: serviceName)
        code += "\n"
        code += generateStateFunc(serviceName: serviceName)
        code += "\n"
        code += generateStateSubject()
        code += "}\n"

        return code
    }
    
    func generateStateStruct(serviceName: String) -> String {
        var code = ""
        
        code += "\tpublic struct State: Codable {\n"
        code += "\t\tenum CodingKeys: String, CodingKey {\n"
        for stateVariable in serviceStateTable.stateVariable.filter({ $0.sendEvents.lowercased() == "yes" }) {
            if stateVariable.dataType == .bin_base64 {
                code += "\t\t\tcase \(stateVariable.name.uncapitalizeFirstLetter())Data = \"\(stateVariable.name)\"\n"
            }
            else {
                code += "\t\t\tcase \(stateVariable.name.uncapitalizeFirstLetter()) = \"\(stateVariable.name)\"\n"
            }
        }
        code += "\t\t}\n"
        code += "\n"
        for stateVariable in serviceStateTable.stateVariable.filter({ $0.sendEvents.lowercased() == "yes" }) {
            if stateVariable.dataType == .bin_base64 {
                code += "\t\tpublic var \(stateVariable.name.uncapitalizeFirstLetter())Data: Data?\n"
                code += "\t\tpublic var \(stateVariable.name.uncapitalizeFirstLetter()): [UInt32]? {\n"
                code += "\t\t\t\(stateVariable.name.uncapitalizeFirstLetter())Data?.toArray(type: UInt32.self).map { $0.bigEndian }\n"
                code += "\t\t}\n"
            }
            else {
                code += "\t\tpublic var \(stateVariable.name.uncapitalizeFirstLetter()): \(stateVariable.swiftType)?\n"
            }
        }
        code += "\t}\n"
        
        return code
    }
    
    func generateStateFunc(serviceName: String) -> String {
        var code = ""
        
        code += "\tpublic func state(xml: Data) throws -> State {\n"
        code += "\t\tstruct PropertySet: Codable {\n"
        code += "\t\t\tvar property: [State]\n"
        code += "\t\t}\n"
        code += "\n"
        code += "\t\tlet decoder = XMLDecoder()\n"
        code += "\t\tdecoder.shouldProcessNamespaces = true\n"
        code += "\t\tlet propertySet = try decoder.decode(PropertySet.self, from: xml)\n"
        code += "\n"
        code += "\t\treturn propertySet.property.reduce(State()) { partialResult, property in\n"
        code += "\t\t\tvar result = partialResult\n"
        for stateVariable in serviceStateTable.stateVariable.filter({ $0.sendEvents.lowercased() == "yes" }) {
            let variable = stateVariable.name.uncapitalizeFirstLetter() + ((stateVariable.dataType == .bin_base64) ? "Data" : "")
            code += "\t\t\tif let \(variable) = property.\(variable) {\n"
            code += "\t\t\t\tresult.\(variable) = \(variable)\n"
            code += "\t\t\t}\n"
        }
        code += "\t\t\treturn result\n"
        code += "\t\t}\n"
        code += "\t}\n"

        return code
    }
    
    func generateStateSubject() -> String {
        var code = ""

        code += "\tpublic var stateSubject: AnyPublisher<State, Never> {\n"
        code += "\t\tsubscribedEventPublisher\n"
        code += "\t\t\t.compactMap { [weak self] in\n"
        code += "\t\t\t\tguard let self else { return nil }\n"
        code += "\n"
        code += "\t\t\t\treturn try? self.state(xml: $0)\n"
        code += "\t\t\t}\n"
        code += "\t\t\t.eraseToAnyPublisher()\n"
        code += "\t}\n"

        return code
    }
    
    func typeFor(_ argument: Argument) -> StateVariable.DataType {
        serviceStateTable.stateVariable.first(where: { $0.name == argument.relatedStateVariable })!.dataType
    }

    func swiftTypeFor(_ argument: Argument) -> String {
        serviceStateTable.stateVariable.first(where: { $0.name == argument.relatedStateVariable })!.swiftType
    }
}

extension String {
    func uncapitalizeFirstLetter() -> String {
        let variable = prefix(1).lowercased() + dropFirst()
        if variable == "repeat" {
            return "`repeat`"
        }
        return variable
    }
}
