import SwiftUI

enum AuthMode: String, CaseIterable {
    case register = "Registrati"
    case login = "Accedi"
}

struct ContentView: View {
    @State private var selectedMode: AuthMode = .register
    
    // Campi per il modulo di test
    @State private var name: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    
    // Visibilità password
    @State private var showPassword: Bool = false
    @State private var showConfirmPassword: Bool = false
    
    // Colori & Stile Apple
    private let backgroundColor = Color(red: 28 / 255.0, green: 28 / 255.0, blue: 30 / 255.0) // #1C1C1E
    private let fieldBackground = Color.white.opacity(0.08)

    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Slider in alto: Registrati | Accedi
                topSlider
                    .padding(.top, 20)
                
                Spacer()
                
                // Card centrale con effetto Liquid Glass
                VStack(spacing: 20) {
                    // Intestazione
                    VStack(spacing: 6) {
                        Text(selectedMode == .register ? "Crea Account" : "Bentornato")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text(selectedMode == .register ? "Inserisci i dati per registrarti" : "Inserisci i tuoi dati per accedere")
                            .font(.system(size: 15))
                            .foregroundColor(.gray)
                    }
                    .padding(.bottom, 6)
                    
                    // Campi di input
                    VStack(spacing: 14) {
                        // Nome
                        customField(
                            icon: "person.fill",
                            placeholder: "Nome",
                            text: $name
                        )
                        
                        // Password
                        customPasswordField(
                            icon: "lock.fill",
                            placeholder: "Password",
                            text: $password,
                            isVisible: $showPassword
                        )
                        
                        // Conferma Password (solo se Registrati)
                        if selectedMode == .register {
                            customPasswordField(
                                icon: "checkmark.shield.fill",
                                placeholder: "Conferma password",
                                text: $confirmPassword,
                                isVisible: $showConfirmPassword
                            )
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    
                    // Pulsante Azione (solo grafica per test)
                    Button(action: {
                        // Nessuna azione reale, solo test
                    }) {
                        Text(selectedMode == .register ? "Registrati" : "Accedi")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.white)
                            .cornerRadius(14)
                    }
                    .padding(.top, 8)
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
    }
    
    // MARK: - Slider Superiore
    private var topSlider: some View {
        HStack(spacing: 0) {
            ForEach(AuthMode.allCases, id: \.self) { mode in
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                        selectedMode = mode
                    }
                }) {
                    Text(mode.rawValue)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(selectedMode == mode ? .black : .white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            ZStack {
                                if selectedMode == mode {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.white)
                                        .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 2)
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
        .frame(maxWidth: 320)
    }
    
    // MARK: - Campo Testo
    private func customField(icon: String, placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 20)
            
            TextField("", text: text, prompt: Text(placeholder).foregroundColor(.white.opacity(0.4)))
                .foregroundColor(.white)
                .font(.system(size: 16))
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
        }
        .padding(.horizontal, 16)
        .frame(height: 50)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(fieldBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Campo Password con Toggle Mostra/Nascondi
    private func customPasswordField(icon: String, placeholder: String, text: Binding<String>, isVisible: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.6))
                .frame(width: 20)
            
            if isVisible.wrappedValue {
                TextField("", text: text, prompt: Text(placeholder).foregroundColor(.white.opacity(0.4)))
                    .foregroundColor(.white)
                    .font(.system(size: 16))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
            } else {
                SecureField("", text: text, prompt: Text(placeholder).foregroundColor(.white.opacity(0.4)))
                    .foregroundColor(.white)
                    .font(.system(size: 16))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
            }
            
            Button(action: {
                isVisible.wrappedValue.toggle()
            }) {
                Image(systemName: isVisible.wrappedValue ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.white.opacity(0.5))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .frame(height: 50)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(fieldBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

#Preview {
    ContentView()
}
