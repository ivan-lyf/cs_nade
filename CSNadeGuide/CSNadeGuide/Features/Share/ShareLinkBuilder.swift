import Foundation

/// Builds and parses shared-tactic links. With a share domain configured the
/// canonical form is `https://<domain>/t/<code>` (universal link; AASA and
/// web fallback live in backend/). Without one, the `csnade://t/<code>`
/// custom scheme works app-to-app with zero infrastructure.
enum ShareLinkBuilder {
    static func url(for code: String) -> URL {
        if !SupabaseConfig.shareDomain.isEmpty,
           let url = URL(string: "https://\(SupabaseConfig.shareDomain)/t/\(code)") {
            return url
        }
        return URL(string: "csnade://t/\(code)")!
    }

    /// Extracts a share code from either link form; nil for foreign URLs.
    static func code(from url: URL) -> String? {
        if url.scheme == "csnade" {
            // csnade://t/<code> parses as host "t", path "/<code>".
            guard url.host == "t" else { return nil }
            let code = url.lastPathComponent
            return code.isEmpty || code == "/" ? nil : code
        }
        if url.scheme == "https" {
            let parts = url.pathComponents   // ["/", "t", "<code>"]
            guard parts.count >= 3, parts[1] == "t" else { return nil }
            return parts[2]
        }
        return nil
    }
}
