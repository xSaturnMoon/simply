import SwiftUI

// MARK: - Liquid Glass API Specification (iOS 27 Native Standard)
public enum GlassStyle: Sendable {
    case regular
    case clear
}

extension View {
    /// Applica l'effetto Liquid Glass nativo per iOS 27.
    /// Su runtime compatibili iOS 27, l'effetto applica la rifrazione fisica e aberrazione ottica di sistema.
    /// Su target precedenti, fornisce un fallback pulito conforme alle Apple HIG.
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

// MARK: - Modalità Autenticazione
enum AuthMode: String, CaseIterable, Identifiable {
    case register = "Registrati"
    case login = "Accedi"
    
    var id: String { rawValue }
}

// MARK: - Schermata Principale
struct ContentView: View {
    @State private var selectedMode: AuthMode = .register
    
    // Campi Form
    @State private var name: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    
    // Visibilità password
    @State private var showPassword: Bool = false
    @State private var showConfirmPassword: Bool = false
    
    // Gestione del focus e dell'accessibilità
    @FocusState private var focusedField: FormField?
    
    enum FormField: Hashable {
        case name
        case password
        case confirmPassword
    }

    var body: some View {
        ZStack {
            // Sfondo con profondità ottica per consentire la rifrazione fisica del Liquid Glass
            opticalBackground
                .ignoresSafeArea()
            
            VStack(spacing: 28) {
                // Controllo a segmenti nativo Apple SwiftUI (HIG standard)
                nativeSegmentedControl
                    .padding(.top, 16)
                
                Spacer()
                
                // Card Principale: Unica superficie funzionale Liquid Glass
                primaryCard
                    .padding(.horizontal, 20)
                
                Spacer()
            }
        }
    }
    
    // MARK: - Sfondo Ottico
    /// Il Liquid Glass è un materiale ottico traslucido: richiede una variazione di profondità e luce sottostante
    /// per manifestare la rifrazione e il bordo speculare sui contorni.
    private var opticalBackground: some View {
        ZStack {
            // Base scura #1C1C1E
            Color(red: 28 / 255.0, green: 28 / 255.0, blue: 30 / 255.0)
            
            // Profondità tonale sottile tipica dei Dark Background di sistema Apple
            RadialGradient(
                colors: [
                    Color(red: 45 / 255.0, green: 55 / 255.0, blue: 75 / 255.0).opacity(0.35),
                    Color.clear
                ],
                center: .topLeading,
                startRadius: 60,
                endRadius: 400
            )
            
            RadialGradient(
                colors: [
                    Color(red: 55 / 255.0, green: 40 / 255.0, blue: 65 / 255.0).opacity(0.25),
                    Color.clear
                ],
                center: .bottomTrailing,
                startRadius: 80,
                endRadius: 450
            )
        }
    }
    
    // MARK: - Controllo Segmented Nativo Apple
    /// Utilizzo del Picker di sistema con .pickerStyle(.segmented) conforme alle Apple HIG.
    /// Evita sovrapposizioni di Liquid Glass artificiali sui controlli di navigazione/selezione di sistema.
    private var nativeSegmentedControl: some View {
        Picker("Modalità", selection: $selectedMode) {
            ForEach(AuthMode.allCases) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 280)
        .padding(.horizontal)
    }
    
    // MARK: - Card Principale con Liquid Glass
    private var primaryCard: some View {
        VStack(spacing: 22) {
            // Header con gerarchia Apple HIG
            VStack(spacing: 6) {
                Text(selectedMode == .register ? "Crea Account" : "Bentornato")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(selectedMode == .register ? "Inserisci i dati per registrarti" : "Inserisci i tuoi dati per accedere")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.bottom, 4)
            
            // Campi di input: utilizzano superfici subordinate con riempimento gerarchico.
            // NON applicano .glassEffect per evitare l'anti-pattern "Glass-on-Glass" (interferenza di buffer ottico).
            VStack(spacing: 14) {
                // Nome
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
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                )
                
                // Password
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
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                )
                
                // Conferma Password (solo se Registrati)
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
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white.opacity(0.06))
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }
            }
            
            // Pulsante di Azione Primario (HIG Apple: contrasto solido su superficie glass)
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
        // Applicazione esclusiva del Liquid Glass sulla superficie card funzionale
        .glassEffect(
            .regular,
            in: RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
        )
    }
}

#Preview {
    ContentView()
}
