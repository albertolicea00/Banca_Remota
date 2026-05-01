import SwiftUI

// MARK: - Top Nav Bar
struct TopNavBar: View {
    var themeColor: Color
    var onMenuTap: () -> Void
    var showMenuBtn: Bool = true
    
    var body: some View {
        HStack {
            if showMenuBtn {
                Button(action: onMenuTap) {
                    Image(systemName: "line.horizontal.3")
                        .font(.title2)
                        .foregroundColor(.black)
                }
            } else {
                Spacer().frame(width: 30) // placeholder
            }
            
            Spacer()
            
            // Logo Circle
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 50, height: 50)
                
                VStack(spacing: 0) {
                    Text("BR")
                        .font(.system(size: 20, weight: .bold, design: .serif))
                        .foregroundColor(Color(hex: "B38B4D")) // Goldish color
                    
                    HStack(spacing: 0) {
                        Rectangle().fill(Color.black).frame(width: 8, height: 3)
                        Rectangle().fill(Color.red).frame(width: 8, height: 3)
                        Rectangle().fill(Color.blue).frame(width: 8, height: 3)
                    }
                    .padding(.top, 2)
                }
            }
            .clipShape(Circle())
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "gearshape")
                    .font(.title2)
                    .foregroundColor(.black)
            }
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
                        .foregroundColor(.black)
                    
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
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
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
            VStack(spacing: 0) {
                // Top colored banner
                HStack {
                    Text(bank.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding()
                .background(bank.themeColor)
                
                // Bottom white area
                ZStack {
                    Color.white
                    
                    // Logo representation
                    Image(bank.logoName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .padding(.vertical, 10)
                }
            }
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
