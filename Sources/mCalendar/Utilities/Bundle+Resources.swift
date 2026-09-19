import Foundation

extension Bundle {
    /// Where the files in `Resources/` end up: the app bundle when built with
    /// Xcode, SwiftPM's generated resource bundle under `swift run`.
    static var resources: Bundle {
        #if SWIFT_PACKAGE
        return .module
        #else
        return .main
        #endif
    }

    /// Decodes a JSON file from `Resources/`, or nil if it is missing or malformed.
    func decodeJSON<T: Decodable>(_ type: T.Type, named name: String) -> T? {
        guard let url = url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}
