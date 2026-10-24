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
                VStack(spacing: 20) {
                    Image("AppLogo")
                        .resizable().scaledToFill()
                        .frame(width: 130, height: 130)
                        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                    Text("Simply")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.white)
                }
                Spacer(); Spacer()
                VStack(spacing: 12) {
                    NavigationLink(destination: RegisterView()) {
                        AuthPill(label: "Registrati con username", style: .primary)
                    }.contentShape(Capsule())
                    NavigationLink(destination: LoginView()) {
                        AuthPill(label: "Accedi", style: .outlined)
                    }.contentShape(Capsule())
                    Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1).padding(.vertical, 4)
                    Button {} label: {
                        HStack(spacing: 10) {
                            Image(systemName: "apple.logo").font(.system(size: 17, weight: .medium)).offset(y: -1)
                            Text("Continua con Apple").font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundStyle(.white).frame(maxWidth: .infinity).frame(height: 54)
                        .background(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1))
                    }.contentShape(Capsule())
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
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left").font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white).frame(width: 38, height: 38).glassEffect(.regular, in: Circle())
                    }.buttonStyle(.plain).contentShape(Circle())
                    Spacer()
                }.padding(.bottom, 32)
                VStack(spacing: 14) {
                    Image("AppLogo").resizable().scaledToFill().frame(width: 52, height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    Text("Crea Account").font(.title.bold()).foregroundStyle(.white)
                    Text("Benvenuto in Simply").font(.subheadline).foregroundStyle(.white.opacity(0.45))
                }.padding(.bottom, 40)
                VStack(spacing: 12) {
                    AuthField(icon: "person", placeholder: "Nome utente", text: $username)
                    AuthSecureField(placeholder: "Password", text: $password, show: $showPassword)
                    AuthSecureField(placeholder: "Conferma Password", text: $confirmPassword, show: $showConfirm)
                }.padding(.bottom, 16)
                if let msg = auth.errorMessage {
                    Text(msg).font(.footnote).foregroundStyle(.red.opacity(0.9))
                        .multilineTextAlignment(.center).padding(.bottom, 12)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
                Button {
                    Task { await auth.register(username: username, password: password, confirmPassword: confirmPassword) }
                } label: {
                    if auth.isLoading { AuthPill(label: "", style: .primary, isLoading: true) }
                    else { AuthPill(label: "Crea Account", style: .primary) }
                }.contentShape(Capsule()).disabled(auth.isLoading)
                Spacer()
            }
            .padding(.horizontal, 28).padding(.top, 20)
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
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left").font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white).frame(width: 38, height: 38).glassEffect(.regular, in: Circle())
                    }.buttonStyle(.plain).contentShape(Circle())
                    Spacer()
                }.padding(.bottom, 32)
                VStack(spacing: 14) {
                    Image("AppLogo").resizable().scaledToFill().frame(width: 52, height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    Text("Bentornato").font(.title.bold()).foregroundStyle(.white)
                    Text("Accedi al tuo account Simply").font(.subheadline).foregroundStyle(.white.opacity(0.45))
                }.padding(.bottom, 40)
                VStack(spacing: 12) {
                    AuthField(icon: "person", placeholder: "Nome utente", text: $username)
                    AuthSecureField(placeholder: "Password", text: $password, show: $showPassword)
                }.padding(.bottom, 16)
                if let msg = auth.errorMessage {
                    Text(msg).font(.footnote).foregroundStyle(.red.opacity(0.9))
                        .multilineTextAlignment(.center).padding(.bottom, 12)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
                Button {
                    Task { await auth.login(username: username, password: password) }
                } label: {
                    if auth.isLoading { AuthPill(label: "", style: .primary, isLoading: true) }
                    else { AuthPill(label: "Accedi", style: .primary) }
                }.contentShape(Capsule()).disabled(auth.isLoading)
                Spacer()
            }
            .padding(.horizontal, 28).padding(.top, 20)
        }
        .navigationBarBackButtonHidden(true)
        .toolbarVisibility(.hidden, for: .navigationBar)
        .animation(.easeInOut(duration: 0.2), value: auth.errorMessage)
    }
}

// MARK: - Main App

