#if DEBUG
import Foundation

/// Launch arguments that force UI states for headless QA screenshots.
/// Debug builds only; never ships.
enum DebugFlags {
    /// `-open-create` — present the create form on launch.
    static var openCreate: Bool {
        ProcessInfo.processInfo.arguments.contains("-open-create")
    }

    /// `-open-detail` — open the first throw's detail on launch.
    static var openDetail: Bool {
        ProcessInfo.processInfo.arguments.contains("-open-detail")
    }

    /// `-open-signin` — present the sign-in screen on launch.
    static var openSignIn: Bool {
        ProcessInfo.processInfo.arguments.contains("-open-signin")
    }

    /// `-open-import` — present the import sheet on launch (unconfigured
    /// backends show its error state; the sheet chrome is what's under test).
    static var openImport: Bool {
        ProcessInfo.processInfo.arguments.contains("-open-import")
    }
}
#endif
