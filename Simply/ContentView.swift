import SwiftUI

enum TabItem: String, CaseIterable, Identifiable {
    case register = "Registrati"
    case login = "Accedi"
    
    var id: String { rawValue }
    
    var title: String { rawValue }
    
    var icon: String {
        switch self {
        case .register:
            return "person.badge.plus"
        case .login:
            return "arrow.right.circle.fill"
        }
    }
}

struct ContentView: View {
    @State private var selectedTab: TabItem = .register
    
    // Sfondo Dark di sistema #1C1C1E
    private let backgroundColor = Color(red: 28 / 255.0, green: 28 / 255.0, blue: 30 / 255.0)

    init() {
        // Configura l'aspetto della TabBar di sistema Apple garantendo il vero effetto glass traslucido
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // Categoria Registrati
            ZStack {
                backgroundColor
                    .ignoresSafeArea()
            }
            .tabItem {
                Label(TabItem.register.title, systemImage: TabItem.register.icon)
            }
            .tag(TabItem.register)
            
            // Categoria Accedi
            ZStack {
                backgroundColor
                    .ignoresSafeArea()
            }
            .tabItem {
                Label(TabItem.login.title, systemImage: TabItem.login.icon)
            }
            .tag(TabItem.login)
        }
        .tint(.blue)
    }
}

#Preview {
    ContentView()
}
