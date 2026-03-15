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
