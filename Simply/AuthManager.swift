import FirebaseAuth
import FirebaseFirestore
import SwiftUI

// MARK: - Models

struct ShoppingItem: Identifiable, Equatable {
    var id: String
    var name: String
    var completed: Bool
    var createdAt: Date

    init(id: String = UUID().uuidString, name: String, completed: Bool = false, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.completed = completed
        self.createdAt = createdAt
    }
}

struct Friend: Identifiable {
    var id: String       // uid dell'amico
    var nickname: String
    var friendCode: String
}

// MARK: - AuthManager

@MainActor
@Observable
class AuthManager {

    static let shared = AuthManager()

    // Auth
    var currentUser: FirebaseAuth.User? = nil
    var isLoading = false
    var errorMessage: String? = nil

    // Profilo
    var username: String = ""
    var friendCode: String = ""

    // Amici
    var friends: [Friend] = []

    // Lista mia
    var myItems: [ShoppingItem] = []

    // Liste amici { uid -> [ShoppingItem] }
    var friendsItems: [String: [ShoppingItem]] = [:]

    private let db = Firestore.firestore()
    private var myItemsListener: ListenerRegistration?
    private var friendsListeners: [String: ListenerRegistration] = [:]

    private init() {
        currentUser = Auth.auth().currentUser
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
                if let user = user {
                    await self?.loadProfile(uid: user.uid)
                    await self?.loadFriends(uid: user.uid)
                    self?.startMyItemsListener(uid: user.uid)
                } else {
                    self?.clearAll()
                }
            }
        }
    }

    // MARK: - Helpers

    private func email(from username: String) -> String {
        "\(username.lowercased().trimmingCharacters(in: .whitespaces))@simply.app"
    }

    private func generateCode() -> String {
        String(format: "%06d", Int.random(in: 100000...999999))
    }

    private func clearAll() {
        username = ""; friendCode = ""
        friends = []; myItems = []; friendsItems = [:]
        myItemsListener?.remove(); myItemsListener = nil
        friendsListeners.values.forEach { $0.remove() }
        friendsListeners = [:]
    }

    // MARK: - Register

    func register(username: String, password: String, confirmPassword: String) async {
        errorMessage = nil
        let clean = username.trimmingCharacters(in: .whitespaces)
        guard !clean.isEmpty else { errorMessage = "Inserisci un nome utente"; return }
        guard clean.count >= 3 else { errorMessage = "Nome utente: min. 3 caratteri"; return }
        guard password.count >= 6 else { errorMessage = "Password: min. 6 caratteri"; return }
        guard password == confirmPassword else { errorMessage = "Le password non coincidono"; return }

        isLoading = true; defer { isLoading = false }

        do {
            // Codice amico unico
            var code = generateCode()
            while (try? await db.collection("friendCodes").document(code).getDocument())?.exists == true {
                code = generateCode()
            }

            let result = try await Auth.auth().createUser(withEmail: email(from: clean), password: password)
            let uid = result.user.uid
            let lower = clean.lowercased()

            try await db.collection("users").document(uid).setData([
                "username": lower,
                "friendCode": code,
                "createdAt": FieldValue.serverTimestamp()
            ])
            try await db.collection("friendCodes").document(code).setData(["uid": uid])

            self.username = lower
            self.friendCode = code
            currentUser = result.user
        } catch let err as NSError {
            errorMessage = mapError(err)
        }
    }

    // MARK: - Login

    func login(username: String, password: String) async {
        errorMessage = nil
        let clean = username.trimmingCharacters(in: .whitespaces)
        guard !clean.isEmpty else { errorMessage = "Inserisci un nome utente"; return }
        guard !password.isEmpty else { errorMessage = "Inserisci la password"; return }

        isLoading = true; defer { isLoading = false }

        do {
            let result = try await Auth.auth().signIn(withEmail: email(from: clean), password: password)
            currentUser = result.user
        } catch let err as NSError {
            errorMessage = mapError(err)
        }
    }

    // MARK: - Logout

    func logout() {
        clearAll()
        try? Auth.auth().signOut()
        currentUser = nil
    }

    // MARK: - Profilo

    func loadProfile(uid: String) async {
        guard let doc = try? await db.collection("users").document(uid).getDocument(),
              let data = doc.data() else { return }
        self.username = data["username"] as? String ?? ""
        self.friendCode = data["friendCode"] as? String ?? ""
    }

    // MARK: - Amici

    func loadFriends(uid: String) async {
        guard let snap = try? await db.collection("users").document(uid)
                .collection("friends").getDocuments() else { return }
        self.friends = snap.documents.compactMap { doc -> Friend? in
            let d = doc.data()
            guard let nickname = d["nickname"] as? String,
                  let code = d["friendCode"] as? String else { return nil }
            return Friend(id: doc.documentID, nickname: nickname, friendCode: code)
        }
        for f in friends { startFriendItemsListener(friendUid: f.id) }
    }

    func addFriend(code: String, nickname: String) async {
        errorMessage = nil
        let cleanCode = code.trimmingCharacters(in: .whitespaces)
        let cleanNick = nickname.trimmingCharacters(in: .whitespaces)
        guard cleanCode.count == 6 else { errorMessage = "Il codice deve essere di 6 cifre"; return }
        guard !cleanNick.isEmpty else { errorMessage = "Inserisci un nickname"; return }
        guard cleanCode != friendCode else { errorMessage = "Non puoi aggiungere te stesso!"; return }
        guard let uid = currentUser?.uid else { return }

        isLoading = true; defer { isLoading = false }

        do {
            let snap = try await db.collection("friendCodes").document(cleanCode).getDocument()
            guard snap.exists, let friendUid = snap.data()?["uid"] as? String else {
                errorMessage = "Codice non trovato"
                return
            }
            guard !friends.contains(where: { $0.id == friendUid }) else {
                errorMessage = "Amico già aggiunto"
                return
            }

            try await db.collection("users").document(uid)
                .collection("friends").document(friendUid).setData([
                    "nickname": cleanNick,
                    "friendCode": cleanCode,
                    "addedAt": FieldValue.serverTimestamp()
                ])

            let f = Friend(id: friendUid, nickname: cleanNick, friendCode: cleanCode)
            friends.append(f)
            startFriendItemsListener(friendUid: friendUid)
        } catch {
            errorMessage = "Errore nell'aggiunta"
        }
    }

    func removeFriend(_ friendUid: String) {
        guard let uid = currentUser?.uid else { return }
        friends.removeAll { $0.id == friendUid }
        friendsListeners[friendUid]?.remove()
        friendsListeners.removeValue(forKey: friendUid)
        friendsItems.removeValue(forKey: friendUid)
        Task { try? await db.collection("users").document(uid)
                .collection("friends").document(friendUid).delete() }
    }

    // MARK: - Lista mia

    func startMyItemsListener(uid: String) {
        myItemsListener?.remove()
        myItemsListener = db.collection("users").document(uid)
            .collection("shopping_items")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snap, _ in
                guard let self, let docs = snap?.documents else { return }
                Task { @MainActor in
                    self.myItems = docs.compactMap { doc -> ShoppingItem? in
                        let d = doc.data()
                        guard let name = d["name"] as? String else { return nil }
                        return ShoppingItem(
                            id: doc.documentID,
                            name: name,
                            completed: d["completed"] as? Bool ?? false,
                            createdAt: (d["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                        )
                    }
                }
            }
    }

    func addMyItem(_ name: String) {
        guard let uid = currentUser?.uid else { return }
        let t = name.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        Task {
            try? await db.collection("users").document(uid)
                .collection("shopping_items").addDocument(data: [
                    "name": t,
                    "completed": false,
                    "createdAt": FieldValue.serverTimestamp()
                ])
        }
    }

    func toggleMyItem(_ item: ShoppingItem) {
        guard let uid = currentUser?.uid else { return }
        Task {
            try? await db.collection("users").document(uid)
                .collection("shopping_items").document(item.id)
                .updateData(["completed": !item.completed])
        }
    }

    func deleteMyItem(_ item: ShoppingItem) {
        guard let uid = currentUser?.uid else { return }
        Task {
            try? await db.collection("users").document(uid)
                .collection("shopping_items").document(item.id).delete()
        }
    }

    // MARK: - Lista amici

    func startFriendItemsListener(friendUid: String) {
        friendsListeners[friendUid]?.remove()
        friendsListeners[friendUid] = db.collection("users").document(friendUid)
            .collection("shopping_items")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snap, _ in
                guard let self, let docs = snap?.documents else { return }
                Task { @MainActor in
                    self.friendsItems[friendUid] = docs.compactMap { doc -> ShoppingItem? in
                        let d = doc.data()
                        guard let name = d["name"] as? String else { return nil }
                        return ShoppingItem(
                            id: doc.documentID,
                            name: name,
                            completed: d["completed"] as? Bool ?? false,
                            createdAt: (d["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                        )
                    }
                }
            }
    }

    // Spunta un elemento della lista di un amico
    func toggleFriendItem(_ item: ShoppingItem, friendUid: String) {
        Task {
            try? await db.collection("users").document(friendUid)
                .collection("shopping_items").document(item.id)
                .updateData(["completed": !item.completed])
        }
    }

    // MARK: - Errori

    private func mapError(_ error: NSError) -> String {
        switch AuthErrorCode(rawValue: error.code) {
        case .emailAlreadyInUse: return "Nome utente già in uso"
        case .wrongPassword, .invalidCredential: return "Password errata"
        case .userNotFound, .invalidEmail: return "Nome utente non trovato"
        case .networkError: return "Errore di rete"
        case .weakPassword: return "Password troppo debole (min. 6 caratteri)"
        case .tooManyRequests: return "Troppi tentativi. Riprova più tardi."
        default: return error.localizedDescription
        }
    }
}
