import SwiftUI

// MARK: - Root

struct ContentView: View {
    @State private var auth = AuthManager.shared

    var body: some View {
        Group {
            if auth.currentUser != nil {
                MainAppView()
            } else {
                NavigationStack {
                    LandingView()
                        .toolbarVisibility(.hidden, for: .navigationBar)
                }
            }
        }
        .animation(.easeInOut(duration: 0.35), value: auth.currentUser == nil)
    }
}

// MARK: - Landing

struct LandingView: View {
    private let bg = Color(red: 28/255, green: 28/255, blue: 30/255)

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo + Nome
                VStack(spacing: 20) {
                    Image("AppLogo")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 130, height: 130)
                        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))

                    Text("Simply")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.white)
                }

                Spacer()
                Spacer()

                // Pulsanti
                VStack(spacing: 12) {
                    NavigationLink(destination: RegisterView()) {
                        AuthPill(label: "Registrati con username", style: .primary)
                    }
                    .contentShape(Capsule())

                    NavigationLink(destination: LoginView()) {
                        AuthPill(label: "Accedi", style: .outlined)
                    }
                    .contentShape(Capsule())

                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 1)
                        .padding(.vertical, 4)

                    // Continua con Apple (custom pill coerente col design)
                    Button {} label: {
                        HStack(spacing: 10) {
                            Image(systemName: "apple.logo")
                                .font(.system(size: 17, weight: .medium))
                                .offset(y: -1)
                            Text("Continua con Apple")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1))
                    }
                    .contentShape(Capsule())
                }
                .padding(.horizontal, 28)

                Spacer()
            }
        }
    }
}

// MARK: - Register

struct RegisterView: View {
    @State private var auth = AuthManager.shared
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirm = false
    @Environment(\.dismiss) private var dismiss

    private let bg = Color(red: 28/255, green: 28/255, blue: 30/255)

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header con back
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 38, height: 38)
                            .glassEffect(.regular, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .contentShape(Circle())
                    Spacer()
                }
                .padding(.bottom, 32)

                // Logo piccolo + titolo
                VStack(spacing: 14) {
                    Image("AppLogo")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 52, height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    Text("Crea Account")
                        .font(.title.bold())
                        .foregroundStyle(.white)

                    Text("Benvenuto in Simply")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.45))
                }
                .padding(.bottom, 40)

                // Campi
                VStack(spacing: 12) {
                    AuthField(icon: "person", placeholder: "Nome utente", text: $username)
                    AuthSecureField(placeholder: "Password", text: $password, show: $showPassword)
                    AuthSecureField(placeholder: "Conferma Password", text: $confirmPassword, show: $showConfirm)
                }
                .padding(.bottom, 16)

                // Messaggio errore
                if let msg = auth.errorMessage {
                    Text(msg)
                        .font(.footnote)
                        .foregroundStyle(.red.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 4)
                        .padding(.bottom, 12)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // CTA
                Button {
                    Task {
                        await auth.register(
                            username: username,
                            password: password,
                            confirmPassword: confirmPassword
                        )
                    }
                } label: {
                    if auth.isLoading {
                        AuthPill(label: "", style: .primary, isLoading: true)
                    } else {
                        AuthPill(label: "Crea Account", style: .primary)
                    }
                }
                .contentShape(Capsule())
                .disabled(auth.isLoading)

                Spacer()
            }
            .padding(.horizontal, 28)
            .padding(.top, 20)
        }
        .navigationBarBackButtonHidden(true)
        .toolbarVisibility(.hidden, for: .navigationBar)
        .animation(.easeInOut(duration: 0.2), value: auth.errorMessage)
    }
}

// MARK: - Login

struct LoginView: View {
    @State private var auth = AuthManager.shared
    @State private var username = ""
    @State private var password = ""
    @State private var showPassword = false
    @Environment(\.dismiss) private var dismiss

