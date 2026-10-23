import FirebaseAuth
import FirebaseFirestore
import SwiftUI

// MARK: - AuthManager

@MainActor
@Observable
class AuthManager {

    static let shared = AuthManager()

    var currentUser: FirebaseAuth.User? = nil
    var isLoading = false
    var errorMessage: String? = nil

    private let db = Firestore.firestore()

    private init() {
        currentUser = Auth.auth().currentUser
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
            }
        }
    }

    // MARK: - Helpers

    private func email(from username: String) -> String {
        let clean = username.lowercased().trimmingCharacters(in: .whitespaces)
        return "\(clean)@simply.app"
    }

    // MARK: - Register

    func register(username: String, password: String, confirmPassword: String) async {
        errorMessage = nil
        let cleanUsername = username.trimmingCharacters(in: .whitespaces)

        guard !cleanUsername.isEmpty else {
            errorMessage = "Inserisci un nome utente"
            return
        }
        guard cleanUsername.count >= 3 else {
            errorMessage = "Il nome utente deve avere almeno 3 caratteri"
            return
        }
        guard password.count >= 6 else {
            errorMessage = "La password deve avere almeno 6 caratteri"
            return
        }
        guard password == confirmPassword else {
            errorMessage = "Le password non coincidono"
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await Auth.auth().createUser(
                withEmail: email(from: cleanUsername),
                password: password
            )
            try await db.collection("users").document(result.user.uid).setData([
                "username": cleanUsername.lowercased(),
                "createdAt": FieldValue.serverTimestamp()
            ])
            currentUser = result.user
        } catch let err as NSError {
            errorMessage = mapFirebaseError(err)
        }
    }

    // MARK: - Login

    func login(username: String, password: String) async {
        errorMessage = nil
        let cleanUsername = username.trimmingCharacters(in: .whitespaces)

        guard !cleanUsername.isEmpty else {
            errorMessage = "Inserisci un nome utente"
            return
        }
        guard !password.isEmpty else {
            errorMessage = "Inserisci la password"
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await Auth.auth().signIn(
                withEmail: email(from: cleanUsername),
                password: password
            )
            currentUser = result.user
        } catch let err as NSError {
            errorMessage = mapFirebaseError(err)
        }
    }

    // MARK: - Logout

    func logout() {
        try? Auth.auth().signOut()
        currentUser = nil
    }

    // MARK: - Error mapping (messaggi in italiano)

    private func mapFirebaseError(_ error: NSError) -> String {
        let code = AuthErrorCode(rawValue: error.code)
        switch code {
        case .emailAlreadyInUse:
            return "Nome utente già in uso"
        case .wrongPassword, .invalidCredential:
            return "Password errata"
        case .userNotFound, .invalidEmail:
            return "Nome utente non trovato"
        case .networkError:
            return "Errore di rete. Controlla la connessione."
        case .weakPassword:
            return "Password troppo debole (min. 6 caratteri)"
        case .tooManyRequests:
            return "Troppi tentativi. Riprova più tardi."
        default:
            return "Errore: \(error.localizedDescription)"
        }
    }
}
