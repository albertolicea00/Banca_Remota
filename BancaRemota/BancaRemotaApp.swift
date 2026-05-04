import SwiftUI

// MARK: - Main Application Entry
@main
struct BancaRemotaApp: App {
    @AppStorage("darkModePreference") private var darkModePreference: Int = 0
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("useCustomFavoriteColor") private var useCustomFavoriteColor = true
    @AppStorage("favoriteCustomColorHex") private var favoriteCustomColorHex = "B38B4D"
    @StateObject private var authManager = AuthManager.shared
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                MainView()
                    .preferredColorScheme(darkModePreference == 1 ? .light : (darkModePreference == 2 ? .dark : nil))
                
                if !authManager.isAuthenticated {
                    Color(UIColor.systemBackground).ignoresSafeArea()
                    VStack(spacing: 20) {
                        Image(systemName: "lock.shield")
                            .font(.system(size: 60))
                            .foregroundColor(.appPrimary)
                        Text("Aplicación Bloqueada")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Tu identidad debe ser verificada antes de acceder.")
                            .font(.footnote) 
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                        Button(action: {
                            authManager.authenticate()
                        }) {
                            Text("Desbloquear")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(width: 200)
                                .background(Color.appPrimary)
                                .cornerRadius(12)
                        }
                    }
                    .preferredColorScheme(darkModePreference == 1 ? .light : (darkModePreference == 2 ? .dark : nil))
                }
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                authManager.checkExpiration()
                if !authManager.isAuthenticated && !authManager.isAuthenticating {
                    authManager.authenticate()
                }
            }
        }
    }
}

