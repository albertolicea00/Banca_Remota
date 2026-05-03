import SwiftUI
import LocalAuthentication

enum ActiveScreen {
    case home
    case bank
    case info
    case tutorial
    case config
    case contactos
    case cuentasBanco
    case cuentasNauta
    case misClaves
    case tasaCambio
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
                        ConfigView(banks: config.banks, onMenuTap: { withAnimation { isMenuOpen.toggle() } })
                    case .bank:
                        if let bank = selectedBank {
                            OperationsListView(bank: bank, allBanks: config.banks, onMenuTap: { withAnimation { isMenuOpen.toggle() } })
                        }
                    case .home:
                        BankSelectionView(banks: config.banks, onSelectBank: { bank in
                            selectedBank = bank
                            activeScreen = .bank
                        }, onSelectScreen: { screen in
                            selectedBank = nil
                            activeScreen = screen
                        }, onMenuTap: { withAnimation { isMenuOpen.toggle() } })
                    case .contactos:
                        UnderConstructionView(title: "Contactos", onMenuTap: { withAnimation { isMenuOpen.toggle() } })
                    case .cuentasNauta:
                        UnderConstructionView(title: "Cuentas de Nauta", onMenuTap: { withAnimation { isMenuOpen.toggle() } })
                    case .cuentasBanco:
                        UnderConstructionView(title: "Cuentas de Banco", onMenuTap: { withAnimation { isMenuOpen.toggle() } })
                    case .misClaves:
                        UnderConstructionView(title: "Mis Claves", onMenuTap: { withAnimation { isMenuOpen.toggle() } })
                    case .tasaCambio:
                        UnderConstructionView(title: "Tasa de Cambio", onMenuTap: { withAnimation { isMenuOpen.toggle() } })
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
                    activeScreen: activeScreen,
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
                    },
                    onSelectScreen: { screen in
                        selectedBank = nil
                        activeScreen = screen
                        withAnimation { isMenuOpen = false }
                    }
                )
                .frame(width: 280)
                .transition(.move(edge: .leading))
            }
        }
    }
}

// MARK: - Favorite Drop Delegate
struct FavoriteDropDelegate: DropDelegate {
    let item: FavoriteOperation
    @Binding var items: [FavoriteOperation]
    @Binding var draggedItem: FavoriteOperation?

    func performDrop(info: DropInfo) -> Bool {
        draggedItem = nil
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let draggedItem = draggedItem,
              draggedItem != item,
              let from = items.firstIndex(of: draggedItem),
              let to = items.firstIndex(of: item) else { return }
        
        if from != to {
            withAnimation(.default) {
                items.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
            }
        }
    }
}

// MARK: - Bank Selection Screen
struct BankSelectionView: View {
    let banks: [Bank]
    let onSelectBank: (Bank) -> Void
    let onSelectScreen: (ActiveScreen) -> Void
    let onMenuTap: () -> Void
    
    @AppStorage("showBanksInFavorites") private var showBanksInFavorites = true
    @AppStorage("useBanksAsLogin") private var useBanksAsLogin = true
    @AppStorage("showShortcutsInFavorites") private var showShortcutsInFavorites = true
    @AppStorage("useCustomFavoriteColor") private var useCustomFavoriteColor = true
    @AppStorage("favoriteCustomColorHex") private var favoriteCustomColorHex = "B38B4D"
    @ObservedObject private var favoritesManager = FavoritesManager.shared
    @State private var isShowingAddFavorite = false
    @State private var draggedItem: FavoriteOperation?
    
