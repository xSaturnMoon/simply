import FirebaseAuth
import FirebaseFirestore
import SwiftUI
import UserNotifications
import WidgetKit

// MARK: - Models

struct ShoppingItem: Identifiable, Equatable, Codable {
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

struct Friend: Identifiable, Equatable, Codable {
    var id: String       // uid dell'amico
    var nickname: String
    var friendCode: String
}

public struct WidgetReminderItem: Codable, Identifiable {
    public let id: String
    public let title: String
    public let timeString: String
    public let isCompleted: Bool
    public let date: Date

    public init(id: String, title: String, timeString: String, isCompleted: Bool, date: Date) {
        self.id = id
        self.title = title
        self.timeString = timeString
        self.isCompleted = isCompleted
        self.date = date
    }
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
    private var friendsListener: ListenerRegistration?
    private var friendsListeners: [String: ListenerRegistration] = [:]
    private var calendarListener: ListenerRegistration?
    private var hasLoadedCalendarEvents = false

    private init() {
        let settings = Firestore.firestore().settings
        settings.cacheSettings = PersistentCacheSettings(sizeBytes: NSNumber(value: FirestoreCacheSizeUnlimited))
        Firestore.firestore().settings = settings

        requestNotificationPermission()
        currentUser = Auth.auth().currentUser
        if let user = currentUser {
            loadProfileFromLocalCache(uid: user.uid)
            let localItems = loadMyItemsFromLocalCache(uid: user.uid)
            if !localItems.isEmpty {
                self.myItems = localItems
            }
            let localFriends = loadFriendsFromLocalCache(uid: user.uid)
            if !localFriends.isEmpty {
                self.friends = localFriends
            }
            let localEvents = loadCalendarFromLocalCache(uid: user.uid)
            if !localEvents.isEmpty {
                self.calendarEvents = localEvents
                self.hasLoadedCalendarEvents = true
                purgeOldEvents(uid: user.uid)
                cleanOrphanNotifications()
            }
        }
        _ = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.currentUser = user
                if let user = user {
                    self?.loadProfileFromLocalCache(uid: user.uid)
                    let localItems = self?.loadMyItemsFromLocalCache(uid: user.uid) ?? []
                    if !localItems.isEmpty && (self?.myItems.isEmpty ?? true) {
                        self?.myItems = localItems
                    }
                    let localFriends = self?.loadFriendsFromLocalCache(uid: user.uid) ?? []
                    if !localFriends.isEmpty && (self?.friends.isEmpty ?? true) {
                        self?.friends = localFriends
                    }
                    let localEvents = self?.loadCalendarFromLocalCache(uid: user.uid) ?? []
                    if !localEvents.isEmpty && (self?.calendarEvents.isEmpty ?? true) {
                        self?.calendarEvents = localEvents
                        self?.hasLoadedCalendarEvents = true
                        self?.purgeOldEvents(uid: user.uid)
                        self?.cleanOrphanNotifications()
                    }
                    await self?.loadProfile(uid: user.uid)
                    self?.startFriendsListener(uid: user.uid)
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

    private func generateUniqueFriendCode() async -> String {
        for _ in 0..<15 {
            let code = generateCode()
            if let snap = try? await db.collection("friendCodes").document(code).getDocument(), snap.exists {
                continue
            }
            return code
        }
        return generateCode()
    }

    // Cache profilo: username e friendCode disponibili istantaneamente anche offline
    private func saveProfileToLocalCache(username: String, friendCode: String, uid: String) {
        UserDefaults.standard.set(username, forKey: "simply_profile_username_\(uid)")
        UserDefaults.standard.set(friendCode, forKey: "simply_profile_code_\(uid)")
    }

    private func loadProfileFromLocalCache(uid: String) {
        if let u = UserDefaults.standard.string(forKey: "simply_profile_username_\(uid)"), !u.isEmpty {
            self.username = u
        }
        if let c = UserDefaults.standard.string(forKey: "simply_profile_code_\(uid)"), !c.isEmpty {
            self.friendCode = c
        }
    }

    // Cache spesa amici per consultazione istantanea offline
    private func saveFriendItemsToLocalCache(_ items: [ShoppingItem], friendUid: String) {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: "simply_friend_items_\(friendUid)")
        }
    }

