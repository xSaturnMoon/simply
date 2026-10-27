import SwiftUI

// MARK: - Navigation Helpers (iOS 17 & 18+)

extension View {
    @ViewBuilder
    func hideNavigationBar() -> some View {
        if #available(iOS 18.0, *) {
            self.toolbarVisibility(.hidden, for: .navigationBar)
        } else {
            self.toolbar(.hidden, for: .navigationBar)
        }
    }
}

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
                        .hideNavigationBar()
                }
            }
        }
        .animation(.easeInOut(duration: 0.35), value: auth.currentUser == nil)
    }
}

// MARK: - Landing

struct LandingView: View {
    private let bg = Color.black

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
    private let bg = Color.black

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 38, height: 38)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
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
        .hideNavigationBar()
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
    private let bg = Color.black

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 38, height: 38)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
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
        .hideNavigationBar()
        .animation(.easeInOut(duration: 0.2), value: auth.errorMessage)
    }
}

// MARK: - Main App

struct MainAppView: View {
    @State private var selectedTab: Int = 0

    var body: some View {
        if #available(iOS 18.0, *) {
            TabView(selection: $selectedTab) {
                Tab("Spesa", systemImage: "cart", value: 0) {
                    ShoppingListView()
                }
                Tab("Calendario", systemImage: "calendar", value: 1) {
                    CalendarView()
                }
                Tab("Profilo", systemImage: "person.circle", value: 2) {
                    ProfileView()
                }
            }
            .tint(.blue)
            .onOpenURL { url in
                if url.scheme == "simply" && url.host == "calendar" {
                    selectedTab = 1
                }
            }
        } else {
            TabView(selection: $selectedTab) {
                ShoppingListView()
                    .tabItem { Label("Spesa", systemImage: "cart") }
                    .tag(0)
                CalendarView()
                    .tabItem { Label("Calendario", systemImage: "calendar") }
                    .tag(1)
                ProfileView()
                    .tabItem { Label("Profilo", systemImage: "person.circle") }
                    .tag(2)
            }
            .tint(.blue)
            .onOpenURL { url in
                if url.scheme == "simply" && url.host == "calendar" {
                    selectedTab = 1
                }
            }
        }
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
                    // Sezione Amici: appare solo se hai amici aggiunti
                    if !auth.friends.isEmpty {
                        Section {
                            VStack(spacing: 8) {
                                ForEach(auth.friends) { friend in
                                    NavigationLink(destination: FriendDetailView(friend: friend)) {
                                        HStack(spacing: 14) {
                                            ZStack {
                                                Circle()
                                                    .fill(Color.blue.opacity(0.15))
                                                    .frame(width: 38, height: 38)
                                                Image(systemName: "person.2.fill")
                                                    .font(.system(size: 15, weight: .semibold))
                                                    .foregroundColor(.blue)
                                            }

                                            Text(friend.nickname)
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundStyle(.primary)

                                            Spacer()

                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundStyle(.secondary.opacity(0.6))
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        .frame(maxWidth: .infinity)
                                        .background(.ultraThinMaterial)
                                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                                        )
                                        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 8, trailing: 20))
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
                                                        .stroke(selectedQty == preset ? Color.blue.opacity(0.8) : Color.primary.opacity(0.1), lineWidth: 1)
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
                                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
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
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
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
        .onAppear {
            auth.startFriendItemsListener(friendUid: friend.id)
        }
    }
}

// MARK: - Calendar Views (Bloom Style)

struct CalendarView: View {
    @State private var auth = AuthManager.shared
    @State private var selectedEvent: CalendarEvent?
    @State private var currentMonth = Date()
    @State private var selectedDate = Date()
    @State private var showingAddEvent = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()

                List {
                    // SEZIONE 1: Mese con Frecce e Griglia Calendario
                    Section {
                        VStack(spacing: 12) {
                            // Mese e Frecce racchiusi in un rettangolo con angoli smussati
                            HStack {
                                Button {
                                    changeMonth(by: -1)
                                } label: {
                                    Image(systemName: "chevron.left")
                                        .font(.subheadline.bold())
                                        .foregroundStyle(.primary)
                                        .frame(width: 38, height: 38)
                                        .background(Color.primary.opacity(0.06))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                                .contentShape(Rectangle())

                                Spacer()

                                Text(currentMonth.formatted(.dateTime.month(.wide).year().locale(Locale(identifier: "it_IT"))).capitalized)
                                    .font(.title3.bold())
                                    .foregroundStyle(.primary)

                                Spacer()

                                Button {
                                    changeMonth(by: 1)
                                } label: {
                                    Image(systemName: "chevron.right")
                                        .font(.subheadline.bold())
                                        .foregroundStyle(.primary)
                                        .frame(width: 38, height: 38)
                                        .background(Color.primary.opacity(0.06))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                                .contentShape(Rectangle())
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                            )

                            CalendarMonthGrid(
                                currentMonth: currentMonth,
                                selectedDate: $selectedDate
                            )
                        }
                        .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 8, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }

                    // SEZIONE 2: Intestazione Agenda Giorno
                    Section {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(selectedDate.formatted(.dateTime.weekday(.wide).locale(Locale(identifier: "it_IT"))).uppercased())
                                    .font(.caption.bold())
                                    .foregroundStyle(.secondary)

                                HStack(spacing: 6) {
                                    Text(selectedDate.formatted(.dateTime.day().month(.wide).locale(Locale(identifier: "it_IT"))).capitalized)
                                        .font(.title3.bold())
                                        .foregroundStyle(.primary)

                                    if Calendar.current.isDateInToday(selectedDate) {
                                        Text("Oggi")
                                            .font(.caption2.bold())
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.blue.opacity(0.15))
                                            .foregroundColor(.blue)
                                            .clipShape(Capsule())
                                    }
                                }
                            }

                            Spacer()

                            Button {
                                showingAddEvent = true
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus")
                                    Text("Impegno")
                                }
                                .font(.subheadline.bold())
                                .foregroundColor(.blue)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.12))
                                .clipShape(Capsule())
                                .contentShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }

                    // SEZIONE 3: Lista Impegni o Empty State
                    let events = auth.events(for: selectedDate)
                    if events.isEmpty {
                        Section {
                            VStack(spacing: 12) {
                                Image(systemName: "calendar.badge.clock")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.secondary.opacity(0.7))
                                    .padding(.top, 20)

                                Text("Nessun impegno in programma")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                Button {
                                    showingAddEvent = true
                                } label: {
                                    Text("+ Aggiungi Impegno")
                                        .font(.subheadline.bold())
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.blue.opacity(0.12))
                                        .foregroundColor(.blue)
                                        .clipShape(Capsule())
                                        .contentShape(Capsule())
                                }
                                .buttonStyle(.plain)
                                .padding(.bottom, 20)
                            }
                            .frame(maxWidth: .infinity)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                            )
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                    } else {
                        Section {
                            ForEach(events) { event in
                                AppleEventCard(event: event) {
                                    selectedEvent = event
                                }
                                .listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        auth.deleteEvent(event)
                                    } label: {
                                        Label("Elimina", systemImage: "trash")
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
            .navigationTitle("Calendario")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingAddEvent) {
                AddEventView(isPresented: $showingAddEvent, initialDate: selectedDate)
            }
            .sheet(item: $selectedEvent) { event in
                EditEventView(event: event)
            }
            .onAppear {
                if let uid = auth.currentUser?.uid {
                    auth.purgeOldEvents(uid: uid)
                }
            }
        }
    }

    func changeMonth(by value: Int) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        if let newMonth = Calendar.current.date(byAdding: .month, value: value, to: currentMonth) {
            withAnimation(.easeInOut(duration: 0.22)) {
                currentMonth = newMonth
                let cal = Calendar.current
                if !cal.isDate(selectedDate, equalTo: newMonth, toGranularity: .month) {
                    if let firstDay = cal.date(from: cal.dateComponents([.year, .month], from: newMonth)) {
                        selectedDate = firstDay
                    }
                }
            }
        }
    }
}

