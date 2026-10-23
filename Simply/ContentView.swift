import SwiftUI

enum AuthMode: String, CaseIterable {
    case register = "Registrati"
    case login = "Accedi"
}

struct ContentView: View {
    @State private var selectedMode: AuthMode = .register
    
    // Dati form
    @State private var name: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    
    // Visibilità password
    @State private var showPassword: Bool = false
    @State private var showConfirmPassword: Bool = false
    
    // Colore base richiesto #1C1C1E
    private let baseBackground = Color(red: 28 / 255.0, green: 28 / 255.0, blue: 30 / 255.0)

    var body: some View {
        ZStack {
            // Sfondo #1C1C1E con profondità di luce per far risaltare il vetro ottico Apple
            baseBackground
                .ignoresSafeArea()
            
            // Sfere di luce ambientale Apple che filtrano attraverso il materiale Liquid Glass
            ambientLighting
                .ignoresSafeArea()
            
            VStack(spacing: 28) {
                // MARK: - Slider Superiore Liquid Glass
                glassSlider
                    .padding(.top, 16)
                
                Spacer()
                
                // MARK: - Card Principale Liquid Glass
                VStack(spacing: 22) {
                    // Intestazione
                    VStack(spacing: 6) {
                        Text(selectedMode == .register ? "Crea Account" : "Bentornato")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text(selectedMode == .register ? "Inserisci i dati per registrarti" : "Inserisci le tue credenziali per accedere")
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.65))
                    }
                    .padding(.bottom, 4)
                    
                    // Campi di input in vetro
                    VStack(spacing: 14) {
                        // Nome
                        glassTextField(
                            icon: "person.fill",
                            placeholder: "Nome",
                            text: $name
                        )
                        
                        // Password
                        glassPasswordField(
                            icon: "lock.fill",
                            placeholder: "Password",
                            text: $password,
                            isVisible: $showPassword
                        )
                        
                        // Conferma Password (solo in Registrati)
                        if selectedMode == .register {
                            glassPasswordField(
                                icon: "checkmark.shield.fill",
                                placeholder: "Conferma password",
                                text: $confirmPassword,
                                isVisible: $showConfirmPassword
                            )
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.95)),
                                removal: .opacity.combined(with: .scale(scale: 0.95))
                            ))
                        }
                    }
                    
                    // Pulsante Azione
                    Button(action: {
                        // Solo grafico di test
                    }) {
                        Text(selectedMode == .register ? "Registrati" : "Accedi")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 5)
                    }
                    .padding(.top, 6)
                }
                .padding(26)
                .background(
                    // Materiale Liquid Glass Ufficiale Apple
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    // Bordo speculare a riflessione di luce tipico del vetro Apple
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.45),
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
                .shadow(color: Color.black.opacity(0.35), radius: 25, x: 0, y: 15)
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
    }
    
    // MARK: - Luci di sfondo per consentire la rifrazione al Materiale Glass
    private var ambientLighting: some View {
        ZStack {
            Circle()
                .fill(Color(red: 0.25, green: 0.35, blue: 0.55).opacity(0.28))
                .frame(width: 340, height: 340)
                .blur(radius: 80)
                .offset(x: -100, y: -200)
            
            Circle()
                .fill(Color(red: 0.45, green: 0.25, blue: 0.55).opacity(0.22))
                .frame(width: 320, height: 320)
                .blur(radius: 85)
                .offset(x: 120, y: 160)
        }
    }
    
    // MARK: - Slider Superiore in Materiale Glass Apple
    private var glassSlider: some View {
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
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(.regularMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(
                                                LinearGradient(
                                                    colors: [Color.white.opacity(0.45), Color.white.opacity(0.1)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                                lineWidth: 1
                                            )
                                    )
                                    .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 3)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.3), Color.white.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .frame(maxWidth: 300)
    }
    
    // MARK: - Campo di Testo Glass
    private func glassTextField(icon: String, placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 20)
            
            TextField("", text: text, prompt: Text(placeholder).foregroundColor(.white.opacity(0.45)))
                .foregroundColor(.white)
                .font(.system(size: 16))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }
    
    // MARK: - Campo Password Glass
    private func glassPasswordField(icon: String, placeholder: String, text: Binding<String>, isVisible: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 20)
            
            if isVisible.wrappedValue {
                TextField("", text: text, prompt: Text(placeholder).foregroundColor(.white.opacity(0.45)))
                    .foregroundColor(.white)
                    .font(.system(size: 16))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
            } else {
                SecureField("", text: text, prompt: Text(placeholder).foregroundColor(.white.opacity(0.45)))
                    .foregroundColor(.white)
                    .font(.system(size: 16))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
            }
            
            Button(action: {
                isVisible.wrappedValue.toggle()
            }) {
                Image(systemName: isVisible.wrappedValue ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.white.opacity(0.6))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }
}

#Preview {
    ContentView()
}
