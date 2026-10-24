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
                    }
                    .buttonStyle(.plain)
                    .contentShape(Capsule())

                    NavigationLink(destination: LoginView()) {
                        AuthPill(label: "Accedi", style: .outlined)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Capsule())

                    Rectangle().fill(Color.white.opacity(0.1)).frame(height: 1).padding(.vertical, 4)

                    Button {} label: {
                        ZStack {
                            Capsule()
                                .fill(Color.white.opacity(0.001))
                                .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1))

                            HStack(spacing: 10) {
                                Image(systemName: "apple.logo")
                                    .font(.system(size: 17, weight: .medium))
                                    .offset(y: -1)
                                Text("Continua con Apple")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
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
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left").font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white).frame(width: 38, height: 38).glassEffect(.regular, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .contentShape(Circle())
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
                }
                .buttonStyle(.plain)
                .contentShape(Capsule())
                .disabled(auth.isLoading)
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
                    }
                    .buttonStyle(.plain)
                    .contentShape(Circle())
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
                }
                .buttonStyle(.plain)
                .contentShape(Capsule())
                .disabled(auth.isLoading)
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
            Tab("Profilo", systemImage: "person.circle") {
                ProfileView()
            }
        }
        .tint(.blue)
    }
}

// MARK: - Shopping List (Spesa)

struct ShoppingListView: View {
    @State private var auth = AuthManager.shared
    @State private var quickItemName = ""
    @State private var selectedQty: String = "ND"
    @FocusState private var isNameFocused: Bool

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
                    // Barra amici: appare solo se hai amici aggiunti
                    if !auth.friends.isEmpty {
                        Section {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("LISTA AMICI")
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)
                                    .padding(.leading, 4)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(auth.friends) { friend in
                                            NavigationLink(destination: FriendDetailView(friend: friend)) {
                                                HStack(spacing: 10) {
                                                    ZStack {
                                                        Circle()
                                                            .fill(Color.blue.opacity(0.15))
                                                            .frame(width: 34, height: 34)
                                                        Image(systemName: "person.2.fill")
                                                            .font(.system(size: 15))
                                                            .foregroundColor(.blue)
                                                    }

                                                    VStack(alignment: .leading, spacing: 2) {
                                                        Text(friend.nickname)
                                                            .font(.system(size: 15, weight: .semibold))
                                                            .foregroundStyle(.primary)
                                                        Text("Vedi spesa")
                                                            .font(.caption2)
                                                            .foregroundStyle(.secondary)
                                                    }

                                                    Image(systemName: "chevron.right")
                                                        .font(.system(size: 12, weight: .semibold))
                                                        .foregroundStyle(.secondary)
                                                        .padding(.leading, 2)
                                                }
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 10)
                                                .background(.ultraThinMaterial)
                                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                                )
                                                .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                    }

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
                                                ZStack {
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(
                                                            selectedQty == preset ?
                                                            Color.blue :
                                                            Color(uiColor: .secondarySystemGroupedBackground)
                                                        )

                                                    Text(preset)
                                                        .font(.system(size: 15, weight: .bold, design: .rounded))
                                                        .foregroundColor(selectedQty == preset ? .white : .primary)
                                                }
                                                .frame(width: 44, height: 44)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(selectedQty == preset ? Color.blue.opacity(0.8) : Color.white.opacity(0.12), lineWidth: 1)
                                                )
                                                .contentShape(RoundedRectangle(cornerRadius: 12))
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
                                .frame(maxHeight: .infinity)
                                .contentShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .disabled(!isQuickAddValid)
                            .buttonStyle(.plain)
                        }
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
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
                                        auth.toggleMyItem(item)
                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    }
                                    .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            auth.deleteMyItem(item)
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
                                        auth.toggleMyItem(item)
                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                    }
                                    .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .opacity(0.6)
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            auth.deleteMyItem(item)
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
                .animation(.spring(response: 0.45, dampingFraction: 0.75), value: activeItems)
                .animation(.spring(response: 0.45, dampingFraction: 0.75), value: completedItems)
            }
            .navigationTitle("Spesa")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func addQuickItem() {
        let name = quickItemName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let qty = (selectedQty == "ND") ? "" : selectedQty

        auth.addMyItem(name: name, quantity: qty)
        quickItemName = ""
        isNameFocused = true
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
}

// MARK: - Shopping Item Card

struct ShoppingItemCard: View {
    let item: ShoppingItem
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
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