// MARK: - CalendarMonthGrid

struct CalendarDaySlot: Identifiable {
    let id: String
    let date: Date?
}

struct CalendarMonthGrid: View {
    let currentMonth: Date
    @Binding var selectedDate: Date
    @State private var auth = AuthManager.shared

    let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    let weekdays = ["L", "M", "M", "G", "V", "S", "D"]

    var body: some View {
        VStack(spacing: 10) {
            // Intestazione Giorni della Settimana
            HStack {
                ForEach(0..<7, id: \.self) { idx in
                    Text(weekdays[idx])
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 4)

            // Griglia Giorni Mese
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(daysInMonthGrid(for: currentMonth)) { slot in
                    if let date = slot.date {
                        let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                        let isToday = Calendar.current.isDateInToday(date)
                        let hasEvents = auth.hasEvents(on: date)

                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                selectedDate = date
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        } label: {
                            VStack(spacing: 3) {
                                Text("\(Calendar.current.component(.day, from: date))")
                                    .font(.system(size: 16, weight: isSelected || isToday ? .bold : .medium, design: .rounded))
                                    .foregroundColor(isSelected ? .white : (isToday ? .blue : .primary))

                                // Pallino indicatore impegni
                                Circle()
                                    .fill(hasEvents ? (isSelected ? .white : Color.orange) : Color.clear)
                                    .frame(width: 5, height: 5)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .background(
                                isSelected ?
                                Color.blue :
                                (isToday ? Color.blue.opacity(0.12) : Color.clear)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .contentShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    } else {
                        Color.clear
                            .frame(height: 42)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(14)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    private func daysInMonthGrid(for date: Date) -> [CalendarDaySlot] {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2 // Lunedì
        cal.locale = Locale(identifier: "it_IT")

        guard let monthInterval = cal.dateInterval(of: .month, for: date) else { return [] }
        let firstOfMonth = monthInterval.start

        let weekdayOfFirst = cal.component(.weekday, from: firstOfMonth)
        let leadingSpaces = (weekdayOfFirst - cal.firstWeekday + 7) % 7

        var slots: [CalendarDaySlot] = []
        for i in 0..<leadingSpaces {
            slots.append(CalendarDaySlot(id: "empty_\(i)", date: nil))
        }

        guard let range = cal.range(of: .day, in: .month, for: date) else { return slots }
        let year = cal.component(.year, from: date)
        let month = cal.component(.month, from: date)
        for day in range {
            if let dayDate = cal.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                slots.append(CalendarDaySlot(id: "day_\(year)_\(month)_\(day)", date: dayDate))
            }
        }
        return slots
    }
}

// MARK: - AppleEventCard

struct AppleEventCard: View {
    let event: CalendarEvent
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Orario
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.startTime.formatted(.dateTime.hour().minute()))
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                .frame(width: 55, alignment: .leading)

                // Barra colorata verticale
                Rectangle()
                    .fill(event.isCompleted ? Color.green : Color.blue)
                    .frame(width: 3.5, height: 38)
                    .clipShape(Capsule())

                // Titolo & Notifica
                VStack(alignment: .leading, spacing: 3) {
                    Text(event.title)
                        .font(.body.weight(.medium))
                        .foregroundColor(event.isCompleted ? .secondary : .primary)
                        .strikethrough(event.isCompleted)
                        .lineLimit(2)

                    if event.reminderEnabled {
                        HStack(spacing: 4) {
                            Image(systemName: "bell.fill")
                                .font(.caption2)
                                .foregroundColor(.orange)
                            Text("Promemoria")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                // Cerchietto completamento
                Button {
                    AuthManager.shared.toggleCompleteEvent(event)
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                } label: {
                    Image(systemName: event.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(event.isCompleted ? .green : .secondary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                AuthManager.shared.deleteEvent(event)
            } label: {
                Label("Elimina Impegno", systemImage: "trash")
            }
        }
    }
}

// MARK: - Time Picker Field

/// Mostra il selettore orario in base alla preferenza utente:
/// "Apple" → wheel nativo, "Manuale" → digitazione rapida con tastierino numerico (Ore : Minuti)
struct TimePickerField: View {
    let label: String
    @Binding var time: Date
    var isNewEvent: Bool = false
    @AppStorage("timePickerMode") private var timePickerMode: String = "Apple"

    var body: some View {
        if timePickerMode == "Manuale" {
            ManualTimeInputField(label: label, time: $time, isNewEvent: isNewEvent)
        } else {
            DatePicker(label, selection: $time, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)
        }
    }
}

/// Inserimento orario manuale scrivendo direttamente con la tastiera numerica:
/// Due caselle grandi e pulite [ ORE ] : [ MINUTI ].
struct ManualTimeInputField: View {
    let label: String
    @Binding var time: Date
    var isNewEvent: Bool = false

    @State private var hourText: String = ""
    @State private var minuteText: String = ""
    @State private var clearHourOnNextType = false
    @State private var clearMinuteOnNextType = false
    @FocusState private var focusedField: TimeField?

    enum TimeField: Hashable {
        case hour
        case minute
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Spacer()

                // ORE BOX
                VStack(spacing: 4) {
                    TextField("00", text: $hourText)
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .hour)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 36, weight: .semibold, design: .rounded))
                        .frame(width: 82, height: 60)
                        .background(Color(uiColor: .tertiarySystemFill))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(focusedField == .hour ? Color.blue : Color.clear, lineWidth: 2)
                        )
                        .onChange(of: focusedField) { _, newField in
                            if newField == .hour {
                                clearHourOnNextType = !hourText.isEmpty
                            } else if newField == .minute {
                                clearMinuteOnNextType = !minuteText.isEmpty
                            }
                        }
                        .onChange(of: hourText) { oldValue, newValue in
                            handleHourInput(old: oldValue, new: newValue)
                        }

                    Text("Ore")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }

                Text(":")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 20)

                // MINUTI BOX
                VStack(spacing: 4) {
                    TextField("00", text: $minuteText)
                        .keyboardType(.numberPad)
                        .focused($focusedField, equals: .minute)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 36, weight: .semibold, design: .rounded))
                        .frame(width: 82, height: 60)
                        .background(Color(uiColor: .tertiarySystemFill))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(focusedField == .minute ? Color.blue : Color.clear, lineWidth: 2)
                        )
                        .onChange(of: minuteText) { oldValue, newValue in
                            handleMinuteInput(old: oldValue, new: newValue)
                        }

                    Text("Minuti")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding(.vertical, 6)
        }
        .onAppear {
            let cal = Calendar.current
            let h = cal.component(.hour, from: time)
            let m = cal.component(.minute, from: time)
            hourText = String(format: "%02d", h)
            minuteText = String(format: "%02d", m)
        }
    }