    private func loadFriendItemsFromLocalCache(friendUid: String) -> [ShoppingItem] {
        guard let data = UserDefaults.standard.data(forKey: "simply_friend_items_\(friendUid)"),
              let items = try? JSONDecoder().decode([ShoppingItem].self, from: data) else {
            return []
        }
        return items
    }

    // Parsing robusto date per evitare incongruenze di formato
    private func parseDate(_ value: Any?) -> Date? {
        if let ts = value as? Timestamp {
            return ts.dateValue()
        } else if let d = value as? Date {
            return d
        } else if let ti = value as? TimeInterval {
            return Date(timeIntervalSince1970: ti)
        }
        return nil
    }

    // Cache locale di sicurezza per gli amici: nessun ritardo e zero perdite!
    private func saveFriendsToLocalCache(_ friends: [Friend], uid: String) {
        if let data = try? JSONEncoder().encode(friends) {
            UserDefaults.standard.set(data, forKey: "simply_friends_backup_\(uid)")
        }
    }

    private func loadFriendsFromLocalCache(uid: String) -> [Friend] {
        guard let data = UserDefaults.standard.data(forKey: "simply_friends_backup_\(uid)"),
              let friends = try? JSONDecoder().decode([Friend].self, from: data) else {
            return []
        }
        return friends
    }

