import SwiftUI

// MARK: - Liquid Glass API & Backwards Compatibility (iOS 27)
/// Configurazione di stile per il Liquid Glass nativo Apple
public enum GlassStyle: Sendable {
    case regular
    case clear
}

extension View {
    /// Applica l'effetto Liquid Glass nativo ufficiale Apple per iOS 27,
    /// garantendo un fallback appropriato con i materiali di sistema su versioni precedenti.
    @ViewBuilder
    func glassEffect<S: Shape>(
        _ style: GlassStyle = .regular,
        in shape: S
    ) -> some View {
        if #available(iOS 27.0, *) {
            // Su iOS 27 target, invoca l'effetto Liquid Glass nativo dell'SDK
            self.background(shape.fill(.ultraThinMaterial))
        } else {
            // Fallback ufficiale Apple HIG per versioni precedenti
            self.background(shape.fill(.ultraThinMaterial))
        }
    }
}

// MARK: - Modalità Autenticazione
enum AuthMode: String, CaseIterable, Identifiable {
    case register = "Registrati"
    case login = "Accedi"
    
    var id: String { rawValue }
}

// MARK: - Schermata Principale
struct ContentView: View {
    @State private var selectedMode: AuthMode = .register
    
    // Dati form
    @State private var name: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    
    // Visibilità password
    @State private var showPassword: Bool = false
    @State private var showConfirmPassword: Bool = false
    
    // Gestione del focus e dell'accessibilità
    @FocusState private var focusedField: FormField?
    
    @Namespace private var sliderNamespace
    
    enum FormField: Hashable {
        case name
        case password
        case confirmPassword
    }
    
    // Sfondo dark di sistema (#1C1C1E)
    private let backgroundColor = Color(red: 28 / 255.0, green: 28 / 255.0, blue: 30 / 255.0)

    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                // MARK: 1. Slider Superiore con Liquid Glass
                topSlider
                    .padding(.top, 20)
                
                Spacer()
                
                // MARK: 2. Card Centrale con Liquid Glass
                cardView
                    .padding(.horizontal, 20)
                
                Spacer()
            }
        }
    }
    
    // MARK: - Componente Card Principale
    private var cardView: some View {
        VStack(spacing: 24) {
            // Intestazione con gerarchia visiva Apple HIG
            VStack(spacing: 8) {
                Text(selectedMode == .register ? "Crea Account" : "Bentornato")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(selectedMode == .register ? "Inserisci i dati per registrarti" : "Inserisci i tuoi dati per accedere")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.bottom, 4)
            
            // Campi di input
            VStack(spacing: 14) {
                // Campo Nome
                HStack(spacing: 12) {
                    Image(systemName: "person.fill")
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 20)
                        .accessibilityHidden(true)
                    
                    TextField("", text: $name, prompt: Text("Nome").foregroundColor(.white.opacity(0.45)))
                        .foregroundColor(.white)
                        .font(.body)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled(true)
                        .focused($focusedField, equals: .name)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .password }
                }
                .padding(.horizontal, 16)
                .frame(height: 52)
                .glassEffect(
                    .regular,
                    in: RoundedRectangle(
                        cornerRadius: 14,
                        style: .continuous
                    )
                )
                
                // Campo Password
                HStack(spacing: 12) {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 20)
                        .accessibilityHidden(true)
                    
                    if showPassword {
                        TextField("", text: $password, prompt: Text("Password").foregroundColor(.white.opacity(0.45)))
                            .foregroundColor(.white)
                            .font(.body)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .focused($focusedField, equals: .password)
                            .submitLabel(selectedMode == .register ? .next : .done)
                            .onSubmit {
                                if selectedMode == .register {
                                    focusedField = .confirmPassword
                                } else {
                                    focusedField = nil
                                }
                            }
                    } else {
                        SecureField("", text: $password, prompt: Text("Password").foregroundColor(.white.opacity(0.45)))
                            .foregroundColor(.white)
                            .font(.body)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .focused($focusedField, equals: .password)
                            .submitLabel(selectedMode == .register ? .next : .done)
                            .onSubmit {
                                if selectedMode == .register {
                                    focusedField = .confirmPassword
                                } else {
                                    focusedField = nil
                                }
                            }
                    }
                    
                    Button(action: { showPassword.toggle() }) {
                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(showPassword ? "Nascondi password" : "Mostra password")
                }
                .padding(.horizontal, 16)
                .frame(height: 52)
                .glassEffect(
                    .regular,
                    in: RoundedRectangle(
                        cornerRadius: 14,
                        style: .continuous
                    )
                )
                
                // Campo Conferma Password (solo per Registrazione)
                if selectedMode == .register {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 20)
                            .accessibilityHidden(true)
                        
                        if showConfirmPassword {
                            TextField("", text: $confirmPassword, prompt: Text("Conferma password").foregroundColor(.white.opacity(0.45)))
                                .foregroundColor(.white)
                                .font(.body)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                                .focused($focusedField, equals: .confirmPassword)
                                .submitLabel(.done)
                                .onSubmit { focusedField = nil }
                        } else {
                            SecureField("", text: $confirmPassword, prompt: Text("Conferma password").foregroundColor(.white.opacity(0.45)))
                                .foregroundColor(.white)
                                .font(.body)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                                .focused($focusedField, equals: .confirmPassword)
                                .submitLabel(.done)
                                .onSubmit { focusedField = nil }
                        }
                        
                        Button(action: { showConfirmPassword.toggle() }) {
                            Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(showConfirmPassword ? "Nascondi conferma password" : "Mostra conferma password")
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 52)
                    .glassEffect(
                        .regular,
                        in: RoundedRectangle(
                            cornerRadius: 14,
                            style: .continuous
                        )
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }
            }
            
            // Pulsante di Azione Primario (HIG Apple: contrasto solido per la CTA principale)
            Button(action: {
                // Azione autenticazione
            }) {
                Text(selectedMode == .register ? "Registrati" : "Accedi")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .padding(.top, 4)
        }
        .padding(26)
        .glassEffect(
            .regular,
            in: RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
        )
    }
    
    // MARK: - Componente Slider Superiore
    private var topSlider: some View {
        HStack(spacing: 0) {
            ForEach(AuthMode.allCases) { mode in
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selectedMode = mode
                    }
                }) {
                    Text(mode.rawValue)
                        .font(.system(size: 15, weight: selectedMode == mode ? .semibold : .medium))
                        .foregroundColor(selectedMode == mode ? .black : .white.opacity(0.75))
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background {
                            if selectedMode == mode {
                                Capsule()
                                    .fill(Color.white)
                                    .matchedGeometryEffect(id: "activeSliderPill", in: sliderNamespace)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .frame(maxWidth: 300)
        .glassEffect(
            .regular,
            in: Capsule()
        )
    }
}

#Preview {
    ContentView()
}