    private let bg = Color(red: 28/255, green: 28/255, blue: 30/255)

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header con back
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 38, height: 38)
                            .glassEffect(.regular, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .contentShape(Circle())
                    Spacer()
                }
                .padding(.bottom, 32)

                // Logo piccolo + titolo
                VStack(spacing: 14) {
                    Image("AppLogo")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 52, height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    Text("Bentornato")
                        .font(.title.bold())
                        .foregroundStyle(.white)

                    Text("Accedi al tuo account Simply")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.45))
                }
                .padding(.bottom, 40)

                // Campi
                VStack(spacing: 12) {
                    AuthField(icon: "person", placeholder: "Nome utente", text: $username)
                    AuthSecureField(placeholder: "Password", text: $password, show: $showPassword)
                }
                .padding(.bottom, 16)

                // Messaggio errore
                if let msg = auth.errorMessage {
                    Text(msg)
                        .font(.footnote)
                        .foregroundStyle(.red.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 4)
                        .padding(.bottom, 12)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // CTA
                Button {
                    Task {
                        await auth.login(username: username, password: password)
                    }
                } label: {
                    if auth.isLoading {
                        AuthPill(label: "", style: .primary, isLoading: true)
                    } else {
                        AuthPill(label: "Accedi", style: .primary)
                    }
                }
                .contentShape(Capsule())
                .disabled(auth.isLoading)

                Spacer()
            }
            .padding(.horizontal, 28)
            .padding(.top, 20)
        }
        .navigationBarBackButtonHidden(true)
        .toolbarVisibility(.hidden, for: .navigationBar)
        .animation(.easeInOut(duration: 0.2), value: auth.errorMessage)
    }
}

// MARK: - Main App (post-login)

struct MainAppView: View {
    @State private var auth = AuthManager.shared
    private let bg = Color(red: 28/255, green: 28/255, blue: 30/255)

    var body: some View {
        TabView {
            Tab("Lista", systemImage: "cart") {
                ShoppingListView()
            }
            Tab("Calendario", systemImage: "calendar") {
                CalendarView()
            }
            Tab("Profilo", systemImage: "person.circle") {
                ProfileView()
            }
        }
    }
}

// MARK: - Icon Picker View

struct AppIconOption: Identifiable {
    let id: String          // nome icona (nil = primaria)
    let assetName: String?  // nome immagine in Assets o bundle (nil = usa AppLogo)
    let label: String
}

struct IconPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentIcon: String? = UIApplication.shared.alternateIconName
    private let bg = Color(red: 28/255, green: 28/255, blue: 30/255)

    private let icons: [AppIconOption] = [
        AppIconOption(id: "default",      assetName: nil,              label: "Originale"),
        AppIconOption(id: "AppIconPurple", assetName: "AppIconPurple", label: "Viola"),
        AppIconOption(id: "AppIconWhite",  assetName: "AppIconWhite",  label: "Bianca"),
        AppIconOption(id: "AppIconGray",   assetName: "AppIconGray",   label: "Grigia"),
    ]

    private var selectedId: String {
        currentIcon ?? "default"
    }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 38, height: 38)
                            .glassEffect(.regular, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .contentShape(Circle())
                    Spacer()
                }
                .padding(.bottom, 32)

                VStack(spacing: 6) {
                    Text("Icona App")
                        .font(.title.bold())
                        .foregroundStyle(.white)
                    Text("Scegli lo stile che preferisci")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.45))
                }
                .padding(.bottom, 40)

                // Griglia icone 2×2
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    ForEach(icons) { option in
                        IconOptionCell(
                            option: option,
                            isSelected: selectedId == option.id
                        ) {
                            applyIcon(option)
                        }
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 28)
            .padding(.top, 20)
        }
        .navigationBarBackButtonHidden(true)
        .toolbarVisibility(.hidden, for: .navigationBar)
    }

    private func applyIcon(_ option: AppIconOption) {
        let iconName: String? = option.id == "default" ? nil : option.id
        guard UIApplication.shared.supportsAlternateIcons else { return }
        UIApplication.shared.setAlternateIconName(iconName) { error in
            if error == nil {
                currentIcon = iconName
            }
        }
    }
}

