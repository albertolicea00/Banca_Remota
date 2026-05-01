import SwiftUI

// MARK: - Navigation Hub View
struct MainView: View {
    @State private var config: BankConfig?
    @State private var selectedBank: Bank?
    @State private var isMenuOpen = false
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Main Content Area
            VStack(spacing: 0) {
                if let config = config {
                    if let bank = selectedBank {
                        OperationsListView(bank: bank, allBanks: config.banks, onMenuTap: {
                            withAnimation {
                                isMenuOpen.toggle()
                            }
                        })
                    } else {
                        BankSelectionView(banks: config.banks, onSelectBank: { bank in
                            selectedBank = bank
                        }, onMenuTap: {
                            withAnimation {
                                isMenuOpen.toggle()
                            }
                        })
                    }
                } else {
                    ProgressView("Loading Configuration...")
                        .onAppear {
                            // Initial configuration load
                            self.config = DataService.shared.loadConfiguration()
                        }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Side Drawer Overlay
            if isMenuOpen {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            isMenuOpen = false
                        }
                    }
                
                SideMenuView(
                    banks: config?.banks ?? [],
                    selectedBank: selectedBank,
                    onSelectHome: {
                        selectedBank = nil
                        withAnimation { isMenuOpen = false }
                    },
                    onSelectBank: { bank in
                        selectedBank = bank
                        withAnimation { isMenuOpen = false }
                    }
                )
                .frame(width: 280)
                .transition(.move(edge: .leading))
            }
        }
    }
}

// MARK: - Bank Selection Screen
struct BankSelectionView: View {
    let banks: [Bank]
    let onSelectBank: (Bank) -> Void
    let onMenuTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            TopNavBar(themeColor: .white, onMenuTap: onMenuTap)
            
            Text("Remote Banking")
                .font(.system(size: 20, weight: .regular))
                .foregroundColor(Color(hex: "B38B4D"))
                .padding(.vertical, 10)
            
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(banks) { bank in
                        BankSelectionCard(bank: bank) {
                            onSelectBank(bank)
                        }
                    }
                }
                .padding()
            }
            .background(Color(hex: "F8F8F8"))
        }
    }
}

// MARK: - Bank Specific Operations List
struct OperationsListView: View {
    let bank: Bank
    let allBanks: [Bank]
    let onMenuTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            TopNavBar(themeColor: bank.themeColor, onMenuTap: onMenuTap)
            
            ScrollView {
                VStack(spacing: 0) {
                    // Header Area with Bank Logo/Text
                    ZStack {
                        Color.white
                        VStack {
                            ZStack {
                                Circle()
                                    .fill(bank.themeColor)
                                    .frame(width: 60, height: 60)
                                Text(bank.shortName.uppercased())
                                    .font(.system(size: 30, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .padding(.top, 10)
                            .padding(.bottom, 20)
                        }
                    }
                    .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 3)
                    
                    // Categorized Operations
                    VStack(spacing: 20) {
                        ForEach(bank.categories) { category in
                            VStack(alignment: .leading, spacing: 12) {
                                Text(category.name.uppercased())
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 4)
                                
                                ForEach(category.operations) { operation in
                                    OperationCard(operation: operation, themeColor: bank.themeColor) {
                                        // Execute USSD trigger
                                        CallService.shared.executeUSSD(code: operation.ussdCode)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .background(Color(hex: "F8F8F8"))
        }
    }
}

// MARK: - Main Side Drawer Menu
struct SideMenuView: View {
    let banks: [Bank]
    let selectedBank: Bank?
    let onSelectHome: () -> Void
    let onSelectBank: (Bank) -> Void
    
    var body: some View {
        ZStack(alignment: .leading) {
            Color.white.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 30) {
                // Branding Logo
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 60, height: 60)
                        .shadow(radius: 2)
                    
                    VStack(spacing: 0) {
                        Text("BR")
                            .font(.system(size: 24, weight: .bold, design: .serif))
                            .foregroundColor(Color(hex: "B38B4D"))
                        
                        HStack(spacing: 0) {
                            Rectangle().fill(Color.black).frame(width: 10, height: 3)
                            Rectangle().fill(Color.red).frame(width: 10, height: 3)
                            Rectangle().fill(Color.blue).frame(width: 10, height: 3)
                        }
                        .padding(.top, 2)
                    }
                }
                .padding(.top, 50)
                .padding(.leading, 30)
                
                // Link Items
                VStack(alignment: .leading, spacing: 25) {
                    MenuRow(iconColor: Color(hex: "B38B4D"), title: "Inicio", isSelected: selectedBank == nil) {
                        onSelectHome()
                    }
                    
                    ForEach(banks) { bank in
                        MenuRow(iconColor: bank.themeColor, title: bank.shortName.lowercased(), isSelected: selectedBank?.id == bank.id) {
                            onSelectBank(bank)
                        }
                    }
                    
                    Divider().padding(.trailing, 40)
                    
                    MenuRow(iconColor: Color(hex: "B38B4D"), title: "Tasa de cambio", isSelected: false) {}
                    MenuRow(iconColor: Color(hex: "B38B4D"), title: "Contactos bancarios", isSelected: false) {}
                }
                .padding(.leading, 30)
                
                Spacer()
            }
        }
    }
}

// MARK: - Reusable Menu Item Component
struct MenuRow: View {
    let iconColor: Color
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                Circle()
                    .fill(iconColor)
                    .frame(width: 30, height: 30)
                
                Text(title)
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? .black : Color.gray.opacity(0.8))
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
