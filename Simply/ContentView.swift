import SwiftUI

// MARK: - Root

struct ContentView: View {
    var body: some View {
        NavigationStack {
            LandingView()
        }
        .navigationBarHidden(true)
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

                // Logo + Nome App
                VStack(spacing: 20) {
                    Image("AppLogo")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 90, height: 90)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                    Text("Simply")
                        .font(.title.bold())
                        .foregroundStyle(.white)
                }

                Spacer()
                Spacer()

                // Pulsanti di accesso
                VStack(spacing: 12) {
                    // Registrati
                    NavigationLink(destination: RegisterView()) {
                        LandingPill(label: "Registrati con username", style: .primary)
                    }
                    .buttonStyle(.plain)

                    // Accedi
                    NavigationLink(destination: LoginView()) {
                        LandingPill(label: "Accedi", style: .outlined)
                    }
                    .buttonStyle(.plain)

                    Divider()
                        .overlay(Color.white.opacity(0.12))
                        .padding(.vertical, 4)

                    // Continue with Apple
                    Button {} label: {
                        LandingPill(label: "Continue with Apple", style: .apple)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 28)

                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Landing Pill Button

enum LandingStyle { case primary, outlined, apple }

struct LandingPill: View {
    let label: String
    let style: LandingStyle

    var body: some View {
        HStack(spacing: 10) {
            if style == .apple {
                Image(systemName: "apple.logo")
                    .font(.system(size: 18, weight: .medium))
            }
            Text(label)
                .font(.system(size: 16, weight: .semibold))
        }
        .foregroundStyle(style == .primary ? .black : .white)
        .frame(maxWidth: .infinity)
        .frame(height: 54)
        .background {
            switch style {
            case .primary:
                Capsule().fill(.white)
            case .outlined, .apple:
                Capsule()
                    .stroke(.white.opacity(0.25), lineWidth: 1)
            }
        }
    }
}

// MARK: - Register View

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

            VStack(alignment: .leading, spacing: 0) {
                // Back
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(12)
                        .glassEffect(.regular, in: Circle())
                }
                .padding(.bottom, 24)

                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text("Crea Account")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                    Text("Inserisci i tuoi dati per iniziare")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.45))
                }
                .padding(.bottom, 36)

                // Campi
                VStack(spacing: 12) {
                    AuthField(icon: "person", placeholder: "Nome utente", text: $name)
                    AuthSecureField(placeholder: "Password", text: $password, show: $showPassword)
                    AuthSecureField(placeholder: "Conferma Password", text: $confirmPassword, show: $showConfirm)
                }
                .padding(.bottom, 28)

                // Bottone
                Button {} label: {
                    Text("Crea Account")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(.white)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(.horizontal, 28)
            .padding(.top, 20)
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Login View

struct LoginView: View {
    @State private var name = ""
    @State private var password = ""
    @State private var showPassword = false
    @Environment(\.dismiss) private var dismiss

    private let bg = Color(red: 28/255, green: 28/255, blue: 30/255)

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Back
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(12)
                        .glassEffect(.regular, in: Circle())
                }
                .padding(.bottom, 24)

                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text("Bentornato")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                    Text("Accedi al tuo account Simply")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.45))
                }
                .padding(.bottom, 36)

                // Campi
                VStack(spacing: 12) {
                    AuthField(icon: "person", placeholder: "Nome utente", text: $name)
                    AuthSecureField(placeholder: "Password", text: $password, show: $showPassword)
                }
                .padding(.bottom, 28)

                // Bottone
                Button {} label: {
                    Text("Accedi")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(.white)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                Spacer()
            }
            .padding(.horizontal, 28)
            .padding(.top, 20)
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Componenti condivisi

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

// MARK: - Preview

#Preview { ContentView() }
