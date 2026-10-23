import SwiftUI

// MARK: - Liquid Glass API (Apple Official Standard)
public struct Glass: Equatable {
    public static let regular = Glass()
    public static let clear = Glass()
    public static let identity = Glass()
    
    public func interactive(_ isInteractive: Bool = true) -> Glass { self }
    public func tint(_ color: Color) -> Glass { self }
}

public struct GlassEffectContainer<Content: View>: View {
    @ViewBuilder let content: () -> Content
    
    public init(spacing: CGFloat? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    public var body: some View {
        content()
    }
}

extension View {
    @ViewBuilder
    func glassEffect<S: Shape>(_ glass: Glass = .regular, in shape: S, isEnabled: Bool = true) -> some View {
        if isEnabled {
            self.background(
                shape
                    .fill(.ultraThinMaterial)
                    .overlay(
                        shape.stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.4),
                                    Color.white.opacity(0.12),
                                    Color.clear,
                                    Color.white.opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                    )
            )
        } else {
            self
        }
    }
    
    @ViewBuilder
    func glassEffect(_ glass: Glass = .regular, isEnabled: Bool = true) -> some View {
        self.glassEffect(glass, in: Capsule(), isEnabled: isEnabled)
    }
}

extension Shape where Self == RoundedRectangle {
    static func rect(cornerRadius: CGFloat) -> RoundedRectangle {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }
}

extension Shape where Self == Capsule {
    static var capsule: Capsule {
        Capsule()
    }
}

// MARK: - Modalità Autenticazione
enum AuthMode: String, CaseIterable {
    case register = "Registrati"
    case login = "Accedi"
}

// MARK: - Schermata Principale
struct ContentView: View {
    @State private var selectedMode: AuthMode = .register
    
    // Campi Form
    @State private var name: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    
    // Toggle visibilità
    @State private var showPassword: Bool = false
    @State private var showConfirmPassword: Bool = false
    
    // Sfondo dark base #1C1C1E
    private let backgroundColor = Color(red: 28 / 255.0, green: 28 / 255.0, blue: 30 / 255.0)

    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
            
            // Contenitore Liquid Glass Unificato
            GlassEffectContainer {
                VStack(spacing: 28) {
                    // Slider in alto con .glassEffect
                    topSlider
                        .padding(.top, 20)
                    
                    Spacer()
                    
                    // Card Form con .glassEffect(.regular)
                    VStack(spacing: 22) {
                        VStack(spacing: 6) {
                            Text(selectedMode == .register ? "Crea Account" : "Bentornato")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text(selectedMode == .register ? "Inserisci i dati per registrarti" : "Inserisci i tuoi dati per accedere")
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.65))
                        }
                        .padding(.bottom, 4)
                        
                        // Campi di input in vetro
                        VStack(spacing: 14) {
                            // Nome
                            HStack(spacing: 12) {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.white.opacity(0.7))
                                    .frame(width: 20)
                                
                                TextField("", text: $name, prompt: Text("Nome").foregroundColor(.white.opacity(0.45)))
                                    .foregroundColor(.white)
                                    .font(.system(size: 16))
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled(true)
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 52)
                            .glassEffect(.regular, in: .rect(cornerRadius: 16))
                            
                            // Password
                            HStack(spacing: 12) {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.white.opacity(0.7))
                                    .frame(width: 20)
                                
                                if showPassword {
                                    TextField("", text: $password, prompt: Text("Password").foregroundColor(.white.opacity(0.45)))
                                        .foregroundColor(.white)
                                        .font(.system(size: 16))
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled(true)
                                } else {
                                    SecureField("", text: $password, prompt: Text("Password").foregroundColor(.white.opacity(0.45)))
                                        .foregroundColor(.white)
                                        .font(.system(size: 16))
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled(true)
                                }
                                
                                Button(action: {
                                    showPassword.toggle()
                                }) {
                                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 52)
                            .glassEffect(.regular, in: .rect(cornerRadius: 16))
                            
                            // Conferma Password (solo se Registrati)
                            if selectedMode == .register {
                                HStack(spacing: 12) {
                                    Image(systemName: "checkmark.shield.fill")
                                        .foregroundColor(.white.opacity(0.7))
                                        .frame(width: 20)
                                    
                                    if showConfirmPassword {
                                        TextField("", text: $confirmPassword, prompt: Text("Conferma password").foregroundColor(.white.opacity(0.45)))
                                            .foregroundColor(.white)
                                            .font(.system(size: 16))
                                            .textInputAutocapitalization(.never)
                                            .autocorrectionDisabled(true)
                                    } else {
                                        SecureField("", text: $confirmPassword, prompt: Text("Conferma password").foregroundColor(.white.opacity(0.45)))
                                            .foregroundColor(.white)
                                            .font(.system(size: 16))
                                            .textInputAutocapitalization(.never)
                                            .autocorrectionDisabled(true)
                                    }
                                    
                                    Button(action: {
                                        showConfirmPassword.toggle()
                                    }) {
                                        Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 16)
                                .frame(height: 52)
                                .glassEffect(.regular, in: .rect(cornerRadius: 16))
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                            }
                        }
                        
                        // Bottone Azione
                        Button(action: {
                            // Test grafica
                        }) {
                            Text(selectedMode == .register ? "Registrati" : "Accedi")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .padding(.top, 6)
                    }
                    .padding(26)
                    .glassEffect(.regular, in: .rect(cornerRadius: 28))
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Slider Superiore Liquid Glass
    private var topSlider: some View {
        HStack(spacing: 0) {
            ForEach(AuthMode.allCases, id: \.self) { mode in
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selectedMode = mode
                    }
                }) {
                    Text(mode.rawValue)
                        .font(.system(size: 15, weight: selectedMode == mode ? .semibold : .medium))
                        .foregroundColor(selectedMode == mode ? .white : .white.opacity(0.65))
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background {
                            if selectedMode == mode {
                                Capsule()
                                    .glassEffect(.regular.interactive())
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .frame(maxWidth: 300)
        .glassEffect(.regular, in: .capsule)
    }
}

#Preview {
    ContentView()
}
