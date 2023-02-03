import Foundation
extension KeyAppEvent {
    var eventName: String? {
        mirror.label.snakeAndFirstUppercased
    }

    var params: [String: Any]? {
        guard !mirror.params.isEmpty else { return nil }
        let formatted = mirror.params.map { ($0.key.snakeAndFirstUppercased ?? "", $0.value) }
        return Dictionary(uniqueKeysWithValues: formatted)
    }
}

extension String {
    var snakeAndFirstUppercased: String? {
        guard let snakeCase = snakeCased() else { return nil }
        return snakeCase.prefix(1).uppercased() + snakeCase.dropFirst()
    }
    
    func snakeCased() -> String? {
        let pattern = "([a-z0-9])([A-Z])"

        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: count)
        return regex?.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "$1_$2")
            .uppercaseFirst
    }
}
