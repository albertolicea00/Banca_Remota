import Foundation
import UIKit
import CryptoKit

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

// MARK: - Keychain Helper
class KeychainHelper {
    static let shared = KeychainHelper()
    
    func save(_ string: String, service: String, account: String) {
        guard let data = string.data(using: .utf8) else { return }
        let query = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ] as [String: Any]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func read(service: String, account: String) -> String? {
        let query = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ] as [String: Any]
        
        var dataTypeRef: AnyObject?
        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == noErr, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    func delete(service: String, account: String) {
        let query = [
            kSecClass as String: kSecClassGenericPassword as String,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ] as [String: Any]
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - User Backup Structure
struct UserBackup: Codable {
    var nautaAccounts: [NautaAccount]?
    var bankAccounts: [BankAccount]?
    var bills: [Bill]?
    var userKeys: [UserKey]?
    var timestamp: Date = Date()
}

// MARK: - User Data Service (CRUD)
class UserDataManager: ObservableObject {
    static let shared = UserDataManager()
    
    @AppStorage("iCloudSyncEnabled") var iCloudSyncEnabled = false
    @Published var iCloudEncryptionPassword = "" {
        didSet {
            KeychainHelper.shared.save(iCloudEncryptionPassword, service: "BancaRemota", account: "SyncPassword")
        }
    }
    
    @Published var nautaAccounts: [NautaAccount] = [] { didSet { save() } }
    @Published var bankAccounts: [BankAccount] = [] { didSet { save() } }
    @Published var bills: [Bill] = [] { didSet { save() } }
    @Published var userKeys: [UserKey] = [] { didSet { save() } }
    @Published var activeSwipeID: UUID? = nil
    
    private init() {
        iCloudEncryptionPassword = KeychainHelper.shared.read(service: "BancaRemota", account: "SyncPassword") ?? ""
        load()
        setupICloudNotifications()
    }
    
    private func setupICloudNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(iCloudDataDidChange),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default
        )
        NSUbiquitousKeyValueStore.default.synchronize()
    }
    
    @objc private func iCloudDataDidChange(notification: Notification) {
        if iCloudSyncEnabled {
            DispatchQueue.main.async {
                self.loadFromICloud()
            }
        }
    }
    
    func createBackup(includeNauta: Bool, includeBanks: Bool, includeBills: Bool, includeKeys: Bool) -> URL? {
        let backup = UserBackup(
            nautaAccounts: includeNauta ? nautaAccounts : nil,
            bankAccounts: includeBanks ? bankAccounts : nil,
            bills: includeBills ? bills : nil,
            userKeys: includeKeys ? userKeys : nil
        )
        
        guard let data = try? JSONEncoder().encode(backup) else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmm"
        let dateString = formatter.string(from: Date())
        let fileName = "BancaRemota_Backup_\(dateString).json"
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try? data.write(to: tempURL)
        return tempURL
    }
    
    func importBackup(from url: URL) -> Bool {
        guard let data = try? Data(contentsOf: url),
              let backup = try? JSONDecoder().decode(UserBackup.self, from: data) else {
            return false
        }
        
        if let nauta = backup.nautaAccounts { self.nautaAccounts = nauta }
        if let banks = backup.bankAccounts { self.bankAccounts = banks }
        if let bills = backup.bills { self.bills = bills }
        if let keys = backup.userKeys { self.userKeys = keys }
        
        return true
    }
    
    private func save() {
        // Local save
        if let encoded = try? JSONEncoder().encode(nautaAccounts) { UserDefaults.standard.set(encoded, forKey: "nautaAccounts") }
        if let encoded = try? JSONEncoder().encode(bankAccounts) { UserDefaults.standard.set(encoded, forKey: "bankAccounts") }
        if let encoded = try? JSONEncoder().encode(bills) { UserDefaults.standard.set(encoded, forKey: "bills") }
        if let encoded = try? JSONEncoder().encode(userKeys) { UserDefaults.standard.set(encoded, forKey: "userKeys") }
        
        // iCloud save
        if iCloudSyncEnabled {
            let store = NSUbiquitousKeyValueStore.default
            
            if let encoded = try? JSONEncoder().encode(nautaAccounts), let encrypted = encryptData(encoded) { store.set(encrypted, forKey: "nautaAccounts") }
            if let encoded = try? JSONEncoder().encode(bankAccounts), let encrypted = encryptData(encoded) { store.set(encrypted, forKey: "bankAccounts") }
            if let encoded = try? JSONEncoder().encode(bills), let encrypted = encryptData(encoded) { store.set(encrypted, forKey: "bills") }
            if let encoded = try? JSONEncoder().encode(userKeys), let encrypted = encryptData(encoded) { store.set(encrypted, forKey: "userKeys") }
            
            store.synchronize()
        }
    }
    
    private func load() {
        // First try local
        if let data = UserDefaults.standard.data(forKey: "nautaAccounts"), let decoded = try? JSONDecoder().decode([NautaAccount].self, from: data) { nautaAccounts = decoded }
        if let data = UserDefaults.standard.data(forKey: "bankAccounts"), let decoded = try? JSONDecoder().decode([BankAccount].self, from: data) { bankAccounts = decoded }
        if let data = UserDefaults.standard.data(forKey: "bills"), let decoded = try? JSONDecoder().decode([Bill].self, from: data) { bills = decoded }
        if let data = UserDefaults.standard.data(forKey: "userKeys"), let decoded = try? JSONDecoder().decode([UserKey].self, from: data) { userKeys = decoded }
        
        // If iCloud enabled, try to merge/update from iCloud
        if iCloudSyncEnabled {
            loadFromICloud()
        }
    }
    
    private func loadFromICloud() {
        let store = NSUbiquitousKeyValueStore.default
        
        if let data = store.data(forKey: "nautaAccounts"), let decrypted = decryptData(data), let decoded = try? JSONDecoder().decode([NautaAccount].self, from: decrypted) { nautaAccounts = decoded }
        if let data = store.data(forKey: "bankAccounts"), let decrypted = decryptData(data), let decoded = try? JSONDecoder().decode([BankAccount].self, from: decrypted) { bankAccounts = decoded }
        if let data = store.data(forKey: "bills"), let decrypted = decryptData(data), let decoded = try? JSONDecoder().decode([Bill].self, from: decrypted) { bills = decoded }
        if let data = store.data(forKey: "userKeys"), let decrypted = decryptData(data), let decoded = try? JSONDecoder().decode([UserKey].self, from: decrypted) { userKeys = decoded }
    }
    
    // MARK: - Encryption Helpers
    private func encryptData(_ data: Data) -> Data? {
        guard !iCloudEncryptionPassword.isEmpty else { return data }
        let key = SHA256.hash(data: Data(iCloudEncryptionPassword.utf8))
        let symmetricKey = SymmetricKey(data: key)
        do {
            let sealedBox = try AES.GCM.seal(data, using: symmetricKey)
            return sealedBox.combined
        } catch {
            print("Encryption error: \(error)")
            return nil
        }
    }
    
    private func decryptData(_ data: Data) -> Data? {
        guard !iCloudEncryptionPassword.isEmpty else { 
            // If no password, we assume it's unencrypted or we can't decrypt it
            return data 
        }
        let key = SHA256.hash(data: Data(iCloudEncryptionPassword.utf8))
        let symmetricKey = SymmetricKey(data: key)
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            return try AES.GCM.open(sealedBox, using: symmetricKey)
        } catch {
            print("Decryption error: \(error)")
            // If decryption fails, maybe the data is not encrypted (legacy)
            return data 
        }
    }
}
