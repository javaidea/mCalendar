import Foundation

extension URLSession {
    /// The body of a 200 response, or nil on any error or other status.
    func fetchData(from url: URL) async -> Data? {
        guard let (data, response) = try? await data(from: url),
              (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
        return data
    }
}