    private func handleHourInput(old: String, new: String) {
        let digits = new.filter { $0.isNumber }

        var effective = digits
        if clearHourOnNextType && digits.count > old.filter({ $0.isNumber }).count {
            if let lastChar = digits.last {
                effective = String(lastChar)
            }
            clearHourOnNextType = false
        } else if clearHourOnNextType && digits.count < old.filter({ $0.isNumber }).count {
            clearHourOnNextType = false
        }

        if effective.count > 2 {
            effective = String(effective.prefix(2))
        }

        if hourText != effective {
            hourText = effective
        }

        if let h = Int(effective) {
            let validH = min(h, 23)
            updateTime(hour: validH, minute: Int(minuteText) ?? 0)

            // Auto-focus al campo minuti se l'utente ha inserito 2 cifre o un numero da 3 a 9
            if effective.count == 2 || (effective.count == 1 && h >= 3) {
                clearMinuteOnNextType = !minuteText.isEmpty
                focusedField = .minute
            }
        }
    }

    private func handleMinuteInput(old: String, new: String) {
        let digits = new.filter { $0.isNumber }

        var effective = digits
        if clearMinuteOnNextType && digits.count > old.filter({ $0.isNumber }).count {
            if let lastChar = digits.last {
                effective = String(lastChar)
            }
            clearMinuteOnNextType = false
        } else if clearMinuteOnNextType && digits.count < old.filter({ $0.isNumber }).count {
            clearMinuteOnNextType = false
        }

        if effective.count > 2 {
            effective = String(effective.prefix(2))
        }

        if minuteText != effective {
            minuteText = effective
        }

        if let m = Int(effective) {
            let validM = min(m, 59)
            updateTime(hour: Int(hourText) ?? 0, minute: validM)
        }
    }