struct MainAppView: View {
    var body: some View {
        TabView {
            Tab("Spesa", systemImage: "cart") {
                ShoppingListView()
            }
            Tab("Calendario", systemImage: "calendar") {
                CalendarView()
            }
            Tab("Impostazioni", systemImage: "gearshape") {
                ProfileView()
            }
        }
        .tint(.blue)
    }
}

// MARK: - Shopping List (Spesa)

struct ShoppingListView: View {
    @State private var auth = AuthManager.shared
    @State private var showingShare = false
    @State private var showingFriendsLists = false
    @State private var quickItemName = ""
    @State private var selectedQty: String = "ND"
    @FocusState private var isNameFocused: Bool
    @State private var showingClearAllAlert = false
    @State private var showingClearCheckedAlert = false

    let quantityPresets = ["ND", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12"]

    var isQuickAddValid: Bool {
        !quickItemName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var activeItems: [ShoppingItem] {
        auth.myItems.filter { !$0.completed }
    }

    var completedItems: [ShoppingItem] {
        auth.myItems
            .filter { $0.completed }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()

                List {
                    // Stat cards
                    Section {
                        HStack(spacing: 15) {
                            statCard(title: "Da comprare", value: "\(activeItems.count)", icon: "cart.fill", color: .orange)
                            statCard(title: "Completati", value: "\(completedItems.count)", icon: "checkmark.seal.fill", color: .green)
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .padding(.vertical, 10)
                    }
                    .padding(.horizontal)

                    // Widget Aggiunta Rapida
                    Section {
                        HStack(spacing: 12) {
                            // Sinistra: Campo Nome + Bottoni Quantità
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    Image(systemName: "cart.fill.badge.plus")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .frame(width: 20)

                                    TextField("Nome prodotto...", text: $quickItemName)
                                        .focused($isNameFocused)
                                        .submitLabel(.done)
                                        .onSubmit {
                                            addQuickItem()
                                        }
                                        .foregroundStyle(.primary)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(Color(uiColor: .secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                                // Selettori Quantità Rapidi
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(quantityPresets, id: \.self) { preset in
                                            Button {
                                                selectedQty = preset
                                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            } label: {
                                                Text(preset)
                                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                                    .frame(width: 44, height: 44)
                                                    .background(
                                                        selectedQty == preset ?
                                                        Color.blue :
                                                        Color(uiColor: .secondarySystemGroupedBackground)
                                                    )
                                                    .foregroundColor(selectedQty == preset ? .white : .primary)
                                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(selectedQty == preset ? Color.blue.opacity(0.8) : Color.white.opacity(0.12), lineWidth: 1)
                                                    )
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }

                            // Destra: Mega Tasto +
                            Button {
                                addQuickItem()
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(isQuickAddValid ? Color.blue : Color.gray.opacity(0.25))

                                    Image(systemName: "plus")
                                        .font(.system(size: 26, weight: .bold))
                                        .foregroundColor(isQuickAddValid ? .white : .secondary)
                                }
                                .frame(width: 58)
                            }
                            .disabled(!isQuickAddValid)
                            .buttonStyle(.plain)
                        }
                        .padding(12)
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 12, trailing: 20))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }

                    // Lista Elementi
                    if auth.myItems.isEmpty {
                        Section {
                            VStack(spacing: 20) {
                                Image(systemName: "cart.badge.plus")
                                    .font(.system(size: 60))
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 40)
                                Text("La tua lista è vuota")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    } else {
                        // Prodotti da comprare
                        if !activeItems.isEmpty {
                            Section {
                                ForEach(activeItems) { item in
                                    ShoppingItemCard(item: item) {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                            auth.toggleMyItem(item)
                                        }
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    }
                                    .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            withAnimation {
                                                auth.deleteMyItem(item)
                                            }
                                        } label: {
                                            Label("Elimina", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }

                        // Prodotti presi
                        if !completedItems.isEmpty {
                            Section {
                                HStack {
                                    Text("PRODOTTI PRESI")
                                        .font(.caption.bold())
                                        .foregroundStyle(.secondary)
                                        .padding(.leading, 20)
                                    Spacer()
                                    Rectangle()
                                        .frame(height: 1)
                                        .foregroundStyle(.secondary.opacity(0.2))
                                }
                                .padding(.top, 20)
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)

                                ForEach(completedItems) { item in
                                    ShoppingItemCard(item: item) {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                            auth.toggleMyItem(item)
                                        }
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    }
                                    .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .opacity(0.6)
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            withAnimation {
                                                auth.deleteMyItem(item)
                                            }
                                        } label: {
                                            Label("Elimina", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Section {
                        Spacer(minLength: 120)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Spesa")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 15) {
                        Button(role: .destructive) {
                            showingClearAllAlert = true
                        } label: {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.red)
                        }

                        Button {
                            showingClearCheckedAlert = true
                        } label: {
                            Image(systemName: "checkmark.circle.badge.xmark.fill")
                                .foregroundColor(.orange)
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 15) {
                        Button {
                            showingFriendsLists.toggle()
                        } label: {
                            Image(systemName: "folder.badge.person.crop")
                                .foregroundColor(.blue)
                        }

                        Button {
                            showingShare.toggle()
                        } label: {
                            Image(systemName: "person.badge.plus")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .alert("Elimina tutto?", isPresented: $showingClearAllAlert) {
                Button("Annulla", role: .cancel) {}
                Button("Elimina Tutto", role: .destructive) {
                    auth.clearAllMyItems()
                }
            } message: {
                Text("Sei sicuro/a di voler eliminare tutti i prodotti dalla lista?")
            }
            .alert("Elimina completati?", isPresented: $showingClearCheckedAlert) {
                Button("Annulla", role: .cancel) {}
                Button("Elimina Completati", role: .destructive) {
                    auth.clearCompletedMyItems()
                }
            } message: {
                Text("Sei sicuro/a di voler eliminare solo i prodotti già completati?")
            }
            .sheet(isPresented: $showingShare) {
                ShareView(isPresented: $showingShare)
            }
            .sheet(isPresented: $showingFriendsLists) {
                FriendsListView(isPresented: $showingFriendsLists)
            }
        }
    }

    private func addQuickItem() {
        let name = quickItemName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let qty = (selectedQty == "ND") ? "" : selectedQty

        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            auth.addMyItem(name: name, quantity: qty)
            quickItemName = ""
            isNameFocused = true
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Shopping Item Card

struct ShoppingItemCard: View {
    let item: ShoppingItem
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 15) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .strikethrough(false)
                    .foregroundStyle(item.completed ? .secondary : .primary)

                if !item.quantity.isEmpty {
                    Text(item.quantity)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button {
                onToggle()
            } label: {
                Image(systemName: item.completed ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(item.completed ? .green : .secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

// MARK: - Share & Add Friend View

struct ShareView: View {
    @Binding var isPresented: Bool
    @State private var auth = AuthManager.shared
    @State private var friendCode = ""
    @State private var friendName = ""
    @State private var showCopied = false

    var displayCode: String {
        auth.friendCode
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 16) {
                        Text(displayCode.isEmpty ? "Caricamento..." : displayCode)
                            .font(.system(size: 26, weight: .bold, design: .monospaced))
                            .tracking(4)
                            .foregroundColor(.primary)
                            .padding(.top, 8)

                        Button {
                            UIPasteboard.general.string = displayCode
                            withAnimation { showCopied = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation { showCopied = false }
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            Label(
                                showCopied ? "Copiato!" : "Copia Codice",
                                systemImage: showCopied ? "checkmark.circle.fill" : "doc.on.doc"
                            )
                            .font(.subheadline.bold())
                            .foregroundColor(showCopied ? .green : .blue)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(showCopied ? Color.green.opacity(0.12) : Color.blue.opacity(0.12)))
                        }

                        Text("Condividi il tuo codice con amici o parenti per collegare le liste.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

                Section("Aggiungi Amico") {
                    TextField("Codice Amico (6 cifre)", text: $friendCode)
                        .keyboardType(.numberPad)
                    TextField("Nome o Soprannome", text: $friendName)

                    if let error = auth.errorMessage {
                        Text(error).font(.caption).foregroundColor(.red)
                    }

                    Button("Aggiungi Amico") {
                        Task {
                            await auth.addFriend(code: friendCode, nickname: friendName)
                            if auth.errorMessage == nil {
                                friendCode = ""
                                friendName = ""
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                                isPresented = false
                            }
                        }
                    }
                    .disabled(friendCode.count != 6 || friendName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .navigationTitle("Condivisione")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Chiudi") { isPresented = false }
                }
            }
        }
    }
}

// MARK: - Friends List Sheet

struct FriendsListView: View {
    @Binding var isPresented: Bool
    @State private var auth = AuthManager.shared

    var body: some View {
        NavigationStack {
            List {
                if auth.friends.isEmpty {
                    Section {
                        Text("Non hai ancora aggiunto amici.")
                            .foregroundStyle(.secondary)
                    }
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(auth.friends) { friend in
                        NavigationLink {
                            FriendDetailView(friend: friend)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "person.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.title2)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(friend.nickname)
                                        .font(.headline)
                                    Text("#\(friend.friendCode)")
                                        .font(.caption.monospaced())
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                auth.removeFriend(friend.id)
                            } label: {
                                Label("Elimina", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Liste Amici")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Chiudi") { isPresented = false }
                }
            }
        }
    }
}

// MARK: - Friend Detail View

struct FriendDetailView: View {
    let friend: Friend
    @State private var auth = AuthManager.shared

    var friendItems: [ShoppingItem] {
        auth.friendsItems[friend.id] ?? []
    }

    var activeItems: [ShoppingItem] {
        friendItems.filter { !$0.completed }
    }

    var completedItems: [ShoppingItem] {
        friendItems.filter { $0.completed }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground).ignoresSafeArea()

            List {
                if friendItems.isEmpty {
                    Section {
                        VStack(spacing: 16) {
                            Image(systemName: "cart.badge.plus")
                                .font(.system(size: 50))
                                .foregroundStyle(.secondary)
                                .padding(.top, 40)
                            Text("La lista di \(friend.nickname) è vuota")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    if !activeItems.isEmpty {
                        Section {
                            ForEach(activeItems) { item in
                                ShoppingItemCard(item: item) {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        auth.toggleFriendItem(item, friendUid: friend.id)
                                    }
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }
                                .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            }
                        }
                    }

                    if !completedItems.isEmpty {
                        Section {
                            HStack {
                                Text("PRODOTTI PRESI")
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                                    .padding(.leading, 20)
                                Spacer()
                                Rectangle()
                                    .frame(height: 1)
                                    .foregroundStyle(.secondary.opacity(0.2))
                            }
                            .padding(.top, 16)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)

                            ForEach(completedItems) { item in
                                ShoppingItemCard(item: item) {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        auth.toggleFriendItem(item, friendUid: friend.id)
                                    }
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }
                                .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .opacity(0.6)
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(friend.nickname)
    }
}

// MARK: - Calendar (placeholder)

struct CalendarView: View {
    private let bg = Color(red: 28/255, green: 28/255, blue: 30/255)
    var body: some View {
        ZStack { bg.ignoresSafeArea(); Text("Calendario").foregroundStyle(.white) }
    }
}

// MARK: - Impostazioni / Profile

struct ProfileView: View {
    @State private var auth = AuthManager.shared
    @State private var showingShare = false
    private let bg = Color(red: 28/255, green: 28/255, blue: 30/255)

    var body: some View {
        NavigationStack {
            ZStack {
                bg.ignoresSafeArea()
                VStack(spacing: 24) {
                    Spacer()

                    // Logo
                    Image("AppLogo").resizable().scaledToFill()
                        .frame(width: 72, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                    // Username + codice
                    VStack(spacing: 6) {
                        Text(auth.username.isEmpty ? "" : "@\(auth.username)")
                            .font(.title2.bold()).foregroundStyle(.white)
                        if !auth.friendCode.isEmpty {
                            HStack(spacing: 6) {
                                Text("#\(auth.friendCode)")
                                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                                    .foregroundStyle(.white.opacity(0.5))
                                Button {
                                    UIPasteboard.general.string = auth.friendCode
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.white.opacity(0.4))
                                }.buttonStyle(.plain)
                            }
                        }
                    }

                    Spacer()

                    // Bottoni
                    VStack(spacing: 12) {
                        Button {
                            showingShare = true
                        } label: {
                            AuthPill(label: "Amici", style: .outlined)
                        }
                        .contentShape(Capsule())

                        NavigationLink(destination: IconPickerView()) {
                            AuthPill(label: "Icona", style: .outlined)
                        }.contentShape(Capsule()).buttonStyle(.plain)

                        Button { auth.logout() } label: {
                            AuthPill(label: "Esci", style: .outlined)
                        }.contentShape(Capsule())
                    }
                    .padding(.horizontal, 28)

                    Spacer().frame(height: 20)
                }
            }
            .navigationTitle("Impostazioni")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingShare) {
                ShareView(isPresented: $showingShare)
            }
        }
    }
}

// MARK: - Icon Picker

struct AppIconOption: Identifiable {
    let id: String
    let assetName: String?
    let label: String
}

struct IconPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentIcon: String? = UIApplication.shared.alternateIconName
    private let bg = Color(red: 28/255, green: 28/255, blue: 30/255)
    private let icons: [AppIconOption] = [
        AppIconOption(id: "default",       assetName: nil,              label: "Originale"),
        AppIconOption(id: "AppIconPurple", assetName: "AppIconPurple",  label: "Viola"),
        AppIconOption(id: "AppIconWhite",  assetName: "AppIconWhite",   label: "Bianca"),
        AppIconOption(id: "AppIconGray",   assetName: "AppIconGray",    label: "Grigia"),
    ]
    private var selectedId: String { currentIcon ?? "default" }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left").font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white).frame(width: 38, height: 38).glassEffect(.regular, in: Circle())
                    }.buttonStyle(.plain).contentShape(Circle())
                    Spacer()
                }.padding(.bottom, 32)
                VStack(spacing: 6) {
                    Text("Icona App").font(.title.bold()).foregroundStyle(.white)
                    Text("Scegli lo stile che preferisci").font(.subheadline).foregroundStyle(.white.opacity(0.45))
                }.padding(.bottom, 40)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    ForEach(icons) { option in
                        IconOptionCell(option: option, isSelected: selectedId == option.id) { applyIcon(option) }
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 28).padding(.top, 20)
        }
        .navigationBarBackButtonHidden(true)
        .toolbarVisibility(.hidden, for: .navigationBar)
    }

    private func applyIcon(_ option: AppIconOption) {
        let name: String? = option.id == "default" ? nil : option.id
        guard UIApplication.shared.supportsAlternateIcons else { return }
        UIApplication.shared.setAlternateIconName(name) { err in
            if err == nil { currentIcon = name }
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
                Group {
                    if let asset = option.assetName, let uiImg = UIImage(named: asset) {
                        Image(uiImage: uiImg).resizable().scaledToFill()
                    } else {
                        Image("AppLogo").resizable().scaledToFill()
                    }
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2.5))
                .shadow(color: .black.opacity(0.3), radius: 8, y: 4)

                Text(option.label)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.55))
            }
            .frame(maxWidth: .infinity).padding(.vertical, 16)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .buttonStyle(.plain)
    }
}

// MARK: - AuthPill

enum AuthPillStyle { case primary, outlined }

struct AuthPill: View {
    let label: String
    let style: AuthPillStyle
    var isLoading: Bool = false

    var body: some View {
        Group {
            if isLoading { ProgressView().tint(style == .primary ? .black : .white) }
            else { Text(label).font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(style == .primary ? .black : .white) }
        }
        .frame(maxWidth: .infinity).frame(height: 54)
        .background {
            switch style {
            case .primary: Capsule().fill(Color.white)
            case .outlined: Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1)
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
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon).foregroundStyle(.white.opacity(0.5)).frame(width: 18)
            TextField("", text: $text,
                prompt: Text(placeholder).foregroundStyle(.white.opacity(0.35)))
                .foregroundStyle(.white).autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .keyboardType(keyboardType)
        }
        .padding(.horizontal, 18).frame(height: 54)
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
            Image(systemName: "lock").foregroundStyle(.white.opacity(0.5)).frame(width: 18)
            Group {
                if show {
                    TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(.white.opacity(0.35)))
                } else {
                    SecureField("", text: $text, prompt: Text(placeholder).foregroundStyle(.white.opacity(0.35)))
                }
            }
            .foregroundStyle(.white).autocorrectionDisabled().textInputAutocapitalization(.never)
            Button { show.toggle() } label: {
                Image(systemName: show ? "eye.slash" : "eye").foregroundStyle(.white.opacity(0.45))
                    .contentTransition(.symbolEffect(.replace))
            }.buttonStyle(.plain)
        }
        .padding(.horizontal, 18).frame(height: 54)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview { ContentView() }
