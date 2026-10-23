import SwiftUI
import AuthenticationServices

// MARK: - Root

struct ContentView: View {
    var body: some View {
        NavigationStack {
            LandingView()
                .toolbarVisibility(.hidden, for: .navigationBar)
        }
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
                VStack(spacing: 18) {
                    Image("AppLogo")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 86, height: 86)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                    Text("Simply")
                        .font(.title.bold())
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

                    // Continua con Apple
                    SignInWithAppleButton(.continue) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        switch result {
                        case .success:
                            break // Gestione futura
                        case .failure:
                            break
                        }
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 54)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.25), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 28)

                Spacer()
            }
        }
    }
}

// MARK: - Register

struct RegisterView: View {
    @State private var name = ""
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

                // Logo piccolo + titolo in stile landing
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
                    AuthField(icon: "person", placeholder: "Nome utente", text: $name)
                    AuthSecureField(placeholder: "Password", text: $password, show: $showPassword)
                    AuthSecureField(placeholder: "Conferma Password", text: $confirmPassword, show: $showConfirm)
                }
                .padding(.bottom, 24)

                // CTA
                Button {} label: {
                    AuthPill(label: "Crea Account", style: .primary)
                }
                .contentShape(Capsule())

                Spacer()
            }
            .padding(.horizontal, 28)
            .padding(.top, 20)
        }
        .navigationBarBackButtonHidden(true)
        .toolbarVisibility(.hidden, for: .navigationBar)
    }
}

// MARK: - Login

struct LoginView: View {
    @State private var name = ""
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

                // Logo piccolo + titolo in stile landing
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
                    AuthField(icon: "person", placeholder: "Nome utente", text: $name)
                    AuthSecureField(placeholder: "Password", text: $password, show: $showPassword)
                }
                .padding(.bottom, 24)

                // CTA
                Button {} label: {
                    AuthPill(label: "Accedi", style: .primary)
                }
                .contentShape(Capsule())

                Spacer()
            }
            .padding(.horizontal, 28)
            .padding(.top, 20)
        }
        .navigationBarBackButtonHidden(true)
        .toolbarVisibility(.hidden, for: .navigationBar)
    }
}

// MARK: - AuthPill (bottone riutilizzabile)

enum AuthPillStyle { case primary, outlined }

struct AuthPill: View {
    let label: String
    let style: AuthPillStyle

    var body: some View {
        Text(label)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(style == .primary ? .black : .white)
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