    private func updateTime(hour: Int, minute: Int) {
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month, .day], from: time)
        comps.hour = min(max(hour, 0), 23)
        comps.minute = min(max(minute, 0), 59)
        if let newDate = cal.date(from: comps) {
            time = newDate
        }
    }
}

// MARK: - AddEventView

struct AddEventView: View {
    @Binding var isPresented: Bool
    let initialDate: Date
    @State private var title = ""
    @State private var date: Date
    @State private var startTime: Date
    @State private var reminderEnabled = false
    @State private var reminderTime: Date

    init(isPresented: Binding<Bool>, initialDate: Date) {
        self._isPresented = isPresented
        self.initialDate = initialDate
        self._date = State(initialValue: initialDate)

        let now = Date()
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month, .day], from: initialDate)
        let nowComps = cal.dateComponents([.hour, .minute], from: now)
        comps.hour = nowComps.hour
        comps.minute = nowComps.minute

        let start = cal.date(from: comps) ?? initialDate
        self._startTime = State(initialValue: start)
        self._reminderTime = State(initialValue: start)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Cosa devi fare?") {
                    TextField("Esempio: Visita medica, Dentista, Spesa...", text: $title)
                        .font(.body)
                }

                Section("Quando") {
                    DatePicker("Giorno", selection: $date, displayedComponents: .date)
                    TimePickerField(label: "Orario", time: $startTime, isNewEvent: true)
                }

                Section("Promemoria") {
                    Toggle("🔔 Avvisami con notifica", isOn: $reminderEnabled)

                    if reminderEnabled {
                        TimePickerField(label: "Orario Notifica", time: $reminderTime, isNewEvent: true)
                    }
                }
            }
            .navigationTitle("Nuovo Impegno")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annulla") { isPresented = false }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Salva") {
                        saveAndDismiss()
                    }
                    .bold()
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func saveAndDismiss() {
        let cleanTitle = title.trimmingCharacters(in: .whitespaces)
        guard !cleanTitle.isEmpty else { return }

        let cal = Calendar.current
        let dateComps = cal.dateComponents([.year, .month, .day], from: date)

        var startComps = cal.dateComponents([.hour, .minute, .second], from: startTime)
        startComps.year = dateComps.year
        startComps.month = dateComps.month
        startComps.day = dateComps.day
        let unifiedStartTime = cal.date(from: startComps) ?? startTime

        var unifiedReminderTime: Date? = nil
        if reminderEnabled {
            var remComps = cal.dateComponents([.hour, .minute, .second], from: reminderTime)
            remComps.year = dateComps.year
            remComps.month = dateComps.month
            remComps.day = dateComps.day
            unifiedReminderTime = cal.date(from: remComps) ?? reminderTime
        }

        AuthManager.shared.addEvent(
            title: cleanTitle,
            date: date,
            startTime: unifiedStartTime,
            reminderEnabled: reminderEnabled,
            reminderTime: unifiedReminderTime
        )
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        isPresented = false
    }
}