    // Cache locale di sicurezza per la spesa: i dati non andranno mai persi!
    private func saveMyItemsToLocalCache(_ items: [ShoppingItem], uid: String) {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: "simply_shopping_backup_\(uid)")
        }
    }

    private func loadMyItemsFromLocalCache(uid: String) -> [ShoppingItem] {
        guard let data = UserDefaults.standard.data(forKey: "simply_shopping_backup_\(uid)"),
              let items = try? JSONDecoder().decode([ShoppingItem].self, from: data) else {
            return []
        }
        return items
    }

    // Cache locale di sicurezza per il calendario: appuntamenti garantiti su disco!
    private func saveCalendarToLocalCache(_ events: [CalendarEvent], uid: String) {
        if let data = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(data, forKey: "simply_calendar_backup_\(uid)")
        }
        updateWidgetReminders(events)
    }

    // Condivisione con WidgetKit per i widget della schermata Home
    private func updateWidgetReminders(_ events: [CalendarEvent]) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"

        let widgetItems = events
            .filter { !$0.isCompleted }
            .sorted { $0.startTime < $1.startTime }
            .prefix(50)
            .map { ev in
                WidgetReminderItem(
                    id: ev.id,
                    title: ev.title,
                    timeString: formatter.string(from: ev.startTime),
                    isCompleted: ev.isCompleted,
                    date: ev.startTime
                )
            }

        if let data = try? JSONEncoder().encode(Array(widgetItems)) {
            if let groupDefaults = UserDefaults(suiteName: "group.com.saturnmoon.simply") {
                groupDefaults.set(data, forKey: "simply_widget_reminders")
            }
            UserDefaults.standard.set(data, forKey: "simply_widget_reminders")
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func loadCalendarFromLocalCache(uid: String) -> [CalendarEvent] {
        guard let data = UserDefaults.standard.data(forKey: "simply_calendar_backup_\(uid)"),
              let events = try? JSONDecoder().decode([CalendarEvent].self, from: data) else {
            return []
        }
        return events
    }

    // Auto-eliminazione appuntamenti più vecchi di un mese (es. se oggi è il 24 ottobre, prima del 24 settembre si eliminano automaticamente)
    func purgeOldEvents(uid: String) {
        let cal = Calendar.current
        guard let cutoffDate = cal.date(byAdding: .month, value: -1, to: Date()) else { return }

        let expired = calendarEvents.filter { $0.date < cutoffDate }
        guard !expired.isEmpty else { return }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            calendarEvents.removeAll { $0.date < cutoffDate }
        }
        saveCalendarToLocalCache(calendarEvents, uid: uid)

        let expiredIds = expired.map { $0.id }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: expiredIds)
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: expiredIds)

        Task {
            for id in expiredIds {
                try? await db.collection("users").document(uid)
                    .collection("calendar_events").document(id).delete()
            }
        }
    }

    // Pulizia notifiche fantasma/orfane e sincronizzazione notifiche su nuovo dispositivo/login
    func cleanOrphanNotifications() {
        guard hasLoadedCalendarEvents else { return }
        UNUserNotificationCenter.current().getPendingNotificationRequests { [weak self] requests in
            guard let self else { return }
            Task { @MainActor in
                let activeEvents = self.calendarEvents.filter { $0.reminderEnabled && !$0.isCompleted }
                let activeIds = Set(activeEvents.map { $0.id })
                let scheduledIds = Set(requests.map { $0.identifier })

                let orphanIds = requests.map { $0.identifier }.filter { !activeIds.contains($0) }
                if !orphanIds.isEmpty {
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: orphanIds)
                    UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: orphanIds)
                }

                // Sincronizza su questo dispositivo le notifiche attive mancanti (es. dopo login o cambio account)
                for event in activeEvents {
                    if !scheduledIds.contains(event.id) {
                        self.scheduleNotification(for: event)
                    }
                }
            }
        }
    }

    private func clearAll() {
        username = ""; friendCode = ""
        friends = []; myItems = []; friendsItems = [:]
        calendarEvents = []
        hasLoadedCalendarEvents = false
        myItemsListener?.remove(); myItemsListener = nil
        friendsListener?.remove(); friendsListener = nil
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
            let code = await generateUniqueFriendCode()

            let result = try await Auth.auth().createUser(withEmail: email(from: clean), password: password)
            let uid = result.user.uid
            let lower = clean.lowercased()

            try await db.collection("users").document(uid).setData([
                "username": lower,
                "friendCode": code,
                "createdAt": FieldValue.serverTimestamp()
            ])
            try await db.collection("friendCodes").document(code).setData([
                "uid": uid,
                "username": lower
            ])

            self.username = lower
            self.friendCode = code
            saveProfileToLocalCache(username: lower, friendCode: code, uid: uid)
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
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        updateWidgetReminders([])
        try? Auth.auth().signOut()
        currentUser = nil
    }

    // MARK: - Profilo

    func loadProfile(uid: String) async {
        do {
            let doc = try await db.collection("users").document(uid).getDocument()
            var code = doc.data()?["friendCode"] as? String ?? ""
            var uName = doc.data()?["username"] as? String ?? ""

            if uName.isEmpty {
                uName = currentUser?.email?.components(separatedBy: "@").first ?? "utente"
            }

            // Se l'account non ha ancora un codice amico a 6 cifre valido, creane uno univoco
            if code.count != 6 {
                code = await generateUniqueFriendCode()
                try? await db.collection("users").document(uid).setData([
                    "username": uName,
                    "friendCode": code,
                    "updatedAt": FieldValue.serverTimestamp()
                ], merge: true)
            }

            // Assicuriamoci che l'indice friendCodes sia sempre registrato e aggiornato
            try? await db.collection("friendCodes").document(code).setData([
                "uid": uid,
                "username": uName
            ], merge: true)

            self.username = uName
            self.friendCode = code
            saveProfileToLocalCache(username: uName, friendCode: code, uid: uid)
        } catch {
            print("Errore caricamento profilo: \(error)")
        }
    }

    // MARK: - Amici (in tempo reale)

    func startFriendsListener(uid: String) {
        friendsListener?.remove()
        friendsListener = db.collection("users").document(uid)
            .collection("friends")
            .addSnapshotListener { [weak self] snap, error in
                guard let self else { return }
                if let error = error {
                    print("Friends listener error: \(error)")
                    return
                }
                guard let docs = snap?.documents else { return }

                Task { @MainActor in
                    let newFriends = docs.compactMap { doc -> Friend? in
                        let d = doc.data()
                        guard let nickname = d["nickname"] as? String,
                              let code = d["friendCode"] as? String else { return nil }
                        return Friend(id: doc.documentID, nickname: nickname, friendCode: code)
                    }

                    if self.friends != newFriends {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            self.friends = newFriends
                        }
                    }
                    self.saveFriendsToLocalCache(newFriends, uid: uid)

                    for f in newFriends {
                        self.startFriendItemsListener(friendUid: f.id)
                    }

                    let activeIds = Set(newFriends.map { $0.id })
                    for oldId in Array(self.friendsListeners.keys) where !activeIds.contains(oldId) {
                        self.friendsListeners[oldId]?.remove()
                        self.friendsListeners.removeValue(forKey: oldId)
                        self.friendsItems.removeValue(forKey: oldId)
                    }
                }
            }
    }

    func addFriend(code: String, nickname: String) async {
        errorMessage = nil
        let cleanCode = code
            .replacingOccurrences(of: "#", with: "")
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespaces)
        let cleanNick = nickname.trimmingCharacters(in: .whitespaces)

        guard cleanCode.count == 6 else {
            errorMessage = "Il codice amico deve essere di 6 cifre"
            return
        }
        guard !cleanNick.isEmpty else {
            errorMessage = "Inserisci un nickname per l'amico"
            return
        }
        guard cleanCode != friendCode else {
            errorMessage = "Non puoi inserire il tuo stesso codice!"
            return
        }
        guard let uid = currentUser?.uid else {
            errorMessage = "Sessione non valida"
            return
        }

        isLoading = true; defer { isLoading = false }

        do {
            let snap = try await db.collection("friendCodes").document(cleanCode).getDocument()
            guard snap.exists, let friendUid = snap.data()?["uid"] as? String, !friendUid.isEmpty else {
                errorMessage = "Codice non trovato. Verifica le cifre."
                return
            }

            if friendUid == uid {
                errorMessage = "Non puoi inserire il tuo stesso codice!"
                return
            }

            if friends.contains(where: { $0.id == friendUid }) {
                errorMessage = "Questo amico è già presente nella tua lista"
                return
            }

            // 1. Salva nella propria rubrica
            try await db.collection("users").document(uid)
                .collection("friends").document(friendUid).setData([
                    "nickname": cleanNick,
                    "friendCode": cleanCode,
                    "addedAt": FieldValue.serverTimestamp()
                ], merge: true)

            // 2. Connessione reciproca: crea automaticamente il contatto inverso nell'account dell'amico
            let myNick = self.username.isEmpty ? "Amico" : self.username
            try? await db.collection("users").document(friendUid)
                .collection("friends").document(uid).setData([
                    "nickname": myNick,
                    "friendCode": self.friendCode,
                    "addedAt": FieldValue.serverTimestamp()
                ], merge: true)

            let newFriend = Friend(id: friendUid, nickname: cleanNick, friendCode: cleanCode)
            if !friends.contains(where: { $0.id == friendUid }) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    friends.append(newFriend)
                }
                saveFriendsToLocalCache(friends, uid: uid)
            }
            startFriendItemsListener(friendUid: friendUid)
        } catch {
            print("Errore aggiunta amico: \(error)")
            errorMessage = "Errore durante l'aggiunta. Riprova."
        }
    }

    func removeFriend(_ friendUid: String) {
        guard let uid = currentUser?.uid else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            friends.removeAll { $0.id == friendUid }
        }
        saveFriendsToLocalCache(friends, uid: uid)
        friendsListeners[friendUid]?.remove()
        friendsListeners.removeValue(forKey: friendUid)
        friendsItems.removeValue(forKey: friendUid)

        Task {
            try? await db.collection("users").document(uid)
                .collection("friends").document(friendUid).delete()
            try? await db.collection("users").document(friendUid)
                .collection("friends").document(uid).delete()
        }
    }

    // MARK: - Lista spesa personale (salvataggio solido su Firestore + cache locale)

    func startMyItemsListener(uid: String) {
        myItemsListener?.remove()

        // Carica subito dal backup locale in memoria (zero delay per la mamma)
        let local = loadMyItemsFromLocalCache(uid: uid)
        if !local.isEmpty && myItems.isEmpty {
            myItems = local
        }

        myItemsListener = db.collection("users").document(uid)
            .collection("shopping_items")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snap, error in
                guard let self else { return }
                if let error = error {
                    print("Snapshot listener error spesa: \(error)")
                    return
                }
                guard let docs = snap?.documents else { return }

                Task { @MainActor in
                    let newItems = docs.compactMap { doc -> ShoppingItem? in
                        let d = doc.data()
                        guard let name = d["name"] as? String else { return nil }

                        let date = self.parseDate(d["createdAt"]) ?? self.parseDate(d["serverCreatedAt"]) ?? Date()

                        return ShoppingItem(
                            id: doc.documentID,
                            name: name,
                            quantity: d["quantity"] as? String ?? "",
                            completed: d["completed"] as? Bool ?? false,
                            createdAt: date
                        )
                    }

                    if self.myItems != newItems {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                            self.myItems = newItems
                        }
                    }
                    self.saveMyItemsToLocalCache(self.myItems, uid: uid)
                }
            }
    }

    func addMyItem(name: String, quantity: String = "") {
        guard let uid = currentUser?.uid else { return }
        let t = name.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }

        // Genera il documentID nativo di Firestore in anticipo: ID locale e remoto sincronizzati al 100%
        let docRef = db.collection("users").document(uid).collection("shopping_items").document()
        let itemId = docRef.documentID
        let now = Date()

        let newItem = ShoppingItem(
            id: itemId,
            name: t,
            quantity: quantity,
            completed: false,
            createdAt: now
        )

        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
            myItems.insert(newItem, at: 0)
        }
        saveMyItemsToLocalCache(myItems, uid: uid)

        Task {
            do {
                try await docRef.setData([
                    "id": itemId,
                    "name": t,
                    "quantity": quantity,
                    "completed": false,
                    "createdAt": Timestamp(date: now),
                    "serverCreatedAt": FieldValue.serverTimestamp()
                ])
            } catch {
                print("Errore salvataggio prodotto spesa su Firestore: \(error)")
            }
        }
    }

    func toggleMyItem(_ item: ShoppingItem) {
        guard let uid = currentUser?.uid else { return }

        if let idx = myItems.firstIndex(where: { $0.id == item.id }) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                myItems[idx].completed.toggle()
            }
            saveMyItemsToLocalCache(myItems, uid: uid)
        }

        let newStatus = !item.completed
        Task {
            do {
                try await db.collection("users").document(uid)
                    .collection("shopping_items").document(item.id)
                    .setData([
                        "completed": newStatus,
                        "updatedAt": FieldValue.serverTimestamp()
                    ], merge: true)
            } catch {
                print("Errore toggle spesa su Firestore: \(error)")
            }
        }
    }

    func deleteMyItem(_ item: ShoppingItem) {
        guard let uid = currentUser?.uid else { return }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            myItems.removeAll { $0.id == item.id }
        }
        saveMyItemsToLocalCache(myItems, uid: uid)

        Task {
            do {
                try await db.collection("users").document(uid)
                    .collection("shopping_items").document(item.id).delete()
            } catch {
                print("Errore cancellazione prodotto spesa su Firestore: \(error)")
            }
        }
    }

    // MARK: - Lista spesa amici (in tempo reale con cache locale)

    func startFriendItemsListener(friendUid: String) {
        guard friendsListeners[friendUid] == nil else { return }

        let local = loadFriendItemsFromLocalCache(friendUid: friendUid)
        if !local.isEmpty && (friendsItems[friendUid]?.isEmpty ?? true) {
            friendsItems[friendUid] = local
        }

        friendsListeners[friendUid] = db.collection("users").document(friendUid)
            .collection("shopping_items")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snap, error in
                guard let self else { return }
                if let error = error {
                    print("Friend items listener error: \(error)")
                    return
                }
                guard let docs = snap?.documents else { return }

                Task { @MainActor in
                    let newItems = docs.compactMap { doc -> ShoppingItem? in
                        let d = doc.data()
                        guard let name = d["name"] as? String else { return nil }

                        let date = self.parseDate(d["createdAt"]) ?? self.parseDate(d["serverCreatedAt"]) ?? Date()

                        return ShoppingItem(
                            id: doc.documentID,
                            name: name,
                            quantity: d["quantity"] as? String ?? "",
                            completed: d["completed"] as? Bool ?? false,
                            createdAt: date
                        )
                    }

                    if self.friendsItems[friendUid] != newItems {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                            self.friendsItems[friendUid] = newItems
                        }
                    }
                    self.saveFriendItemsToLocalCache(newItems, friendUid: friendUid)
                }
            }
    }

    func toggleFriendItem(_ item: ShoppingItem, friendUid: String) {
        if var list = friendsItems[friendUid], let idx = list.firstIndex(where: { $0.id == item.id }) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                list[idx].completed.toggle()
                friendsItems[friendUid] = list
            }
            saveFriendItemsToLocalCache(list, friendUid: friendUid)
        }

        let newStatus = !item.completed
        Task {
            do {
                try await db.collection("users").document(friendUid)
                    .collection("shopping_items").document(item.id)
                    .setData([
                        "completed": newStatus,
                        "updatedAt": FieldValue.serverTimestamp()
                    ], merge: true)
            } catch {
                print("Errore toggle spesa amico su Firestore: \(error)")
            }
        }
    }

    // MARK: - Calendario (Persistenza solida su Firestore + Cache locale + Pulizia automatica 1 mese)

    func startCalendarListener(uid: String) {
        calendarListener?.remove()

        // Carica subito dal backup locale in memoria (zero delay per la mamma)
        let local = loadCalendarFromLocalCache(uid: uid)
        if !local.isEmpty && calendarEvents.isEmpty {
            calendarEvents = local
            hasLoadedCalendarEvents = true
            purgeOldEvents(uid: uid)
        }

        calendarListener = db.collection("users").document(uid)
            .collection("calendar_events")
            .order(by: "startTime", descending: false)
            .addSnapshotListener { [weak self] snap, error in
                guard let self else { return }
                if let error = error {
                    print("Snapshot listener error calendario: \(error)")
                    return
                }
                guard let docs = snap?.documents else { return }

                Task { @MainActor in
                    self.hasLoadedCalendarEvents = true
                    let cal = Calendar.current
                    let cutoffDate = cal.date(byAdding: .month, value: -1, to: Date()) ?? Date().addingTimeInterval(-30 * 24 * 3600)
                    var validEvents: [CalendarEvent] = []
                    var expiredIds: [String] = []

                    for doc in docs {
                        let docId = doc.documentID
                        let d = doc.data()
                        guard let title = d["title"] as? String else { continue }

                        let date = self.parseDate(d["date"]) ?? Date()
                        let startTime = self.parseDate(d["startTime"]) ?? date
                        let reminderTime = self.parseDate(d["reminderTime"])

                        // Se l'evento è più vecchio di 1 mese, marcalo per l'eliminazione automatica
                        if date < cutoffDate {
                            expiredIds.append(docId)
                            continue
                        }

                        let event = CalendarEvent(
                            id: docId,
                            title: title,
                            date: date,
                            startTime: startTime,
                            isCompleted: d["isCompleted"] as? Bool ?? false,
                            reminderEnabled: d["reminderEnabled"] as? Bool ?? false,
                            reminderTime: reminderTime
                        )
                        validEvents.append(event)
                    }

                    if self.calendarEvents != validEvents {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                            self.calendarEvents = validEvents
                        }
                    }
                    self.saveCalendarToLocalCache(self.calendarEvents, uid: uid)
                    self.cleanOrphanNotifications()

                    // Elimina dal database Firestore i vecchi appuntamenti scaduti
                    if !expiredIds.isEmpty {
                        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: expiredIds)
                        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: expiredIds)
                        Task {
                            for oldId in expiredIds {
                                try? await self.db.collection("users").document(uid)
                                    .collection("calendar_events").document(oldId).delete()
                            }
                        }
                    }
                }
            }
    }

    func addEvent(title: String, date: Date, startTime: Date, reminderEnabled: Bool, reminderTime: Date? = nil) {
        guard let uid = currentUser?.uid else { return }
        let cleanTitle = title.trimmingCharacters(in: .whitespaces)
        guard !cleanTitle.isEmpty else { return }

        // Genera il documentID nativo di Firestore prima dell'inserimento: sincronizzazione perfetta
        let docRef = db.collection("users").document(uid).collection("calendar_events").document()
        let eventId = docRef.documentID
        let now = Date()

        let newEvent = CalendarEvent(
            id: eventId,
            title: cleanTitle,
            date: date,
            startTime: startTime,
            isCompleted: false,
            reminderEnabled: reminderEnabled,
            reminderTime: reminderTime
        )

        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
            calendarEvents.append(newEvent)
            calendarEvents.sort { $0.startTime < $1.startTime }
        }
        saveCalendarToLocalCache(calendarEvents, uid: uid)

        if reminderEnabled {
            scheduleNotification(for: newEvent)
        }

        Task {
            do {
                var data: [String: Any] = [
                    "id": eventId,
                    "title": cleanTitle,
                    "date": Timestamp(date: date),
                    "startTime": Timestamp(date: startTime),
                    "isCompleted": false,
                    "reminderEnabled": reminderEnabled,
                    "createdAt": Timestamp(date: now),
                    "serverCreatedAt": FieldValue.serverTimestamp()
                ]
                if let rt = reminderTime {
                    data["reminderTime"] = Timestamp(date: rt)
                }

                try await docRef.setData(data)
            } catch {
                print("Errore salvataggio evento su Firestore: \(error)")
            }
        }
    }

    func updateEvent(_ event: CalendarEvent) {
        guard let uid = currentUser?.uid else { return }

        if let idx = calendarEvents.firstIndex(where: { $0.id == event.id }) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                calendarEvents[idx] = event
                calendarEvents.sort { $0.startTime < $1.startTime }
            }
            saveCalendarToLocalCache(calendarEvents, uid: uid)
        }

        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [event.id])
        if event.reminderEnabled {
            scheduleNotification(for: event)
        }

        Task {
            do {
                var data: [String: Any] = [
                    "id": event.id,
                    "title": event.title,
                    "date": Timestamp(date: event.date),
                    "startTime": Timestamp(date: event.startTime),
                    "isCompleted": event.isCompleted,
                    "reminderEnabled": event.reminderEnabled,
                    "updatedAt": FieldValue.serverTimestamp()
                ]
                if let rt = event.reminderTime {
                    data["reminderTime"] = Timestamp(date: rt)
                } else {
                    data["reminderTime"] = FieldValue.delete()
                }

                try await db.collection("users").document(uid)
                    .collection("calendar_events").document(event.id)
                    .setData(data, merge: true)
            } catch {
                print("Errore aggiornamento evento su Firestore: \(error)")
            }
        }
    }

    func deleteEvent(_ event: CalendarEvent) {
        guard let uid = currentUser?.uid else { return }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            calendarEvents.removeAll { $0.id == event.id }
        }
        saveCalendarToLocalCache(calendarEvents, uid: uid)

        // Rimuove immediatamente sia le notifiche in attesa sia quelle già consegnate
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [event.id])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [event.id])
        cleanOrphanNotifications()

        Task {
            do {
                try await db.collection("users").document(uid)
                    .collection("calendar_events").document(event.id).delete()
            } catch {
                print("Errore cancellazione evento su Firestore: \(error)")
            }
        }
    }

    func toggleCompleteEvent(_ event: CalendarEvent) {
        guard let uid = currentUser?.uid else { return }

        if let idx = calendarEvents.firstIndex(where: { $0.id == event.id }) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                calendarEvents[idx].isCompleted.toggle()
            }
            saveCalendarToLocalCache(calendarEvents, uid: uid)
        }

        let newStatus = !event.isCompleted

        // Se l'evento è stato completato, cancella la notifica per evitare che suoni inutilmente
        if newStatus {
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [event.id])
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [event.id])
        } else if event.reminderEnabled {
            scheduleNotification(for: event)
        }

        Task {
            do {
                try await db.collection("users").document(uid)
                    .collection("calendar_events").document(event.id)
                    .setData([
                        "isCompleted": newStatus,
                        "updatedAt": FieldValue.serverTimestamp()
                    ], merge: true)
            } catch {
                print("Errore toggle complete evento: \(error)")
            }
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
