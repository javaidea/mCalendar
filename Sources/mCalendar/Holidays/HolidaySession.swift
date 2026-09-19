import Foundation

/// The session for every holiday download -- the app's only network access.
///
/// PRIVACY.md lists exactly what a request carries, so nothing is left to
/// system defaults: no cookies, no cache, and fixed headers instead of the
/// default User-Agent (app build, OS version) and Accept-Language (the user's
/// preferred languages).
let holidaySession: URLSession = {
    let config = URLSessionConfiguration.ephemeral
    config.httpCookieStorage = nil
    config.httpShouldSetCookies = false
    config.urlCache = nil
    config.httpAdditionalHeaders = ["User-Agent": "MiniCalendar", "Accept-Language": "en"]
    config.timeoutIntervalForRequest = 10
    return URLSession(configuration: config)
}()

extension URLSession {
    /// The body of a 200 response, or nil on any error or other status.
    func fetchData(from url: URL) async -> Data? {
        guard let (data, response) = try? await data(from: url),
              (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
        return data
    }
}