// MARK: - EditEventView

struct EditEventView: View {
    @Environment(\.dismiss) var dismiss
    @State var event: CalendarEvent
    @State private var title: String
    @State private var date: Date
    @State private var startTime: Date
    @State private var reminderEnabled: Bool
    @State private var reminderTime: Date

    init(event: CalendarEvent) {
        self._event = State(initialValue: event)
        self._title = State(initialValue: event.title)
        self._date = State(initialValue: event.date)
        self._startTime = State(initialValue: event.startTime)
        self._reminderEnabled = State(initialValue: event.reminderEnabled)
        self._reminderTime = State(initialValue: event.reminderTime ?? event.startTime)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Cosa") {
                    TextField("Titolo impegno", text: $title)
                        .font(.body)
                }

                Section("Quando") {
                    DatePicker("Giorno", selection: $date, displayedComponents: .date)
                    TimePickerField(label: "Orario", time: $startTime, isNewEvent: false)
                }

                Section("Promemoria") {
                    Toggle("🔔 Avvisami con notifica", isOn: $reminderEnabled)

                    if reminderEnabled {
                        TimePickerField(label: "Orario Notifica", time: $reminderTime, isNewEvent: false)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        AuthManager.shared.deleteEvent(event)
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Label("Elimina Impegno", systemImage: "trash")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Modifica Impegno")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Salva") {
                        saveChanges()
                    }
                    .bold()
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func saveChanges() {
        let cleanTitle = title.trimmingCharacters(in: .whitespaces)
        guard !cleanTitle.isEmpty else { return }

        let cal = Calendar.current
        let dateComps = cal.dateComponents([.year, .month, .day], from: date)

        var startComps = cal.dateComponents([.hour, .minute, .second], from: startTime)
        startComps.year = dateComps.year
        startComps.month = dateComps.month
        startComps.day = dateComps.day
        let unifiedStartTime = cal.date(from: startComps) ?? startTime

        var unifiedReminderTime: Date? = nil
        if reminderEnabled {
            var remComps = cal.dateComponents([.hour, .minute, .second], from: reminderTime)
            remComps.year = dateComps.year
            remComps.month = dateComps.month
            remComps.day = dateComps.day
            unifiedReminderTime = cal.date(from: remComps) ?? reminderTime
        }

        var updated = event
        updated.title = cleanTitle
        updated.date = date
        updated.startTime = unifiedStartTime
        updated.reminderEnabled = reminderEnabled
        updated.reminderTime = unifiedReminderTime

        AuthManager.shared.updateEvent(updated)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        dismiss()
    }
}

// MARK: - AllRemindersView

struct AllRemindersView: View {
    @Binding var isPresented: Bool
    @State private var auth = AuthManager.shared

    var futureReminders: [CalendarEvent] {
        let startOfToday = Calendar.current.startOfDay(for: Date())
        return auth.calendarEvents
            .filter { $0.reminderEnabled && $0.date >= startOfToday }
            .sorted(by: {
                if Calendar.current.isDate($0.date, inSameDayAs: $1.date) {
                    return $0.startTime < $1.startTime
                }
                return $0.date < $1.date
            })
    }