struct IconOptionCell: View {
    let option: AppIconOption
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Preview icona
                Group {
                    if let asset = option.assetName,
                       let uiImg = UIImage(named: asset) ?? UIImage(contentsOfFile: Bundle.main.path(forResource: asset, ofType: nil) ?? "") {
                        Image(uiImage: uiImg)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image("AppLogo")
                            .resizable()
                            .scaledToFill()
                    }
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2.5)
                )
                .shadow(color: .black.opacity(0.3), radius: 8, y: 4)

                Text(option.label)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.55))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .opacity(isSelected ? 1 : 0.8)
        }
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .buttonStyle(.plain)
    }
}

// MARK: - Placeholder views (da implementare)

struct ShoppingListView: View {
    private let bg = Color(red: 28/255, green: 28/255, blue: 30/255)
    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            Text("Lista della Spesa")
                .foregroundStyle(.white)
        }
    }
}

struct CalendarView: View {
    private let bg = Color(red: 28/255, green: 28/255, blue: 30/255)
    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            Text("Calendario")
                .foregroundStyle(.white)
        }
    }
}

struct ProfileView: View {
    @State private var auth = AuthManager.shared
    @State private var navigateToIconPicker = false
    private let bg = Color(red: 28/255, green: 28/255, blue: 30/255)

    var body: some View {
        NavigationStack {
            ZStack {
                bg.ignoresSafeArea()

                VStack(spacing: 28) {
                    Spacer()

                    // Avatar + nome
                    VStack(spacing: 14) {
                        Image("AppLogo")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                        Text(auth.currentUser?.email?
                            .replacingOccurrences(of: "@simply.app", with: "") ?? "")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                    }

                    Spacer()

                    // Azioni
                    VStack(spacing: 12) {
                        // Icona App
                        NavigationLink(destination: IconPickerView()) {
                            HStack {
                                Image(systemName: "app.badge")
                                    .font(.system(size: 17))
                                    .foregroundStyle(.white.opacity(0.8))
                                    .frame(width: 28)
                                Text("Icona App")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(.white)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.35))
                            }
                            .padding(.horizontal, 20)
                            .frame(height: 54)
                            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .buttonStyle(.plain)

                        // Esci
                        Button {
                            auth.logout()
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 17))
                                    .foregroundStyle(.red.opacity(0.85))
                                    .frame(width: 28)
                                Text("Esci")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(.red.opacity(0.85))
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .frame(height: 54)
                            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 28)

                    Spacer()
                        .frame(height: 20)
                }
            }
            .toolbarVisibility(.hidden, for: .navigationBar)
        }
    }
}

// MARK: - AuthPill (bottone riutilizzabile)

enum AuthPillStyle { case primary, outlined }

struct AuthPill: View {
    let label: String
    let style: AuthPillStyle
    var isLoading: Bool = false

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .tint(style == .primary ? .black : .white)
            } else {
                Text(label)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(style == .primary ? .black : .white)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 54)
        .background {
            switch style {
            case .primary:
                Capsule().fill(Color.white)
            case .outlined:
                Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1)
            }
        }
        .contentShape(Capsule())
    }
}

// MARK: - AuthField

struct AuthField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundStyle(.white.opacity(0.5))
                .frame(width: 18)
            TextField(
                "",
                text: $text,
                prompt: Text(placeholder).foregroundStyle(.white.opacity(0.35))
            )
            .foregroundStyle(.white)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
        }
        .padding(.horizontal, 18)
        .frame(height: 54)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - AuthSecureField

struct AuthSecureField: View {
    let placeholder: String
    @Binding var text: String
    @Binding var show: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "lock")
                .foregroundStyle(.white.opacity(0.5))
                .frame(width: 18)
            Group {
                if show {
                    TextField(
                        "",
                        text: $text,
                        prompt: Text(placeholder).foregroundStyle(.white.opacity(0.35))
                    )
                } else {
                    SecureField(
                        "",
                        text: $text,
                        prompt: Text(placeholder).foregroundStyle(.white.opacity(0.35))
                    )
                }
            }
            .foregroundStyle(.white)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)

            Button {
                show.toggle()
            } label: {
                Image(systemName: show ? "eye.slash" : "eye")
                    .foregroundStyle(.white.opacity(0.45))
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .frame(height: 54)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview { ContentView() }