    var body: some View {
        VStack(spacing: 0) {
            TopNavBar(themeColor: Color(UIColor.systemBackground), onMenuTap: onMenuTap, isHome: true)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    if showBanksInFavorites {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Bancos Favoritos")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            HStack(spacing: 15) {
                                ForEach(banks) { bank in
                                    BankSelectionCard(bank: bank) {
                                        if useBanksAsLogin,
                                           let authOp = bank.categories.flatMap({ $0.operations }).first(where: { $0.isLogin == true }) {
                                            CallService.shared.executeUSSD(code: authOp.ussdCode)
                                        } else {
                                            onSelectBank(bank)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.top, 20)
                    }
                    
                    if showShortcutsInFavorites {
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Atajos de Menú")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            ScrollViewReader { proxy in
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 20) {
                                        // MenuShortcutCard(iconName: "person.crop.circle", title: "Contactos", themeColor: .appPrimary) { onSelectScreen(.contactos) }.id(0)
                                        MenuShortcutCard(iconName: "wifi", title: "Nauta", themeColor: .appPrimary) { onSelectScreen(.cuentasNauta) }.id(2)
                                        MenuShortcutCard(iconName: "building.columns.fill", title: "Cuentas", themeColor: .appPrimary) { onSelectScreen(.cuentasBanco) }.id(1)
                                        MenuShortcutCard(iconName: "key.fill", title: "Claves", themeColor: .appPrimary) { onSelectScreen(.misClaves) }.id(3)
                                        MenuShortcutCard(iconName: "arrow.left.arrow.right", title: "Cambio", themeColor: .appPrimary) { onSelectScreen(.tasaCambio) }.id(4)
                                    }
                                    .padding(.horizontal)
                                    .padding(.bottom, 10)
                                }
                                .onAppear {
                                    DispatchQueue.main.async {
                                        proxy.scrollTo(2, anchor: .center)
                                    }
                                }
                            }
                        }
                        .padding(.top, showBanksInFavorites ? 0 : 20)
                    }
                    
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Operaciones Favoritas")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        if !favoritesManager.favoriteOperations.isEmpty {
                            ForEach(favoritesManager.favoriteOperations) { fav in
                                if let bank = banks.first(where: { $0.id == fav.bankId }) {
                                    let theme = useCustomFavoriteColor ? Color(hex: favoriteCustomColorHex) : bank.themeColor
                                    let textColor = useCustomFavoriteColor ? .white : bank.textColor
                                    OperationCard(operation: fav.operation, themeColor: theme, textColor: textColor) {
                                        CallService.shared.executeUSSD(code: fav.operation.ussdCode)
                                    }
                                    .padding(.horizontal)
                                    .onDrag {
                                        self.draggedItem = fav
                                        return NSItemProvider(object: fav.id as NSString)
                                    }
                                    .onDrop(of: [.plainText], delegate: FavoriteDropDelegate(item: fav, items: Binding(
                                        get: { favoritesManager.favoriteOperations },
                                        set: { favoritesManager.favoriteOperations = $0 }
                                    ), draggedItem: $draggedItem))
                                }
                            }
                        }
                        
                        Button(action: { isShowingAddFavorite = true }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Agregar operación favorita")
                            }
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.appPrimary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, showShortcutsInFavorites ? 0 : 20)
                    .padding(.bottom, 30)
                    
                    Spacer()
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .sheet(isPresented: $isShowingAddFavorite) {
                AddFavoriteOperationView(banks: banks)
            }
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
                                    OperationCard(operation: operation, themeColor: bank.themeColor, textColor: bank.textColor) {
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
    let activeScreen: ActiveScreen
    let onSelectHome: () -> Void
    let onSelectBank: (Bank) -> Void
    let onSelectHelp: () -> Void
    let onSelectTutorial: () -> Void
    let onSelectConfig: () -> Void
    let onSelectScreen: (ActiveScreen) -> Void
    
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
                .padding(.top, 30)
                                
                // Link Items
                VStack(alignment: .leading, spacing: 25) {
                    MenuRow(iconColor: .appPrimary, imageName: nil, systemImageName: "star.fill", title: "Favoritos", isSelected: activeScreen == .home) {
                        onSelectHome()
                    }
                    
                    Divider().padding(.trailing, 40)
                    
                    ForEach(banks) { bank in
                        MenuRow(iconColor: .appPrimary, imageName: bank.iconImg, systemImageName: nil, title: bank.shortName.uppercased(), isSelected: activeScreen == .bank && selectedBank?.id == bank.id) {
                            onSelectBank(bank)
                        }
                    }
                    
                    Divider().padding(.trailing, 40)
                    // MenuRow(iconColor: .appPrimary, imageName: nil, systemImageName: "person.crop.circle", title: "Contactos", isSelected: activeScreen == .contactos) { onSelectScreen(.contactos) }
                    MenuRow(iconColor: .appPrimary, imageName: nil, systemImageName: "wifi", title: "Cuentas de Nauta", isSelected: activeScreen == .cuentasNauta) { onSelectScreen(.cuentasNauta) }
                    MenuRow(iconColor: .appPrimary, imageName: nil, systemImageName: "building.columns.fill", title: "Cuentas de Banco", isSelected: activeScreen == .cuentasBanco) { onSelectScreen(.cuentasBanco) }

                    
                    Divider().padding(.trailing, 40)
                    MenuRow(iconColor: .appPrimary, imageName: nil, systemImageName: "key.fill", title: "Mis Claves", isSelected: activeScreen == .misClaves) { onSelectScreen(.misClaves) }

                    Divider().padding(.trailing, 40)
                    MenuRow(iconColor: .appPrimary, imageName: nil, systemImageName: "arrow.left.arrow.right", title: "Tasa de Cambio", isSelected: activeScreen == .tasaCambio) { onSelectScreen(.tasaCambio) }

                    Divider().padding(.trailing, 40)
                    MenuRow(iconColor: .appPrimary, imageName: nil, systemImageName: "info.circle", title: "Información", isSelected: activeScreen == .info) {
                        onSelectHelp()
                    }
                    MenuRow(iconColor: .appPrimary, imageName: nil, systemImageName: "questionmark.circle", title: "Ayuda", isSelected: activeScreen == .tutorial) {
                        onSelectTutorial()
                    }
                    MenuRow(iconColor: .appPrimary, imageName: nil, systemImageName: "gearshape", title: "Configuración", isSelected: activeScreen == .config) {
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
            TopNavBar(themeColor: Color(UIColor.systemBackground), onMenuTap: onMenuTap, title: "Información")
            
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    // Info Sections
                    Group {
                        HelpSection(title: "Sobre la Aplicación", content: "Banca Remota es una solución nativa diseñada para simplificar y agilizar las operaciones bancarias a través de códigos USSD en Cuba. Esta herramienta permite gestionar cuentas de Banco en Cuba de forma intuitiva.\n\nEste proyecto surge para rescatar la funcionalidad de la aplicación original homónima tras su desaparición. Reconocemos el trabajo de Henry Cruz, cuya versión anterior fue esencial para los usuarios.")
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Contacto y Colaboración")
                                .font(.headline)
                                .foregroundColor(.appPrimary)
                            
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
                                .foregroundColor(.appPrimary)
                            
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
                .foregroundColor(.appPrimary)
            
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
                        .foregroundColor(isSelected ? .primary : iconColor)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .cornerRadius(6)
                } else if let systemName = systemImageName {
                    Image(systemName: systemName)
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? .primary : iconColor)
                        .frame(width: 24, height: 24)
                } else {
                    Circle()
                        .fill(isSelected ? .primary : iconColor)
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
            TopNavBar(themeColor: Color(UIColor.systemBackground), onMenuTap: onMenuTap, title: "Ayuda")
            
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {
                    Text("Ayuda y Uso de la App")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.appPrimary)
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
    let banks: [Bank]
    let onMenuTap: () -> Void
    
    @AppStorage("darkModePreference") private var darkMode: Int = 0 // 0 = Default, 1 = Light, 2 = Dark
    @AppStorage("liquidGlassEnabled") private var liquidGlass = false
    @AppStorage("authEnabled") private var authEnabled: Bool = false
    @AppStorage("authExpiration") private var authExpiration: Double = 1.0 // 1 min, 5 min, etc.
    @AppStorage("lastAuthTime") private var lastAuthTime: Double = 0
    
    @AppStorage("showNetworkStatus") private var showNetworkStatus = false
    @AppStorage("useBankNameInsteadOfIcon") private var useBankNameInsteadOfIcon = false
    @AppStorage("showBanksInFavorites") private var showBanksInFavorites = true
    @AppStorage("useBanksAsLogin") private var useBanksAsLogin = true
    @AppStorage("showShortcutsInFavorites") private var showShortcutsInFavorites = true
    
    @AppStorage("useCustomFavoriteColor") private var useCustomFavoriteColor = true
    @AppStorage("favoriteCustomColorHex") private var favoriteCustomColorHex = "B38B4D"
    
    @State private var pendingAuthEnabled: Bool = false
    @State private var selectedFavoriteColor: Color = .appPrimary
    
    var body: some View {
        VStack(spacing: 0) {
            TopNavBar(themeColor: Color(UIColor.systemBackground), onMenuTap: onMenuTap, title: "Configuración")
            
            Form {
                Section(header: Text("Apariencia")) {
                    Picker("Tema Visual", selection: $darkMode) {
                        Text("Por defecto").tag(0)
                        Text("Modo Claro").tag(1)
                        Text("Modo Oscuro").tag(2)
                    }
                    
                    Toggle("Modo Liquid Glass", isOn: $liquidGlass)
                    
                    Toggle("Usar color personalizado en favoritos", isOn: $useCustomFavoriteColor)
                    if useCustomFavoriteColor {
                        ColorPicker("Color de favoritos", selection: $selectedFavoriteColor)
                            .onChange(of: selectedFavoriteColor) { newColor in
                                if let hex = newColor.toHex() {
                                    favoriteCustomColorHex = hex
                                }
                            }
                    }
                }
                
                Section(header: Text("General y Preferencias")) {
                    Toggle("Aviso de estado de conexión", isOn: $showNetworkStatus)
                    Toggle("Mostrar nombre de banco en vez de icono", isOn: $useBankNameInsteadOfIcon)
                    Toggle("Mostrar atajos de menú en favoritos", isOn: $showShortcutsInFavorites)
                    Toggle("Mostrar bancos en favoritos", isOn: $showBanksInFavorites)
                    if showBanksInFavorites {
                        Toggle("Usar bancos favoritos como inicio de sesión", isOn: $useBanksAsLogin)
                    }
                }
                
                Section(header: Text("Gestión de Datos")) {
                    Button(action: {
                        FavoritesManager.shared.loadDefaults(from: banks)
                    }) {
                        Label("Cargar Favoritos por Defecto", systemImage: "arrow.counterclockwise.circle")
                            .foregroundColor(.appPrimary)
                    }
                }
                
                Section(header: Text("Seguridad y Autenticación"), footer: Text("Protege el acceso a la aplicación usando la seguridad nativa de tu dispositivo (Face ID, Touch ID o Código).")) {
                    Toggle("Requerir Autenticación", isOn: $pendingAuthEnabled)
                    
                    if authEnabled {
                        Picker("Expirar Sesión", selection: $authExpiration) {
                            Text("Inmediato").tag(0.0)
                            Text("En 30 segundos").tag(0.5)
                            Text("En 1 minuto").tag(1.0)
                            Text("En 5 minutos").tag(5.0)
                            Text("En 15 minutos").tag(15.0)
                        }
                    }
                }
            }
            .onChange(of: pendingAuthEnabled) { newValue in
                guard newValue != authEnabled else { return }
                
                let context = LAContext()
                var error: NSError?
                
                if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
                    context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Confirma para cambiar la seguridad") { success, _ in
                        DispatchQueue.main.async {
                            if success {
                                authEnabled = newValue
                                lastAuthTime = Date().timeIntervalSince1970
                                AuthManager.shared.isAuthenticated = true
                            } else {
                                pendingAuthEnabled = authEnabled // Revert
                            }
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        authEnabled = newValue
                        lastAuthTime = Date().timeIntervalSince1970
                    }
                }
            }
            .onChange(of: authExpiration) { _ in
                lastAuthTime = Date().timeIntervalSince1970
            }
            .onAppear {
                pendingAuthEnabled = authEnabled
                selectedFavoriteColor = Color(hex: favoriteCustomColorHex)
            }
        }
    }
}

// MARK: - Under Construction View
struct UnderConstructionView: View {
    let title: String
    let onMenuTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            TopNavBar(themeColor: Color(UIColor.systemBackground), onMenuTap: onMenuTap, title: title)
            
            VStack(spacing: 20) {
                Spacer()
                Image(systemName: "hammer.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.appPrimary)
                Text("En Construcción")
                    .font(.title)
                    .fontWeight(.bold)
                Text("Esta sección estará disponible en futuras actualizaciones de la aplicación. ¡Gracias por la espera!")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 40)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(UIColor.systemGroupedBackground))
        }
    }
}