    var body: some View {
        NavigationStack {
            List {
                if futureReminders.isEmpty {
                    ContentUnavailableView(
                        "Nessun Promemoria",
                        systemImage: "bell.slash",
                        description: Text("Tutti i tuoi impegni con notifica attiva appariranno qui.")
                    )
                } else {
                    ForEach(futureReminders) { event in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(event.title).font(.headline)
                                Text(event.date.formatted(.dateTime.day().month().locale(Locale(identifier: "it_IT"))))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                if let rt = event.reminderTime {
                                    Label(rt.formatted(.dateTime.hour().minute()), systemImage: "clock")
                                        .font(.caption2.bold())
                                        .foregroundColor(.orange)
                                } else {
                                    Label(event.startTime.formatted(.dateTime.hour().minute()), systemImage: "clock")
                                        .font(.caption2.bold())
                                        .foregroundColor(.orange)
                                }
                            }
                            Spacer()
                            Image(systemName: "bell.fill").foregroundColor(.orange)
                        }
                    }
                }
            }
            .navigationTitle("Promemoria Attivi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Chiudi") { isPresented = false }
                }
            }
        }
    }
}

// MARK: - Profile

struct ProfileView: View {
    @State private var auth = AuthManager.shared
    @State private var isCopied = false
    @State private var showLogoutConfirm = false
    @AppStorage("appTheme") private var appTheme: String = "system"
    @AppStorage("timePickerMode") private var timePickerMode: String = "Apple"
    private let bg = Color(uiColor: .systemBackground)

    private var themeDisplayName: String {
        switch appTheme {
        case "light": return "Chiaro"
        case "dark": return "Scuro"
        default: return "Sistema"
        }
    }

    private var iconDisplayName: String {
        guard let name = UIApplication.shared.alternateIconName else { return "Originale" }
        if name.contains("white") { return "Bianca" }
        if name.contains("purple") { return "Viola" }
        if name.contains("green") { return "Verde" }
        if name.contains("orange") { return "Arancione" }
        return "Originale"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                bg.ignoresSafeArea()
                VStack(spacing: 20) {
                    Spacer()

                    // Logo
                    Image("AppLogo").resizable().scaledToFill()
                        .frame(width: 72, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                    // Username + codice
                    VStack(spacing: 8) {
                        Text(auth.username.isEmpty ? "" : "@\(auth.username)")
                            .font(.title2.bold())
                            .foregroundStyle(.primary)

                        if !auth.friendCode.isEmpty {
                            Button {
                                UIPasteboard.general.string = auth.friendCode
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                withAnimation { isCopied = true }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                                    withAnimation { isCopied = false }
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Text("#\(auth.friendCode)")
                                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                                        .foregroundStyle(.primary.opacity(0.85))
                                    Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(isCopied ? .green : .primary.opacity(0.5))
                                    if isCopied {
                                        Text("Copiato!")
                                            .font(.caption2.bold())
                                            .foregroundStyle(.green)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.primary.opacity(0.08))
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(Color.primary.opacity(0.12), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                            .contentShape(Capsule())
                        }
                    }

                    Spacer()

                    // Bottoni a rettangolo smussato conformi allo stile dell'app
                    VStack(spacing: 10) {
                        ProfileMenuButton(
                            icon: "person.2.fill",
                            iconColor: .blue,
                            title: "Amici",
                            value: auth.friends.isEmpty ? nil : "\(auth.friends.count)",
                            destination: FriendsView()
                        )

                        ProfileMenuButton(
                            icon: "circle.lefthalf.filled",
                            iconColor: .purple,
                            title: "Tema",
                            value: themeDisplayName,
                            destination: ThemeSettingsView()
                        )

                        ProfileMenuButton(
                            icon: "clock.fill",
                            iconColor: .orange,
                            title: "Orologio",
                            value: timePickerMode,
                            destination: ClockSettingsView()
                        )

                        ProfileMenuButton(
                            icon: "paintbrush.fill",
                            iconColor: .pink,
                            title: "Icona",
                            value: iconDisplayName,
                            destination: IconPickerView()
                        )

                        Button {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            showLogoutConfirm = true
                        } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(.red)
                                    .frame(width: 36, height: 36)
                                    .background(Color.red.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                                Text("Esci")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.red)

                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 56)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.red.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 16)
                }
            }
            .hideNavigationBar()
            .confirmationDialog("Vuoi davvero uscire dall'account?", isPresented: $showLogoutConfirm, titleVisibility: .visible) {
                Button("Esci", role: .destructive) {
                    auth.logout()
                }
                Button("Annulla", role: .cancel) {}
            }
            .onAppear {
                if let uid = auth.currentUser?.uid, auth.friendCode.isEmpty {
                    Task {
                        await auth.loadProfile(uid: uid)
                    }
                }
            }
        }
    }
}

// MARK: - Profile Menu Button

