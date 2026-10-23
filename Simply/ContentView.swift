import SwiftUI

enum TabItem: String, CaseIterable, Identifiable {
    case register = "Registrati"
    case login = "Accedi"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .register: return "person.badge.plus"
        case .login:    return "arrow.right.circle.fill"
        }
    }
}

struct ContentView: View {
    @State private var selectedTab: TabItem = .register

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(TabItem.register.rawValue, systemImage: TabItem.register.icon, value: TabItem.register) {
                ZStack {
                    Color(red: 28/255, green: 28/255, blue: 30/255)
                        .ignoresSafeArea()
                }
            }

            Tab(TabItem.login.rawValue, systemImage: TabItem.login.icon, value: TabItem.login) {
                ZStack {
                    Color(red: 28/255, green: 28/255, blue: 30/255)
                        .ignoresSafeArea()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
