import FirebaseAuth
import FirebaseFirestore
import SwiftUI
import UserNotifications

// MARK: - Models

struct ShoppingItem: Identifiable, Equatable {
    var id: String
    var name: String
    var quantity: String
    var completed: Bool
    var createdAt: Date

    init(id: String = UUID().uuidString, name: String, quantity: String = "", completed: Bool = false, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.completed = completed
        self.createdAt = createdAt
    }
}

struct CalendarEvent: Identifiable, Codable, Equatable {
    var id: String
    var title: String
    var date: Date
    var startTime: Date
    var isCompleted: Bool
    var reminderEnabled: Bool
    var reminderTime: Date?

    init(
        id: String = UUID().uuidString,
        title: String,
        date: Date,
        startTime: Date,
        isCompleted: Bool = false,
        reminderEnabled: Bool = false,
        reminderTime: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.startTime = startTime
        self.isCompleted = isCompleted
        self.reminderEnabled = reminderEnabled
        self.reminderTime = reminderTime
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

    // Spesa
    var myItems: [ShoppingItem] = []
    var friendsItems: [String: [ShoppingItem]] = [:]

    // Calendario
    var calendarEvents: [CalendarEvent] = []

    private let db = Firestore.firestore()
    private var myItemsListener: ListenerRegistration?
    private var friendsListeners: [String: ListenerRegistration] = [:]
    private var calendarListener: ListenerRegistration?

    private init() {
        requestNotificationPermission()
        currentUser = Auth.auth().currentUser
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
                if let user = user {
                    await self?.loadProfile(uid: user.uid)
                    await self?.loadFriends(uid: user.uid)
                    self?.startMyItemsListener(uid: user.uid)
                    self?.startCalendarListener(uid: user.uid)
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
        friends = []; myItems = []; friendsItems = []
        calendarEvents = []
        myItemsListener?.remove(); myItemsListener = nil
        calendarListener?.remove(); calendarListener = nil
        friendsListeners.values.forEach { $0.remove() }
        friendsListeners = [:]
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
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

    // MARK: - Lista spesa mia

    func startMyItemsListener(uid: String) {
        myItemsListener?.remove()
        myItemsListener = db.collection("users").document(uid)
            .collection("shopping_items")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snap, _ in
                guard let self, let docs = snap?.documents else { return }
                Task { @MainActor in
                    let newItems = docs.compactMap { doc -> ShoppingItem? in
                        let d = doc.data()
                        guard let name = d["name"] as? String else { return nil }
                        return ShoppingItem(
                            id: doc.documentID,
                            name: name,
                            quantity: d["quantity"] as? String ?? "",
                            completed: d["completed"] as? Bool ?? false,
                            createdAt: (d["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                        )
                    }
                    if self.myItems != newItems {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                            self.myItems = newItems
                        }
                    }
                }
            }
    }

    func addMyItem(name: String, quantity: String = "") {
        guard let uid = currentUser?.uid else { return }
        let t = name.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }

        let tempId = UUID().uuidString
        let tempItem = ShoppingItem(id: tempId, name: t, quantity: quantity, completed: false, createdAt: Date())

        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
            myItems.insert(tempItem, at: 0)
        }

        Task {
            if let ref = try? await db.collection("users").document(uid)
                .collection("shopping_items").addDocument(data: [
                    "name": t,
                    "quantity": quantity,
                    "completed": false,
                    "createdAt": FieldValue.serverTimestamp()
                ]) {
                if let idx = self.myItems.firstIndex(where: { $0.id == tempId }) {
                    self.myItems[idx].id = ref.documentID
                }
            }
        }
    }

    func toggleMyItem(_ item: ShoppingItem) {
        guard let uid = currentUser?.uid else { return }

        if let idx = myItems.firstIndex(where: { $0.id == item.id }) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                myItems[idx].completed.toggle()
            }
        }

        Task {
            try? await db.collection("users").document(uid)
                .collection("shopping_items").document(item.id)
                .updateData(["completed": !item.completed])
        }
    }

    func deleteMyItem(_ item: ShoppingItem) {
        guard let uid = currentUser?.uid else { return }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            myItems.removeAll { $0.id == item.id }
        }

