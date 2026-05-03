import SwiftUI

enum ActiveScreen {
    case home
    case bank
    case info
    case tutorial
    case config
}

// MARK: - Navigation Hub View
struct MainView: View {
    @State private var config: BankConfig?
    @State private var selectedBank: Bank?
    @State private var isMenuOpen = false
    @State private var activeScreen: ActiveScreen = .home
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Main Content Area
            VStack(spacing: 0) {
                if let config = config {
                    switch activeScreen {
                    case .info:
                        HelpView(onMenuTap: { withAnimation { isMenuOpen.toggle() } })
                    case .tutorial:
                        TutorialView(onMenuTap: { withAnimation { isMenuOpen.toggle() } })
                    case .config:
                        ConfigView(onMenuTap: { withAnimation { isMenuOpen.toggle() } })
                    case .bank:
                        if let bank = selectedBank {
                            OperationsListView(bank: bank, allBanks: config.banks, onMenuTap: { withAnimation { isMenuOpen.toggle() } })
                        }
                    case .home:
                        BankSelectionView(banks: config.banks, onSelectBank: { bank in
                            selectedBank = bank
                            activeScreen = .bank
                        }, onMenuTap: { withAnimation { isMenuOpen.toggle() } })
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
                        activeScreen = .home
                        withAnimation { isMenuOpen = false }
                    },
                    onSelectBank: { bank in
                        selectedBank = bank
                        activeScreen = .bank
                        withAnimation { isMenuOpen = false }
                    },
                    onSelectHelp: {
                        activeScreen = .info
                        withAnimation { isMenuOpen = false }
                    },
                    onSelectTutorial: {
                        activeScreen = .tutorial
                        withAnimation { isMenuOpen = false }
                    },
                    onSelectConfig: {
                        activeScreen = .config
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
            TopNavBar(themeColor: Color(UIColor.systemBackground), onMenuTap: onMenuTap)
            
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
            .background(Color(UIColor.systemGroupedBackground))
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
                    .foregroundColor(.primary)
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
            .background(Color(UIColor.systemGroupedBackground))
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
    let onSelectTutorial: () -> Void
    let onSelectConfig: () -> Void
    
    var body: some View {
        ZStack(alignment: .leading) {
            Color(UIColor.systemBackground).ignoresSafeArea()
            
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
                        MenuRow(iconColor: Color(hex: "B38B4D"), imageName: "\(bank.id)/icon", systemImageName: nil, title: bank.shortName.uppercased(), isSelected: selectedBank?.id == bank.id) {
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
                    MenuRow(iconColor: Color(hex: "B38B4D"), imageName: nil, systemImageName: "questionmark.circle", title: "Ayuda", isSelected: false) {
                        onSelectTutorial()
                    }
                    MenuRow(iconColor: Color(hex: "B38B4D"), imageName: nil, systemImageName: "gearshape", title: "Configuración", isSelected: false) {
                        onSelectConfig()
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
            TopNavBar(themeColor: Color(UIColor.systemBackground), onMenuTap: onMenuTap)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    // Info Sections
                    Group {
                        HelpSection(title: "Sobre la Aplicación", content: "Banca Remota es una solución nativa diseñada para simplificar y agilizar las operaciones bancarias a través de códigos USSD en Cuba. Esta herramienta permite gestionar cuentas de Banco en Cuba de forma intuitiva.\n\nEste proyecto surge para rescatar la funcionalidad de la aplicación original homónima tras su desaparición. Reconocemos el trabajo de Henry Cruz, cuya versión anterior fue esencial para los usuarios.")
                        
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
                            Text("Créditos")
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
                    
                    Spacer(minLength: 20)
                    
                    Text("Versión 2.0.1")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
                .padding(25)
            }
            .background(Color(UIColor.systemGroupedBackground))
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
                .foregroundColor(.primary.opacity(0.8))
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
                        .renderingMode(.template)
                        .foregroundColor(isSelected ? .white : iconColor)
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
                    .foregroundColor(isSelected ? .primary : Color.gray.opacity(0.8))
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Tutorial View (Ayuda)
struct TutorialView: View {
    let onMenuTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            TopNavBar(themeColor: Color(UIColor.systemBackground), onMenuTap: onMenuTap)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    Text("Ayuda y Uso de la App")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "B38B4D"))
                        .padding(.bottom, 10)
                    
                    HelpSection(title: "Cómo realizar operaciones", content: "Para realizar una operación, selecciona el banco deseado en el inicio. Luego verás un listado de categorías. Toca cualquier operación y la app generará y ejecutará automáticamente el código USSD correspondiente en tu teléfono.")
                    
                    HelpSection(title: "Configuración Inicial", content: "Es recomendable registrarse o autenticarse primero dentro de las opciones de 'Sesión' de cada banco para poder consultar saldo o realizar transferencias.")
                    
                    HelpSection(title: "Límites de Tarjeta", content: "Para consultas y cambios de límites diarios, puedes dirigirte a la sección de Consultas o Configuración de tu banco específico.")
                    
                    Spacer()
                }
                .padding(25)
            }
            .background(Color(UIColor.systemGroupedBackground))
        }
    }
}

// MARK: - Config View
struct ConfigView: View {
    let onMenuTap: () -> Void
    
    @AppStorage("darkModePreference") private var darkMode: Int = 0 // 0 = Default, 1 = Light, 2 = Dark
    @AppStorage("liquidGlassEnabled") private var liquidGlass = false
    @AppStorage("authMethod") private var authMethod: Int = 0 // 0 = Ninguno, 1 = PIN, 2 = Face ID / Touch ID
    @AppStorage("authExpiration") private var authExpiration: Int = 1 // 1 min, 5 min, etc.
    
    var body: some View {
        VStack(spacing: 0) {
            TopNavBar(themeColor: Color(UIColor.systemBackground), onMenuTap: onMenuTap)
            
            Form {
                Section(header: Text("Apariencia")) {
                    Picker("Tema Visual", selection: $darkMode) {
                        Text("Por defecto del sistema").tag(0)
                        Text("Modo Claro").tag(1)
                        Text("Modo Oscuro").tag(2)
                    }
                    
                    Toggle("Modo Liquid Glass", isOn: $liquidGlass)
                }
                
                Section(header: Text("Seguridad y Autenticación"), footer: Text("Protege el acceso a la aplicación requiriendo autenticación.")) {
                    Picker("Autenticación", selection: $authMethod) {
                        Text("Ninguno").tag(0)
                        Text("PIN").tag(1)
                        Text("Face / Touch ID").tag(2)
                    }
                    
                    if authMethod != 0 {
                        Picker("Expirar Sesión", selection: $authExpiration) {
                            Text("Inmediato").tag(0)
                            Text("En 1 minuto").tag(1)
                            Text("En 5 minutos").tag(5)
                            Text("En 15 minutos").tag(15)
                        }
                    }
                }
            }
        }
    }
}