struct ProfileMenuButton<Destination: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String?
    let destination: Destination

    init(icon: String, iconColor: Color = .blue, title: String, value: String? = nil, destination: Destination) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.value = value
        self.destination = destination
    }

    var body: some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .frame(width: 36, height: 36)
                    .background(iconColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)

                Spacer()

                if let value = value, !value.isEmpty {
                    Text(value)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .frame(height: 56)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
    private let bg = Color(uiColor: .systemBackground)

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            VStack(spacing: 0) {

                // Header
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 38, height: 38)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.primary.opacity(0.12), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .contentShape(Circle())

                    Spacer()

                    Button {
                        withAnimation(.spring(response: 0.35)) { showAdd.toggle() }
                        if showAdd { codeFocused = true }
                    } label: {
                        Image(systemName: showAdd ? "xmark" : "person.badge.plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 38, height: 38)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.primary.opacity(0.12), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .contentShape(Circle())
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 28)

                Text("Amici").font(.title.bold()).foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading).padding(.horizontal, 24).padding(.bottom, 20)

                // Form aggiungi amico
                if showAdd {
                    VStack(spacing: 10) {
                        AuthField(icon: "number", placeholder: "Codice a 6 cifre", text: $codeInput)
                            .keyboardType(.numberPad)
                            .focused($codeFocused)
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
                            .foregroundStyle(.secondary.opacity(0.4))
                        Text("Nessun amico aggiunto").font(.system(size: 16))
                            .foregroundStyle(.secondary)
                        Text("Tocca + per aggiungerne uno col suo codice").font(.system(size: 14))
                            .foregroundStyle(.secondary.opacity(0.7))
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
                                            .foregroundStyle(.primary)
                                        Text("#\(friend.friendCode)")
                                            .font(.system(size: 13, design: .monospaced))
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Button {
                                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                        auth.removeFriend(friend.id)
                                    } label: {
                                        Image(systemName: "person.badge.minus")
                                            .font(.system(size: 16))
                                            .frame(width: 44, height: 44)
                                            .foregroundStyle(.red.opacity(0.7))
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 18).frame(minHeight: 60)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                                )
                            }
                        }
                        .padding(.horizontal, 24).padding(.bottom, 24)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .hideNavigationBar()
        .animation(.easeInOut(duration: 0.2), value: showAdd)
        .animation(.easeInOut(duration: 0.2), value: auth.errorMessage)
        .onAppear { auth.errorMessage = nil }
    }
}

// MARK: - Theme Settings View

struct ThemeSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appTheme") private var appTheme: String = "system"
    private let bg = Color(uiColor: .systemBackground)

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            VStack(spacing: 0) {
                // Header con Back
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 38, height: 38)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.primary.opacity(0.12), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .contentShape(Circle())

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 28)

                // Titolo & Descrizione
                VStack(spacing: 6) {
                    Text("Tema")
                        .font(.title.bold())
                        .foregroundStyle(.primary)
                    Text("Scegli l'aspetto visivo di Simply")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 36)

                // Opzioni Tema
                VStack(spacing: 16) {
                    themeOptionCard(
                        mode: "system",
                        icon: "circle.lefthalf.filled",
                        title: "Sistema",
                        description: "Segue automaticamente le impostazioni del tuo iPhone"
                    )

                    themeOptionCard(
                        mode: "light",
                        icon: "sun.max.fill",
                        title: "Chiaro",
                        description: "Interfaccia luminosa con sfondi chiari e testi scuri"
                    )

                    themeOptionCard(
                        mode: "dark",
                        icon: "moon.fill",
                        title: "Scuro",
                        description: "Interfaccia scura ad alto contrasto (AMOLED black)"
                    )
                }
                .padding(.horizontal, 24)

                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .hideNavigationBar()
    }

    @ViewBuilder
    private func themeOptionCard(mode: String, icon: String, title: String, description: String) -> some View {
        let isSelected = (appTheme == mode)

        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                appTheme = mode
            }
        } label: {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(isSelected ? .purple : .primary.opacity(0.6))
                    .frame(width: 44, height: 44)
                    .background(isSelected ? Color.purple.opacity(0.15) : Color.primary.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.purple)
                } else {
                    Circle()
                        .stroke(Color.primary.opacity(0.2), lineWidth: 1.5)
                        .frame(width: 20, height: 20)
                }
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isSelected ? Color.purple.opacity(0.6) : Color.primary.opacity(0.1), lineWidth: isSelected ? 1.5 : 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Clock Settings View