        Task {
            try? await db.collection("users").document(uid)
                .collection("shopping_items").document(item.id).delete()
        }
    }

    // MARK: - Lista spesa amici

    func startFriendItemsListener(friendUid: String) {
        friendsListeners[friendUid]?.remove()
        friendsListeners[friendUid] = db.collection("users").document(friendUid)
            .collection("shopping_items")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snap, _ in
                guard let self, let docs = snap?.documents else { return }
                Task { @MainActor in
                    let newItems = docs.compactMap { doc -> ShoppingItem? in
                        let d = doc.data()
                        guard let name = d["name"] as? String else { return nil }
                        return ShoppingItem(
                            id: doc.documentID,
                            name: name,
                            quantity: d["quantity"] as? String ?? "",
                            completed: d["completed"] as? Bool ?? false,
                            createdAt: (d["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                        )
                    }
                    if self.friendsItems[friendUid] != newItems {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                            self.friendsItems[friendUid] = newItems
                        }
                    }
                }
            }
    }

    func toggleFriendItem(_ item: ShoppingItem, friendUid: String) {
        if var list = friendsItems[friendUid], let idx = list.firstIndex(where: { $0.id == item.id }) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                list[idx].completed.toggle()
                friendsItems[friendUid] = list
            }
        }

        Task {
            try? await db.collection("users").document(friendUid)
                .collection("shopping_items").document(item.id)
                .updateData(["completed": !item.completed])
        }
    }

    // MARK: - Calendario

    func startCalendarListener(uid: String) {
        calendarListener?.remove()
        calendarListener = db.collection("users").document(uid)
            .collection("calendar_events")
            .order(by: "startTime", descending: false)
            .addSnapshotListener { [weak self] snap, _ in
                guard let self, let docs = snap?.documents else { return }
                Task { @MainActor in
                    let loaded = docs.compactMap { doc -> CalendarEvent? in
                        let d = doc.data()
                        guard let title = d["title"] as? String else { return nil }
                        return CalendarEvent(
                            id: doc.documentID,
                            title: title,
                            date: (d["date"] as? Timestamp)?.dateValue() ?? Date(),
                            startTime: (d["startTime"] as? Timestamp)?.dateValue() ?? Date(),
                            isCompleted: d["isCompleted"] as? Bool ?? false,
                            reminderEnabled: d["reminderEnabled"] as? Bool ?? false,
                            reminderTime: (d["reminderTime"] as? Timestamp)?.dateValue()
                        )
                    }
                    if self.calendarEvents != loaded {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                            self.calendarEvents = loaded
                        }
                    }
                }
            }
    }

    func addEvent(title: String, date: Date, startTime: Date, reminderEnabled: Bool, reminderTime: Date? = nil) {
        guard let uid = currentUser?.uid else { return }
        let tempId = UUID().uuidString
        let newEvent = CalendarEvent(
            id: tempId,
            title: title,
            date: date,
            startTime: startTime,
            isCompleted: false,
            reminderEnabled: reminderEnabled,
            reminderTime: reminderTime
        )

        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
            calendarEvents.append(newEvent)
        }

        if reminderEnabled {
            scheduleNotification(for: newEvent)
        }

        Task {
            var data: [String: Any] = [
                "title": title,
                "date": Timestamp(date: date),
                "startTime": Timestamp(date: startTime),
                "isCompleted": false,
                "reminderEnabled": reminderEnabled,
                "createdAt": FieldValue.serverTimestamp()
            ]
            if let rt = reminderTime {
                data["reminderTime"] = Timestamp(date: rt)
            }

            if let ref = try? await db.collection("users").document(uid)
                .collection("calendar_events").addDocument(data: data) {
                if let idx = self.calendarEvents.firstIndex(where: { $0.id == tempId }) {
                    self.calendarEvents[idx].id = ref.documentID
                }
            }
        }
    }

    func updateEvent(_ event: CalendarEvent) {
        guard let uid = currentUser?.uid else { return }

        if let idx = calendarEvents.firstIndex(where: { $0.id == event.id }) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                calendarEvents[idx] = event
            }
        }

        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [event.id])
        if event.reminderEnabled {
            scheduleNotification(for: event)
        }

        Task {
            var data: [String: Any] = [
                "title": event.title,
                "date": Timestamp(date: event.date),
                "startTime": Timestamp(date: event.startTime),
                "isCompleted": event.isCompleted,
                "reminderEnabled": event.reminderEnabled
            ]
            if let rt = event.reminderTime {
                data["reminderTime"] = Timestamp(date: rt)
            } else {
                data["reminderTime"] = FieldValue.delete()
            }
            try? await db.collection("users").document(uid)
                .collection("calendar_events").document(event.id).updateData(data)
        }
    }

    func deleteEvent(_ event: CalendarEvent) {
        guard let uid = currentUser?.uid else { return }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            calendarEvents.removeAll { $0.id == event.id }
        }

        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [event.id])

        Task {
            try? await db.collection("users").document(uid)
                .collection("calendar_events").document(event.id).delete()
        }
    }

    func toggleCompleteEvent(_ event: CalendarEvent) {
        guard let uid = currentUser?.uid else { return }

        if let idx = calendarEvents.firstIndex(where: { $0.id == event.id }) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                calendarEvents[idx].isCompleted.toggle()
            }
        }

        Task {
            try? await db.collection("users").document(uid)
                .collection("calendar_events").document(event.id)
                .updateData(["isCompleted": !event.isCompleted])
        }
    }

    func events(for date: Date) -> [CalendarEvent] {
        calendarEvents.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.startTime < $1.startTime }
    }

    func hasEvents(on date: Date) -> Bool {
        calendarEvents.contains { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    private func scheduleNotification(for event: CalendarEvent) {
        let content = UNMutableNotificationContent()
        content.title = "Simply Promemoria"
        content.body = "\(event.title) alle \(event.startTime.formatted(.dateTime.hour().minute()))"
        content.sound = .default

        let cal = Calendar.current
        let targetTime = event.reminderTime ?? event.startTime
        var components = cal.dateComponents([.year, .month, .day], from: event.date)
        let timeComps = cal.dateComponents([.hour, .minute], from: targetTime)
        components.hour = timeComps.hour
        components.minute = timeComps.minute

        if let scheduledDate = cal.date(from: components), scheduledDate < Date() {
            return
        }

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: event.id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
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
