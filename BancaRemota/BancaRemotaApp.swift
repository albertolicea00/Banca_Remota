import SwiftUI

// MARK: - Main Application Entry
@main
struct BancaRemotaApp: App {
    @AppStorage("darkModePreference") private var darkModePreference: Int = 0
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .preferredColorScheme(darkModePreference == 1 ? .light : (darkModePreference == 2 ? .dark : nil))
        }
    }
}
