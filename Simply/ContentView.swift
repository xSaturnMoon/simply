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
            Tab("Lista", systemImage: "cart") { ShoppingListView() }
            Tab("Calendario", systemImage: "calendar") { CalendarView() }
            Tab("Profilo", systemImage: "person.circle") { ProfileView() }
        }
    }
}

// MARK: - Shopping List

struct ShoppingListView: View {
    @State private var auth = AuthManager.shared
    @State private var selectedFriendUid: String? = nil  // nil = la mia lista
    @State private var newItemText = ""
    @State private var showInput = false
    @FocusState private var inputFocused: Bool
    private let bg = Color(red: 28/255, green: 28/255, blue: 30/255)

    private var currentItems: [ShoppingItem] {
        if let uid = selectedFriendUid { return auth.friendsItems[uid] ?? [] }
        return auth.myItems
    }
    private var isMyList: Bool { selectedFriendUid == nil }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()
            VStack(spacing: 0) {

                // Header
                HStack {
                    Text("Lista")
                        .font(.system(size: 28, weight: .bold)).foregroundStyle(.white)
                    Spacer()
                    if isMyList {
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { showInput.toggle() }
                            if showInput { inputFocused = true }
                        } label: {
                            Image(systemName: showInput ? "xmark" : "plus")
                                .font(.system(size: 16, weight: .semibold)).foregroundStyle(.white)
                                .frame(width: 36, height: 36).glassEffect(.regular, in: Circle())
                        }.contentShape(Circle())
                    }
                }
                .padding(.horizontal, 24).padding(.top, 16).padding(.bottom, 12)

                // Selettore Io / Amici
                if !auth.friends.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            // "Io"
                            ListTabPill(label: "Io", isSelected: isMyList) {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedFriendUid = nil
                                    showInput = false
                                }
                            }
                            ForEach(auth.friends) { friend in
                                ListTabPill(label: friend.nickname, isSelected: selectedFriendUid == friend.id) {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedFriendUid = friend.id
                                        showInput = false
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 12)
                }

                // Campo aggiungi (solo lista mia)
                if showInput && isMyList {
                    HStack(spacing: 12) {
                        TextField("", text: $newItemText,
                            prompt: Text("Aggiungi elemento...").foregroundStyle(.white.opacity(0.4)))
                            .foregroundStyle(.white).focused($inputFocused)
                            .submitLabel(.done).onSubmit { addItem() }
                        Button { addItem() } label: {
                            Image(systemName: "arrow.up.circle.fill").font(.system(size: 28))
                                .foregroundStyle(newItemText.isEmpty ? .white.opacity(0.25) : .white)
                        }.disabled(newItemText.trimmingCharacters(in: .whitespaces).isEmpty).buttonStyle(.plain)
                    }
                    .padding(.horizontal, 18).frame(height: 54)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal, 24).padding(.bottom, 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Lista
                if currentItems.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "cart").font(.system(size: 44, weight: .light)).foregroundStyle(.white.opacity(0.2))
                        Text("Nessun elemento").font(.system(size: 16)).foregroundStyle(.white.opacity(0.3))
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(currentItems) { item in
                                ShoppingRow(
                                    item: item,
                                    isMine: isMyList,
                                    onToggle: {
                                        if isMyList { auth.toggleMyItem(item) }
                                        else if let uid = selectedFriendUid { auth.toggleFriendItem(item, friendUid: uid) }
                                    },
                                    onDelete: isMyList ? { auth.deleteMyItem(item) } : nil
                                )
                            }
                        }
                        .padding(.horizontal, 24).padding(.bottom, 24)
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showInput)
        .animation(.easeInOut(duration: 0.15), value: selectedFriendUid)
    }

    private func addItem() {
        let t = newItemText.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        auth.addMyItem(t)
        newItemText = ""
        inputFocused = true
    }
}

// MARK: - List Tab Pill

struct ListTabPill: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .black : .white.opacity(0.7))
                .padding(.horizontal, 16).frame(height: 32)
                .background {
                    if isSelected { Capsule().fill(Color.white) }
                    else { Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1) }
                }
        }
        .contentShape(Capsule())
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

// MARK: - Shopping Row

struct ShoppingRow: View {
    let item: ShoppingItem
    let isMine: Bool
    let onToggle: () -> Void
    let onDelete: (() -> Void)?

    var body: some View {
        HStack(spacing: 16) {
            Button(action: onToggle) {
                Image(systemName: item.completed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(item.completed ? .white : .white.opacity(0.35))
                    .contentTransition(.symbolEffect(.replace))
            }.buttonStyle(.plain)

            Text(item.name)
                .font(.system(size: 16))
                .foregroundStyle(item.completed ? .white.opacity(0.35) : .white)
                .strikethrough(item.completed, color: .white.opacity(0.35))
                .frame(maxWidth: .infinity, alignment: .leading)

            if let del = onDelete {
                Button(action: del) {
                    Image(systemName: "trash").font(.system(size: 15)).foregroundStyle(.white.opacity(0.25))
                }.buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 18).frame(minHeight: 54)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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
                                }.buttonStyle(.plain)
                            }
                        }
                    }

                    Spacer()

                    // Bottoni
                    VStack(spacing: 12) {
                        NavigationLink(destination: FriendsView()) {
                            AuthPill(label: "Amici", style: .outlined)
                        }.contentShape(Capsule()).buttonStyle(.plain)

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
                    }.buttonStyle(.plain).contentShape(Circle())
                    Spacer()
                    Button {
                        withAnimation(.spring(response: 0.35)) { showAdd.toggle() }
                        if showAdd { codeFocused = true }
                    } label: {
                        Image(systemName: showAdd ? "xmark" : "person.badge.plus")
                            .font(.system(size: 16, weight: .semibold)).foregroundStyle(.white)
                            .frame(width: 38, height: 38).glassEffect(.regular, in: Circle())
                    }.contentShape(Circle())
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
                        .contentShape(Capsule()).disabled(auth.isLoading)
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
                                            .foregroundStyle(.red.opacity(0.6))
                                    }.buttonStyle(.plain)
                                }
                                .padding(.horizontal, 18).frame(minHeight: 60)
                                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
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
