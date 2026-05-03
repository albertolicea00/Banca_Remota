import SwiftUI

// MARK: - Navigation Hub View
struct MainView: View {
    @State private var config: BankConfig?
    @State private var selectedBank: Bank?
    @State private var isMenuOpen = false
    @State private var isShowingHelp = false
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Main Content Area
            VStack(spacing: 0) {
                if let config = config {
                    if isShowingHelp {
                        HelpView(onMenuTap: {
                            withAnimation { isMenuOpen.toggle() }
                        })
                    } else if let bank = selectedBank {
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
                        isShowingHelp = false
                        withAnimation { isMenuOpen = false }
                    },
                    onSelectBank: { bank in
                        selectedBank = bank
                        isShowingHelp = false
                        withAnimation { isMenuOpen = false }
                    },
                    onSelectHelp: {
                        isShowingHelp = true
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
            
            ScrollView {
                VStack {
                    HStack(spacing: 15) {
                        ForEach(banks) { bank in
                            BankSelectionCard(bank: bank) {
                                onSelectBank(bank)
                            }
                        }
                    }
                    .padding()
                    
                    Spacer()
                }
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
            TopNavBar(themeColor: bank.themeColor, onMenuTap: onMenuTap, bank: bank)
            
            // Banner with full bank name
            HStack {
                Text(bank.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(bank.themeColor)
            .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 3)
            .zIndex(1) // Keep shadow above scrollview
            
            ScrollView {
                VStack(spacing: 0) {
                    Spacer().frame(height: 20)
                    
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
    let onSelectHelp: () -> Void
    
    var body: some View {
        ZStack(alignment: .leading) {
            Color.white.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 30) {
                // Branding Image
                Button(action: onSelectHome) {
                    Image("branding_logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 20)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.top, 40)
                .padding(.bottom, 10)
                
                Divider().padding(.trailing, 40)
                                
                // Link Items
                VStack(alignment: .leading, spacing: 25) {
                    ForEach(banks) { bank in
                        MenuRow(iconColor: bank.themeColor, imageName: "\(bank.id)/icon", systemImageName: nil, title: bank.shortName.uppercased(), isSelected: selectedBank?.id == bank.id) {
                            onSelectBank(bank)
                        }
                    }
                    
                    // Divider().padding(.trailing, 40)
                    // MenuRow(iconColor: Color(hex: "B38B4D"), imageName: nil, title: "Tasa de Cambio", isSelected: false) {}
                    // MenuRow(iconColor: Color(hex: "B38B4D"), imageName: nil, title: "Contactos del Banco", isSelected: false) {}
                    
                    Divider().padding(.trailing, 40)
                    MenuRow(iconColor: Color(hex: "B38B4D"), imageName: nil, systemImageName: "info.circle", title: "Información", isSelected: false) {
                        onSelectHelp()
                    }

                }
                .padding(.leading, 30)
                
                Spacer()
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width < -50 {
                        onSelectHome()
                    }
                }
        )
    }
}

// MARK: - Help and About View
struct HelpView: View {
    let onMenuTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            TopNavBar(themeColor: .white, onMenuTap: onMenuTap)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    // App Logo/Branding
                    Image("branding_logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 250)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    
                    // Info Sections
                    Group {
                        HelpSection(title: "Sobre la Aplicación", content: "Banca Remota es una solución nativa diseñada para simplificar y agilizar las operaciones bancarias a través de códigos USSD en Cuba. Esta herramienta permite gestionar cuentas de Banco en Cuba de forma intuitiva.\n\nNota: Este proyecto surge para rescatar la funcionalidad de la aplicación original homónima tras su desaparición. Reconocemos el trabajo de Henry Cruz, cuya versión anterior fue esencial para los usuarios.")
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Contacto y Colaboración")
                                .font(.headline)
                                .foregroundColor(Color(hex: "B38B4D"))
                            
                            Link(destination: URL(string: "https://www.linkedin.com/in/albertolicea00")!) {
                                Label("Alberto Licea (Desarrollador)", systemImage: "person.circle")
                            }
                            .foregroundColor(.blue)
                            
                            Link(destination: URL(string: "https://github.com/albertolicea00/Banca_Remota")!) {
                                Label("Código Fuente en GitHub", systemImage: "terminal")
                            }
                            .foregroundColor(.blue)
                            .padding(.top, 2)
                            
                            Text("Puedes colaborar sugiriendo mejoras, reportando errores o aportando nuevas imágenes para los bancos.")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.top, 2)
                            
                            Divider().padding(.top, 5)
                        }

                        HelpSection(title: "Nuestro Compromiso", content: "Esta versión de la aplicación se mantendrá tal cual la ves: ligera, sencilla y rápida. Queremos que funcione en todos los dispositivos Apple, incluso en los más antiguos, para evitar que tengas que cambiar de teléfono solo para usar tu banco. Creemos en la tecnología duradera y en respetar la costumbre de nuestros usuarios.")

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Créditos Originales")
                                .font(.headline)
                                .foregroundColor(Color(hex: "B38B4D"))
                            
                            Link(destination: URL(string: "https://www.linkedin.com/in/henrycruzmederos")!) {
                                Label("Henry Cruz (Creador original)", systemImage: "link")
                            }
                            .font(.body)
                            .foregroundColor(.gray)
                            
                            Divider().padding(.top, 5)
                        }
                        
                        HelpSection(title: "Privacidad", content: "La aplicación no almacena ni transmite sus datos personales. Todas las operaciones se realizan localmente mediante llamadas al sistema telefónico (USSD).")
                    }
                    
                    Spacer(minLength: 50)
                    
                    Text("Versión 1.0.0")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
                .padding(25)
            }
            .background(Color(hex: "F8F8F8"))
        }
    }
}

struct HelpSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundColor(Color(hex: "B38B4D"))
            
            Text(content)
                .font(.body)
                .foregroundColor(.black.opacity(0.8))
                .lineSpacing(4)
            
            Divider().padding(.top, 5)
        }
    }
}

// MARK: - Reusable Menu Item Component
struct MenuRow: View {
    let iconColor: Color
    let imageName: String?
    let systemImageName: String?
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 15) {
                if let imageName = imageName {
                    Image(imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .cornerRadius(6)
                } else if let systemName = systemImageName {
                    Image(systemName: systemName)
                        .font(.system(size: 20))
                        .foregroundColor(iconColor)
                        .frame(width: 24, height: 24)
                } else {
                    Circle()
                        .fill(iconColor)
                        .frame(width: 24, height: 24)
                }
                
                Text(title)
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? .black : Color.gray.opacity(0.8))
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