                Image(systemName: item.completed ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(item.completed ? .green : .secondary)
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
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
                                    auth.toggleFriendItem(item, friendUid: friend.id)
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
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
                                    auth.toggleFriendItem(item, friendUid: friend.id)
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
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
            .animation(.spring(response: 0.45, dampingFraction: 0.75), value: activeItems)
            .animation(.spring(response: 0.45, dampingFraction: 0.75), value: completedItems)
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

// MARK: - Profile

struct ProfileView: View {
    @State private var auth = AuthManager.shared
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
                                }
                                .buttonStyle(.plain)
                                .contentShape(Rectangle())
                            }
                        }
                    }

                    Spacer()

                    // Bottoni
                    VStack(spacing: 12) {
                        NavigationLink(destination: FriendsView()) {
                            AuthPill(label: "Amici", style: .outlined)
                        }
                        .buttonStyle(.plain)
                        .contentShape(Capsule())

                        NavigationLink(destination: IconPickerView()) {
                            AuthPill(label: "Icona", style: .outlined)
                        }
                        .buttonStyle(.plain)
                        .contentShape(Capsule())

                        Button { auth.logout() } label: {
                            AuthPill(label: "Esci", style: .outlined)
                        }
                        .buttonStyle(.plain)
                        .contentShape(Capsule())
                    }
                    .padding(.horizontal, 28)

                    Spacer().frame(height: 20)
                }
            }
            .toolbarVisibility(.hidden, for: .navigationBar)
        }
    }
}

// MARK: - Friends View

struct FriendsView: View {
    @State private var auth = AuthManager.shared
    @State private var codeInput = ""
    @State private var nicknameInput = ""
    @State private var showAdd = false
    @FocusState private var codeFocused: Bool
    @Environment(\.dismiss) private var dismiss
    private let bg = Color(red: 28/255, green: 28/255, blue: 30/255)

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            VStack(spacing: 0) {

                // Header
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left").font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white).frame(width: 38, height: 38).glassEffect(.regular, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .contentShape(Circle())
                    Spacer()
                    Button {
                        withAnimation(.spring(response: 0.35)) { showAdd.toggle() }
                        if showAdd { codeFocused = true }
                    } label: {
                        Image(systemName: showAdd ? "xmark" : "person.badge.plus")
                            .font(.system(size: 16, weight: .semibold)).foregroundStyle(.white)
                            .frame(width: 38, height: 38).glassEffect(.regular, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .contentShape(Circle())
                }.padding(.horizontal, 24).padding(.top, 20).padding(.bottom, 28)

                Text("Amici").font(.title.bold()).foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 24).padding(.bottom, 20)

                // Form aggiungi amico
                if showAdd {
                    VStack(spacing: 10) {
                        AuthField(icon: "number", placeholder: "Codice a 6 cifre", text: $codeInput)
                            .keyboardType(.numberPad)
                        AuthField(icon: "person", placeholder: "Come vuoi chiamarlo?", text: $nicknameInput)

                        if let msg = auth.errorMessage {
                            Text(msg).font(.footnote).foregroundStyle(.red.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .transition(.opacity)
                        }

                        Button {
                            Task {
                                await auth.addFriend(code: codeInput, nickname: nicknameInput)
                                if auth.errorMessage == nil {
                                    codeInput = ""; nicknameInput = ""
                                    withAnimation { showAdd = false }
                                }
                            }
                        } label: {
                            if auth.isLoading { AuthPill(label: "", style: .primary, isLoading: true) }
                            else { AuthPill(label: "Aggiungi", style: .primary) }
                        }
                        .buttonStyle(.plain)
                        .contentShape(Capsule())
                        .disabled(auth.isLoading)
                    }
                    .padding(.horizontal, 24).padding(.bottom, 20)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Lista amici
                if auth.friends.isEmpty && !showAdd {
                    Spacer()
                    VStack(spacing: 10) {
                        Image(systemName: "person.2").font(.system(size: 44, weight: .light))
                            .foregroundStyle(.white.opacity(0.2))
                        Text("Nessun amico aggiunto").font(.system(size: 16))
                            .foregroundStyle(.white.opacity(0.3))
                        Text("Tocca + per aggiungerne uno").font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.2))
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(auth.friends) { friend in
                                HStack(spacing: 16) {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(friend.nickname)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundStyle(.white)
                                        Text("#\(friend.friendCode)")
                                            .font(.system(size: 13, design: .monospaced))
                                            .foregroundStyle(.white.opacity(0.4))
                                    }
                                    Spacer()
                                    Button { auth.removeFriend(friend.id) } label: {
                                        Image(systemName: "person.badge.minus")
                                            .font(.system(size: 16))
                                            .frame(width: 44, height: 44)
                                            .foregroundStyle(.red.opacity(0.6))
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 18).frame(minHeight: 60)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                            }
                        }
                        .padding(.horizontal, 24).padding(.bottom, 24)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbarVisibility(.hidden, for: .navigationBar)
        .animation(.easeInOut(duration: 0.2), value: showAdd)
        .animation(.easeInOut(duration: 0.2), value: auth.errorMessage)
        .onAppear { auth.errorMessage = nil }
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
                    }
                    .buttonStyle(.plain)
                    .contentShape(Circle())
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
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
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
        ZStack {
            switch style {
            case .primary:
                Capsule().fill(Color.white)
            case .outlined:
                Capsule()
                    .fill(Color.white.opacity(0.001))
                    .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1))
            }

            if isLoading {
                ProgressView().tint(style == .primary ? .black : .white)
            } else {
                Text(label)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(style == .primary ? .black : .white)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 54)
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
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18).frame(height: 54)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview { ContentView() }