struct ClockSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("timePickerMode") private var timePickerMode: String = "Apple"
    @State private var previewTime: Date = Date()
    private let bg = Color(uiColor: .systemBackground)

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            VStack(spacing: 0) {
                // Header con Back
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.primary)
                            .frame(width: 38, height: 38)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.primary.opacity(0.12), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .contentShape(Circle())

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 28)

                // Titolo & Descrizione
                VStack(spacing: 6) {
                    Text("Orologio")
                        .font(.title.bold())
                        .foregroundStyle(.primary)
                    Text("Scegli come inserire l'orario negli impegni")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 36)

                // Opzioni
                VStack(spacing: 16) {
                    clockOptionCard(
                        mode: "Apple",
                        icon: "clock.fill",
                        title: "Apple",
                        description: "Ruota verticale classica dell'app Orologio"
                    )

                    clockOptionCard(
                        mode: "Manuale",
                        icon: "keyboard.fill",
                        title: "Manuale",
                        description: "Tastierino numerico rapido con caselle Ore : Minuti"
                    )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)

                // Anteprima dal vivo
                VStack(alignment: .leading, spacing: 12) {
                    Text("ANTEPRIMA")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 28)

                    VStack(spacing: 14) {
                        TimePickerField(label: "Orario Prova", time: $previewTime, isNewEvent: false)

                        Text(timePickerMode == "Apple" ? "Gira la ruota per selezionare l'orario" : "Tocca le caselle per digitare l'orario con la tastiera")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                }

                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .hideNavigationBar()
    }

    @ViewBuilder
    private func clockOptionCard(mode: String, icon: String, title: String, description: String) -> some View {
        let isSelected = (timePickerMode == mode)

        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                timePickerMode = mode
            }
        } label: {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(isSelected ? .blue : .primary.opacity(0.6))
                    .frame(width: 44, height: 44)
                    .background(isSelected ? Color.blue.opacity(0.15) : Color.primary.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.blue)
                } else {
                    Circle()
                        .stroke(Color.primary.opacity(0.2), lineWidth: 1.5)
                        .frame(width: 20, height: 20)
                }
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isSelected ? Color.blue.opacity(0.6) : Color.primary.opacity(0.1), lineWidth: isSelected ? 1.5 : 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Icon Picker

struct AppIconOption: Identifiable {
    let id: String
    let assetName: String
    let label: String
}

struct IconPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentIcon: String? = UIApplication.shared.alternateIconName
    private let bg = Color(uiColor: .systemBackground)
    private let icons: [AppIconOption] = [
        AppIconOption(id: "default",       assetName: "simply_black",  label: "Originale"),
        AppIconOption(id: "simply_white",  assetName: "simply_white",  label: "Bianca"),
        AppIconOption(id: "simply_purple", assetName: "simply_purple", label: "Viola"),
        AppIconOption(id: "simply_green",  assetName: "simply_green",  label: "Verde"),
        AppIconOption(id: "simply_orange", assetName: "simply_orange", label: "Arancione"),
    ]

    private var selectedId: String {
        if let icon = currentIcon {
            if icon.contains("purple") { return "simply_purple" }
            if icon.contains("white") { return "simply_white" }
            if icon.contains("green") { return "simply_green" }
            if icon.contains("orange") { return "simply_orange" }
            if icon.contains("black") { return "default" }
            return icon
        }
        return "default"
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
                            .foregroundStyle(.primary)
                            .frame(width: 38, height: 38)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.primary.opacity(0.12), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .contentShape(Circle())
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 28)

                VStack(spacing: 6) {
                    Text("Icona App")
                        .font(.title.bold())
                        .foregroundStyle(.primary)
                    Text("Scegli lo stile che preferisci")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 36)

                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 18) {
                        ForEach(icons) { option in
                            IconOptionCell(option: option, isSelected: selectedId == option.id) {
                                applyIcon(option)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .hideNavigationBar()
    }

    private func applyIcon(_ option: AppIconOption) {
        guard selectedId != option.id else { return }
        let name: String? = (option.id == "default" || option.id == "simply_black") ? nil : option.id
        guard UIApplication.shared.supportsAlternateIcons else { return }

        UIApplication.shared.setAlternateIconName(name) { err in
            DispatchQueue.main.async {
                if let err = err {
                    print("Errore cambio icona: \(err.localizedDescription)")
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        currentIcon = name
                    }
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
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
                Image(option.assetName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 78, height: 78)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(isSelected ? Color.blue : Color.primary.opacity(0.12), lineWidth: isSelected ? 3 : 1)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 8, y: 4)

                HStack(spacing: 6) {
                    Text(option.label)
                        .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                        .foregroundStyle(isSelected ? Color.blue : Color.primary.opacity(0.75))

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.blue)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isSelected ? Color.blue.opacity(0.5) : Color.primary.opacity(0.08), lineWidth: 1)
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
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
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
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#Preview { ContentView() }
