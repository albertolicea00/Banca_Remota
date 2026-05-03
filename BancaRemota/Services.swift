import Foundation
import UIKit

// MARK: - Data Management Service
class DataService {
    static let shared = DataService()
    
    private init() {}
    
    /// Loads the bank configuration from the bundled codes.json file
    func loadConfiguration() -> BankConfig? {
        guard let url = Bundle.main.url(forResource: "codes", withExtension: "json") else {
            print("Error: Could not locate codes.json in bundle.")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let config = try decoder.decode(BankConfig.self, from: data)
            return config
        } catch {
            print("Error: Failed to parse codes.json: \(error)")
            return nil
        }
    }
}

import LocalAuthentication
import SwiftUI

// MARK: - Authentication Service
class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @AppStorage("authEnabled") private var authEnabled: Bool = false
    @AppStorage("authExpiration") private var authExpiration: Double = 1.0
    @AppStorage("lastAuthTime") private var lastAuthTime: Double = 0
    
    @Published var isAuthenticated: Bool = false
    @Published var isAuthenticating: Bool = false
    
    private init() {
        checkExpiration()
    }
    
    func checkExpiration() {
        if !authEnabled {
            isAuthenticated = true
            return
        }
        
        let now = Date().timeIntervalSince1970
        let expirationSeconds = authExpiration * 60.0
        
        if (now - lastAuthTime) > expirationSeconds {
            isAuthenticated = false
        } else {
            isAuthenticated = true
        }
    }
    
    func authenticate() {
        if !authEnabled {
            isAuthenticated = true
            return
        }
        
        let context = LAContext()
        var error: NSError?
        let reason = "Autentícate para acceder a Banca Remota"
        
        let policy: LAPolicy = .deviceOwnerAuthentication
        
        if context.canEvaluatePolicy(policy, error: &error) {
            isAuthenticating = true
            context.evaluatePolicy(policy, localizedReason: reason) { success, _ in
                DispatchQueue.main.async {
                    self.isAuthenticating = false
                    if success {
                        self.isAuthenticated = true
                        self.lastAuthTime = Date().timeIntervalSince1970
                    }
                }
            }
        } else {
            self.isAuthenticated = true
        }
    }
}

// MARK: - Telephony/USSD Service
class CallService {
    static let shared = CallService()
    
    private init() {}
    
    /// Executes a USSD code by opening the system dialer
    func executeUSSD(code: String) {
        // Encodings like # need to be %23 in URL scheme
        let encodedCode = code.addingPercentEncoding(withAllowedCharacters: CharacterSet(charactersIn: "#").inverted) ?? code
        
        guard let url = URL(string: "tel://\(encodedCode)") else {
            print("Error: Invalid URL format for code: \(code)")
            return
        }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:]) { success in
                if success {
                    print("Service: Successfully opened USSD code: \(code)")
                } else {
                    print("Service: Failed to open USSD code: \(code)")
                }
            }
        } else {
            print("Error: Cannot open tel:// URL on this device (Simulator or restricted).")
        }
    }
}

// MARK: - User Data Service (CRUD)
class UserDataManager: ObservableObject {
    static let shared = UserDataManager()
    
    @Published var nautaAccounts: [NautaAccount] = [] { didSet { save() } }
    @Published var bankAccounts: [BankAccount] = [] { didSet { save() } }
    @Published var bills: [Bill] = [] { didSet { save() } }
    @Published var userKeys: [UserKey] = [] { didSet { save() } }
    
    private init() {
        load()
    }
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(nautaAccounts) { UserDefaults.standard.set(encoded, forKey: "nautaAccounts") }
        if let encoded = try? JSONEncoder().encode(bankAccounts) { UserDefaults.standard.set(encoded, forKey: "bankAccounts") }
        if let encoded = try? JSONEncoder().encode(bills) { UserDefaults.standard.set(encoded, forKey: "bills") }
        if let encoded = try? JSONEncoder().encode(userKeys) { UserDefaults.standard.set(encoded, forKey: "userKeys") }
    }
    
    private func load() {
        if let data = UserDefaults.standard.data(forKey: "nautaAccounts"), let decoded = try? JSONDecoder().decode([NautaAccount].self, from: data) { nautaAccounts = decoded }
        if let data = UserDefaults.standard.data(forKey: "bankAccounts"), let decoded = try? JSONDecoder().decode([BankAccount].self, from: data) { bankAccounts = decoded }
        if let data = UserDefaults.standard.data(forKey: "bills"), let decoded = try? JSONDecoder().decode([Bill].self, from: data) { bills = decoded }
        if let data = UserDefaults.standard.data(forKey: "userKeys"), let decoded = try? JSONDecoder().decode([UserKey].self, from: data) { userKeys = decoded }
    }
}
