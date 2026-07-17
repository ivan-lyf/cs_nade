import Foundation

/// A parsed incoming share link, wrapped for sheet presentation. RootView's
/// `onOpenURL` produces one from either link form (universal link or the
/// csnade:// scheme) via `ShareLinkBuilder.code(from:)`.
struct PendingImport: Identifiable {
    let code: String
    var id: String { code }
}
