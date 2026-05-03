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
                    Image("branding_logo")
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
