import SwiftUI

// MARK: - Top Nav Bar
struct TopNavBar: View {
    var themeColor: Color
    var onMenuTap: () -> Void
    var showMenuBtn: Bool = true
    var bank: Bank? = nil
    
    var body: some View {
        HStack {
            if showMenuBtn {
                Button(action: onMenuTap) {
                    Image(systemName: "line.horizontal.3")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
            } else {
                Spacer().frame(width: 30) // placeholder
            }
            
            Spacer()
            
            // Logo Circle
            if let bank = bank {
                Image("\(bank.id)/icon")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(.primary)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
            }
            
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
                        .foregroundColor(.primary)
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
                Image("\(bank.id)/icon")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(.primary)
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 40)
                
                Text(bank.shortName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
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