// MARK: - Add Favorite Operation View
struct AddFavoriteOperationView: View {
    @Environment(\.presentationMode) var presentationMode
    let banks: [Bank]
    @ObservedObject var favoritesManager = FavoritesManager.shared
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Buscar operación o banco...", text: $searchText)
                        .disableAutocorrection(true)
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(10)
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.vertical, 10)
                
                List {
                    ForEach(banks) { bank in
                        ForEach(bank.categories) { category in
                            let filteredOperations = category.operations.filter { operation in
                                searchText.isEmpty || 
                                operation.name.localizedCaseInsensitiveContains(searchText) ||
                                operation.description.localizedCaseInsensitiveContains(searchText) ||
                                bank.shortName.localizedCaseInsensitiveContains(searchText)
                            }
                            
                            if !filteredOperations.isEmpty {
                                Section(header: Text("\(bank.shortName.uppercased()) - \(category.name)")) {
                                    ForEach(filteredOperations) { operation in
                                        let isFavorite = favoritesManager.favoriteOperations.contains(where: { $0.id == "\(bank.id)_\(operation.id)" })
                                        
                                        Button(action: {
                                            if isFavorite {
                                                favoritesManager.favoriteOperations.removeAll(where: { $0.id == "\(bank.id)_\(operation.id)" })
                                            } else {
                                                favoritesManager.favoriteOperations.append(FavoriteOperation(bankId: bank.id, operation: operation))
                                            }
                                        }) {
                                            HStack(spacing: 15) {
                                                Image(systemName: operation.iconName)
                                                    .foregroundColor(bank.themeColor)
                                                    .frame(width: 25)
                                                
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(operation.name)
                                                        .foregroundColor(.primary)
                                                    Text(operation.description)
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                        .lineLimit(1)
                                                }
                                                
                                                Spacer()
                                                
                                                if isFavorite {
                                                    Image(systemName: "star.fill")
                                                        .foregroundColor(.appPrimary)
                                                } else {
                                                    Image(systemName: "plus.circle")
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Agregar Favorito")
            .navigationBarItems(trailing: Button("Cerrar") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}
