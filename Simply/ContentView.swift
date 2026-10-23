import SwiftUI

// MARK: - Content View

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Registrati", systemImage: "person.badge.plus") {
                RegisterView()
            }
            Tab("Accedi", systemImage: "arrow.right.circle.fill") {
                LoginView()
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

    private let bg = Color(red: 28/255, green: 28/255, blue: 30/255)

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text("Crea Account")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                    Text("Benvenuto in Simply")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.45))
                }
                .padding(.bottom, 36)

                // Campi
                VStack(spacing: 12) {
                    AuthField(icon: "person", placeholder: "Nome", text: $name)
                    AuthSecureField(placeholder: "Password", text: $password, show: $showPassword)
                    AuthSecureField(placeholder: "Conferma Password", text: $confirmPassword, show: $showConfirm)
                }
                .padding(.bottom, 24)

                // Pulsante
                AuthButton(label: "Registrati") {}
            }
            .padding(.horizontal, 28)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
}

// MARK: - Login View

struct LoginView: View {
    @State private var name = ""
    @State private var password = ""
    @State private var showPassword = false

    private let bg = Color(red: 28/255, green: 28/255, blue: 30/255)

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text("Bentornato")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                    Text("Accedi al tuo account")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.45))
                }
                .padding(.bottom, 36)

                // Campi
                VStack(spacing: 12) {
                    AuthField(icon: "person", placeholder: "Nome", text: $name)
                    AuthSecureField(placeholder: "Password", text: $password, show: $showPassword)
                }
                .padding(.bottom, 24)

                // Pulsante
                AuthButton(label: "Accedi") {}
            }
            .padding(.horizontal, 28)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
}

// MARK: - Componenti Condivisi

struct AuthField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundStyle(.white.opacity(0.55))
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
                .foregroundStyle(.white.opacity(0.55))
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

struct AuthButton: View {
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
