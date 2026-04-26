import Foundation

enum WCSErrorFormatting {
    static func userFacingMessage(for error: Error) -> String {
        let ns = error as NSError
        if ns.domain == NSURLErrorDomain {
            switch ns.code {
            case NSURLErrorNotConnectedToInternet, NSURLErrorDataNotAllowed:
                return "You appear to be offline. Check your connection and try again."
            case NSURLErrorTimedOut:
                return "The request timed out. Try again in a moment."
            case NSURLErrorCannotFindHost, NSURLErrorDNSLookupFailed:
                return "Could not reach the server. Verify the site URL and your network."
            case NSURLErrorCancelled:
                return "Loading was cancelled."
            default:
                break
            }
        }
        return error.localizedDescription
    }
}
