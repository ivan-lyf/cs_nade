import Foundation

/// Backend configuration. Fill in from the Supabase dashboard (Settings →
/// API) once the project exists. Empty values mean "backend not configured":
/// the app hides all networked features and stays fully local — the library
/// itself never needs any of this.
enum SupabaseConfig {
    /// Project ref jtlsobutxksdiekrhhbe (see .mcp.json).
    static let projectURL = "https://jtlsobutxksdiekrhhbe.supabase.co"

    /// The public API key (modern publishable key; the legacy JWT anon key
    /// also works). Safe to ship in the binary; RLS enforces access.
    static let anonKey = "sb_publishable_6pq01qh1koQp9As6fibAeQ_TTZeoRHn"

    /// Domain that serves the AASA file + web fallback for universal links
    /// (backend/aasa, backend/web-fallback). Until it exists, share links use
    /// the csnade:// custom scheme, which works app-to-app without a domain.
    static let shareDomain = ""

    static var isConfigured: Bool {
        !projectURL.isEmpty && !anonKey.isEmpty && URL(string: projectURL) != nil
    }
}
