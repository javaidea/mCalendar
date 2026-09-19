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
