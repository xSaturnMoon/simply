import SwiftUI

enum AuthMode: String, CaseIterable {
    case register = "Registrati"
    case login = "Accedi"
}

struct ContentView: View {
    @State private var selectedMode: AuthMode = .register
    
    // Campi Form
    @State private var name: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    
    // Toggle visibilità password
    @State private var showPassword: Bool = false
    @State private var showConfirmPassword: Bool = false
    
    // Colore base #1C1C1E
    private let backgroundColor = Color(red: 28 / 255.0, green: 28 / 255.0, blue: 30 / 255.0)

    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 28) {
                // Slider superiore: Registrati | Accedi
                topSlider
                    .padding(.top, 20)
                
                Spacer()
                
                // Card centrale con materiale ufficiale Apple (.ultraThinMaterial)
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
                    
                    // Campi di input
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
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        
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
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        
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
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        }
                    }
                    
                    // Bottone Registrati / Accedi
                    Button(action: {
                        // Test interfaccia
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
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
    }
    
    // MARK: - Slider Superiore con materiale Apple (.ultraThinMaterial & .regularMaterial)
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
                                    .fill(.regularMaterial)
                                    .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 2)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .frame(maxWidth: 300)
        .background(.ultraThinMaterial, in: Capsule())
    }
}

#Preview {
    ContentView()
}
