import SwiftUI

// MARK: - Top Nav Bar
struct TopNavBar: View {
    var themeColor: Color
    var onMenuTap: () -> Void
    var showMenuBtn: Bool = true
    var bank: Bank? = nil
    var title: String? = nil
    var isHome: Bool = false
    
    @AppStorage("useBankNameInsteadOfIcon") private var useBankNameInsteadOfIcon = false
    
    var body: some View {
        let contentColor = bank?.textColor ?? .primary
        
        HStack {
            if showMenuBtn {
                Button(action: onMenuTap) {
                    Image(systemName: "line.horizontal.3")
                        .font(.title2)
                        .foregroundColor(contentColor)
                }
            } else {
                Spacer().frame(width: 30) // placeholder
            }
            
            Spacer()
            
            // Center Content
            Group {
                if let bank = bank {
                    if useBankNameInsteadOfIcon {
                        Text(bank.name)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(contentColor)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    } else {
                        Image(bank.iconImg)
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(contentColor)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 40, height: 40)
                    }
                } else if isHome {
                    Image("AppLogoL")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else if let title = title {
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(contentColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .frame(height: 40)
            
            Spacer()
            
            /*
            Button(action: {}) {
                Image(systemName: "gearshape")
                    .font(.title2)
                    .foregroundColor(.primary)
            }
            */
            Spacer().frame(width: 30) // placeholder to maintain centering
        }
        .padding(.horizontal)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background(themeColor)
    }
}

// MARK: - Operation Card
struct OperationCard: View {
    let operation: BankOperation
    let themeColor: Color
    let textColor: Color
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(operation.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(operation.description)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(themeColor)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: operation.iconName)
                        .font(.system(size: 20))
                        .foregroundColor(textColor)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .shadow(color: Color.primary.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Bank Selection Card
struct BankSelectionCard: View {
    let bank: Bank
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Image(bank.iconImg)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(bank.textColor)
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 40)
                
                Text(bank.shortName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(bank.textColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(bank.themeColor)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Menu Shortcut Card
struct MenuShortcutCard: View {
    let iconName: String
    let title: String
    let themeColor: Color
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Image(systemName: iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 30)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 110, height: 90)
            .background(themeColor)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Data Card (Copy to Clipboard)
struct DataCard: View {
    let title: String
    let subtitle: String?
    let value: String
    let iconName: String
    let backgroundColor: Color
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    
    @State private var showCopied = false
    
    var body: some View {
        Button(action: {
            UIPasteboard.general.string = value
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            withAnimation {
                showCopied = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation { showCopied = false }
            }
        }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(backgroundColor.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: iconName)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(backgroundColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    
                    Text(value)
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(backgroundColor)
                        .padding(.top, 2)
                }
                
                Spacer()
                
                if showCopied {
                    Text("Copiado!")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                } else {
                    HStack(spacing: 8) {
                        if let onEdit = onEdit {
                            Button(action: onEdit) {
                                Image(systemName: "pencil")
                                    .foregroundColor(.blue)
                            }
                        }
                        if let onDelete = onDelete {
                            Button(action: onDelete) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Wallet Card
struct WalletCard: View {
    let account: BankAccount
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    
    @State private var showCopied = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(account.label)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                    Text(account.group.isEmpty ? "Banco" : account.group)
                        .font(.system(size: 10, weight: .medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(4)
                        .foregroundColor(.white)
                }
                Spacer()
                Image(systemName: "creditcard.fill")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.bottom, 30)
            
            Spacer()
            
            // Card Number
            Text(maskCardNumber(account.cardNumber))
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .tracking(2)
            
            Spacer()
            
            // Footer
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TITULAR")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.white.opacity(0.5))
                    Text(account.name.uppercased())
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    if showCopied {
                        Text("COPIADO")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white)
                            .cornerRadius(6)
                    } else {
                        Button(action: {
                            UIPasteboard.general.string = account.cardNumber
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            withAnimation { showCopied = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation { showCopied = false }
                            }
                        }) {
                            Image(systemName: "doc.on.doc.fill")
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Menu {
                            if let onEdit = onEdit {
                                Button(action: onEdit) {
                                    Label("Editar", systemImage: "pencil")
                                }
                            }
                            if let onDelete = onDelete {
                                Button(role: .destructive, action: onDelete) {
                                    Label("Eliminar", systemImage: "trash")
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle.fill")
                                .font(.title3)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
            }
        }
        .padding(24)
        .frame(height: 200)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: account.colorHex),
                            Color(hex: account.colorHex).opacity(0.7)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
    
    private func maskCardNumber(_ number: String) -> String {
        let last4 = number.suffix(4)
        return "**** **** **** \(last4)"
    }
}
