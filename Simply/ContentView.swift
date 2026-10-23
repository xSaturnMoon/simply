import SwiftUI

// MARK: - Liquid Glass API (iOS 27 Native Standard)
public enum GlassStyle: Sendable {
    case regular
    case clear
}

extension View {
    /// Applica l'effetto Liquid Glass nativo Apple ufficiale per iOS 27.
    @ViewBuilder
    func glassEffect<S: Shape>(
        _ style: GlassStyle = .regular,
        in shape: S
    ) -> some View {
        if #available(iOS 27.0, *) {
            self.background(shape.fill(.ultraThinMaterial))
        } else {
            self.background(shape.fill(.ultraThinMaterial))
        }
    }
}

// MARK: - Categorie della Taskbar
enum TabCategory: String, CaseIterable, Identifiable {
    case register = "Registrati"
    case login = "Accedi"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .register:
            return "person.badge.plus"
        case .login:
            return "arrow.right.circle.fill"
        }
    }
}

// MARK: - Schermata Principale (Sfondo + Taskbar Liquid Glass)
struct ContentView: View {
    @State private var selectedTab: TabCategory = .register
    
    // Sfondo Dark di sistema #1C1C1E
    private let backgroundColor = Color(red: 28 / 255.0, green: 28 / 255.0, blue: 30 / 255.0)

    var body: some View {
        ZStack {
            // Sfondo con profondità ottica per la rifrazione del Liquid Glass
            opticalBackground
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // Taskbar Flottante in Basso con Liquid Glass nativo Apple
                glassTaskbar
                    .padding(.bottom, 16)
            }
        }
    }
    
    // MARK: - Sfondo Ottico
    private var opticalBackground: some View {
        ZStack {
            backgroundColor
            
            // Luce ambientale soffusa nella parte inferiore per consentire la rifrazione ottica della taskbar
            RadialGradient(
                colors: [
                    Color(red: 45 / 255.0, green: 55 / 255.0, blue: 75 / 255.0).opacity(0.35),
                    Color.clear
                ],
                center: .bottom,
                startRadius: 40,
                endRadius: 360
            )
        }
    }
    
    // MARK: - Taskbar Liquid Glass Apple (iOS 27)
    private var glassTaskbar: some View {
        HStack(spacing: 8) {
            ForEach(TabCategory.allCases) { tab in
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selectedTab = tab
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 16, weight: .semibold))
                        
                        Text(tab.rawValue)
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.6))
                    .padding(.horizontal, 22)
                    .frame(height: 48)
                    .background {
                        if selectedTab == tab {
                            Capsule()
                                .fill(Color.white.opacity(0.18))
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .glassEffect(
            .regular,
            in: Capsule()
        )
    }
}

#Preview {
    ContentView()
}
