import Foundation
import Supabase

/// The single shared Supabase client. Nil until `SupabaseConfig` is filled in;
/// callers treat nil as "backend features unavailable".
enum SupabaseClientProvider {
    static let client: SupabaseClient? = {
        guard SupabaseConfig.isConfigured,
              let url = URL(string: SupabaseConfig.projectURL) else { return nil }
        return SupabaseClient(supabaseURL: url, supabaseKey: SupabaseConfig.anonKey)
    }()
}
