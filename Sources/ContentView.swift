import SwiftUI

// MARK: - App Entry

struct ContentView: View {
    @StateObject private var session = SessionManager()
    @State private var showSplash = true

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if showSplash {
                SplashView()
                    .transition(.opacity)
                    .zIndex(1)
            } else if session.isLoggedIn {
                MainTabView()
                    .transition(.opacity)
            } else {
                AuthView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: session.isLoggedIn)
        .environmentObject(session)
        .preferredColorScheme(.dark)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    showSplash = false
                }
            }
        }
    }
}

// MARK: - Auth Model

struct AuthUser: Codable, Equatable {
    var username: String
    var email: String
    var isGuest: Bool = false
}

enum AuthError: LocalizedError {
    case invalidCredentials
    case accountExists
    case network
    case custom(String)

    var errorDescription: String? {
        switch self {
        case .invalidCredentials: return "Wrong username or password."
        case .accountExists: return "This account already exists."
        case .network: return "Can't reach the server. Check your connection."
        case .custom(let message): return message
        }
    }
}

// MARK: - Auth Service

protocol AuthService {
    func login(username: String, key: String) async throws -> AuthUser
}

/// Calls the DoniMods License API. Set apiBaseURL to your deployed Vercel URL.
struct APIAuthService: AuthService {
    // Example: https://your-project.vercel.app
    private let apiBaseURL = "https://doni-mods-license-system.vercel.app"

    private struct RequestBody: Encodable { let username: String; let key: String }
    private struct ResponseBody: Decodable {
        let valid: Bool
        let code: String?
        let message: String?
        let username: String?
        let expires_at: String?
    }

    func login(username: String, key: String) async throws -> AuthUser {
        guard !apiBaseURL.contains("YOUR-VERCEL-DOMAIN") else {
            throw AuthError.custom("Chưa cấu hình URL API Vercel trong ContentView.swift.")
        }
        guard let url = URL(string: apiBaseURL + "/api/validate") else {
            throw AuthError.custom("URL API không hợp lệ.")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15
        request.httpBody = try JSONEncoder().encode(RequestBody(username: username, key: key))
        let (data, response): (Data, URLResponse)
        do { (data, response) = try await URLSession.shared.data(for: request) }
        catch { throw AuthError.custom("Không kết nối được máy chủ. Hãy kiểm tra Internet.") }
        guard let http = response as? HTTPURLResponse else { throw AuthError.network }
        let result = try? JSONDecoder().decode(ResponseBody.self, from: data)
        guard http.statusCode == 200, let result else {
            throw AuthError.custom(result?.message ?? "Máy chủ trả về lỗi (HTTP \(http.statusCode)).")
        }
        guard result.valid else {
            throw AuthError.custom(result.message ?? result.code ?? "License key không hợp lệ.")
        }
        return AuthUser(username: result.username ?? username, email: "", isGuest: false)
    }
}

// MARK: - Session Manager

@MainActor
final class SessionManager: ObservableObject {
    @Published private(set) var user: AuthUser?
    @Published private(set) var isLoading = false

    private let service: AuthService
    private static let storageKey = "doni_session_user"

    var isLoggedIn: Bool { user != nil }

    init(service: AuthService = APIAuthService()) {
        self.service = service
        self.user = Self.loadStoredUser()
    }

    func login(username: String, key: String) async throws {
        isLoading = true
        defer { isLoading = false }
        let user = try await service.login(username: username, key: key)
        setUser(user)
    }


    func logout() {
        user = nil
        UserDefaults.standard.removeObject(forKey: Self.storageKey)
    }

    private func setUser(_ newUser: AuthUser) {
        user = newUser
        if let data = try? JSONEncoder().encode(newUser) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    private static func loadStoredUser() -> AuthUser? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(AuthUser.self, from: data)
    }
}

// MARK: - Shared Background

struct NeonBackground: View {
    var glowOffset: CGSize = CGSize(width: 80, height: -120)

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.03, green: 0.03, blue: 0.08), .black],
                startPoint: .top,
                endPoint: .bottom
            )

            Circle()
                .fill(Color.cyan.opacity(0.10))
                .frame(width: 260, height: 260)
                .blur(radius: 70)
                .offset(glowOffset)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Splash

struct SplashView: View {
    @State private var animate = false
    @State private var glowPulse = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Circle()
                .fill(Color.cyan.opacity(0.15))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .scaleEffect(glowPulse ? 1.2 : 0.9)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: glowPulse)

            VStack(spacing: 10) {
                Text("DoniMods")
                    .font(.system(size: 40, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.cyan, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: .cyan.opacity(0.8), radius: 12)
                    .scaleEffect(animate ? 1 : 0.8)
                    .opacity(animate ? 1 : 0)

                Text("WELCOME")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(8)
                    .foregroundStyle(.cyan.opacity(0.7))
                    .opacity(animate ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(duration: 0.8)) { animate = true }
            glowPulse = true
        }
    }
}

// MARK: - Auth Screen

enum AuthField: Hashable {
    case username, password
}

struct AuthView: View {
    @EnvironmentObject private var session: SessionManager

    @State private var username = ""
    @State private var licenseKey = ""
    @State private var errorMessage: String?
    @FocusState private var focus: AuthField?

    var body: some View {
        ZStack {
            NeonBackground(glowOffset: CGSize(width: 0, height: -220))

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    header
                    formCard

                    if let message = errorMessage {
                        errorBanner(message)
                    }

                    primaryButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 40)
                .padding(.bottom, 30)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private var header: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.cyan.opacity(0.3), .blue.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 84, height: 84)

                Circle()
                    .stroke(LinearGradient(
                        colors: [.cyan, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ), lineWidth: 2)
                    .frame(width: 84, height: 84)
                    .shadow(color: .cyan.opacity(0.5), radius: 10)

                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(.cyan)
                    .shadow(color: .cyan, radius: 8)
            }

            Text("DoniMods")
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(LinearGradient(
                    colors: [.cyan, .blue],
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .shadow(color: .cyan.opacity(0.5), radius: 8)

            Text("Sign in to continue")
                .font(.system(size: 14))
                .foregroundStyle(.gray)
        }
        .padding(.bottom, 4)
    }

    private var formCard: some View {
        VStack(spacing: 12) {
            NeonField(
                icon: "person.fill",
                placeholder: "Username",
                text: $username,
                field: .username,
                focus: $focus,
                contentType: .username,
                submitLabel: .next,
                onSubmit: { focus = .password }
            )

            NeonField(
                icon: "key.fill",
                placeholder: "License Key",
                text: $licenseKey,
                field: .password,
                focus: $focus,
                isSecure: false,
                contentType: nil,
                submitLabel: .go,
                onSubmit: { submit() }
            )

            HStack(spacing: 6) {
                Image(systemName: "shield.lefthalf.filled")
                Text("License key is verified securely by the server.")
            }
            .font(.system(size: 11))
            .foregroundStyle(.gray)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 2)
        }
        .padding(16)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.cyan.opacity(0.18), lineWidth: 1)
        }
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14))
                .foregroundStyle(.red)

            Text(message)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.red.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        }
    }

    private var primaryButton: some View {
        Button(action: submit) {
            ZStack {
                if session.isLoading {
                    ProgressView().tint(.black)
                } else {
                    HStack(spacing: 8) {
                        Text("Login")
                            .font(.system(size: 15, weight: .bold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 13, weight: .bold))
                    }
                }
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(LinearGradient(
                colors: [.cyan, .blue],
                startPoint: .leading,
                endPoint: .trailing
            ))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .cyan.opacity(0.35), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(session.isLoading)
    }

    private func submit() {
        guard !session.isLoading else { return }
        focus = nil

        let name = username.trimmingCharacters(in: .whitespaces)
        let key = licenseKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, !key.isEmpty else {
            errorMessage = "Please enter your username and license key."
            return
        }
        errorMessage = nil

        Task { @MainActor in
            do {
                try await session.login(username: name, key: key)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Neon Text Field

struct NeonField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    let field: AuthField
    let focus: FocusState<AuthField?>.Binding
    var isSecure = false
    var keyboard: UIKeyboardType = .default
    var contentType: UITextContentType? = nil
    var submitLabel: SubmitLabel = .next
    var onSubmit: () -> Void = {}

    @State private var reveal = false

    private var isFocused: Bool { focus.wrappedValue == field }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(isFocused ? Color.cyan : Color.gray)
                .frame(width: 20)

            Group {
                if isSecure && !reveal {
                    SecureField("", text: $text, prompt: Text(placeholder).foregroundColor(.gray))
                } else {
                    TextField("", text: $text, prompt: Text(placeholder).foregroundColor(.gray))
                }
            }
            .focused(focus, equals: field)
            .font(.system(size: 15))
            .foregroundStyle(.white)
            .keyboardType(keyboard)
            .textContentType(contentType)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .submitLabel(submitLabel)
            .onSubmit(onSubmit)

            if isSecure {
                Button {
                    reveal.toggle()
                } label: {
                    Image(systemName: reveal ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.gray)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 50)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(isFocused ? Color.cyan.opacity(0.8) : Color.white.opacity(0.10), lineWidth: 1)
        }
        .shadow(color: isFocused ? Color.cyan.opacity(0.25) : Color.clear, radius: 8)
        .animation(.easeOut(duration: 0.15), value: isFocused)
    }
}

// MARK: - Main Tabs

struct MainTabView: View {
    @State private var selectedTab = 0

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.08, alpha: 1)
        appearance.shadowColor = UIColor.cyan.withAlphaComponent(0.3)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView { selectedTab = 1 }
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                    Text("Home")
                }
                .tag(0)

            ToolsView()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "bolt.fill" : "bolt")
                    Text("Tools")
                }
                .tag(1)

            ProfileView()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "person.fill" : "person")
                    Text("Profile")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "gearshape.fill" : "gearshape")
                    Text("Settings")
                }
                .tag(3)
        }
        .tint(.cyan)
    }
}

// MARK: - Home

struct HomeView: View {
    let onExploreTools: () -> Void
    @EnvironmentObject private var session: SessionManager
    @State private var pulse = false

    private let features = [
        ("bolt.fill", "Speed Boost", "Optimize game performance instantly"),
        ("shield.fill", "Protection", "Anti-ban & safety tools"),
        ("star.fill", "Premium Mods", "Exclusive modded features")
    ]

    private var displayName: String {
        session.user?.username ?? "Player"
    }

    var body: some View {
        ZStack {
            NeonBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {

                    // Top Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Welcome back, \(displayName)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.gray)
                                .lineLimit(1)
                            Text("DoniMods")
                                .font(.system(size: 26, weight: .black, design: .rounded))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.cyan, .blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: .cyan.opacity(0.5), radius: 6)
                        }

                        Spacer(minLength: 8)

                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 7, height: 7)
                                .shadow(color: .green, radius: 4)
                                .scaleEffect(pulse ? 1.3 : 1.0)
                                .animation(.easeInOut(duration: 0.8).repeatForever(), value: pulse)

                            Text("ONLINE")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(1.5)
                                .foregroundStyle(.green)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.1))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.green.opacity(0.3), lineWidth: 1))
                    }
                    .padding(.top, 8)

                    // Hero Banner
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Image(systemName: "gamecontroller.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(.cyan)
                                .shadow(color: .cyan, radius: 8)

                            Spacer()

                            Text("v1.0.0")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(1)
                                .foregroundStyle(.cyan.opacity(0.7))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.cyan.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }

                        Text("Your Ultimate\nGame Toolbox")
                            .font(.system(size: 22, weight: .black))
                            .foregroundStyle(.white)
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Access powerful mods, tweaks and tools to level up your gaming experience.")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.6))
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)

                        Button(action: onExploreTools) {
                            HStack(spacing: 8) {
                                Text("Explore Tools")
                                    .font(.system(size: 14, weight: .bold))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(
                                LinearGradient(
                                    colors: [.cyan, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .cyan.opacity(0.4), radius: 8, y: 4)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.cyan.opacity(0.2),
                                        Color.blue.opacity(0.1),
                                        Color.clear
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [.cyan.opacity(0.6), .blue.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }

                    // Features
                    VStack(alignment: .leading, spacing: 12) {
                        Text("FEATURES")
                            .font(.system(size: 11, weight: .black))
                            .tracking(3)
                            .foregroundStyle(.cyan.opacity(0.7))

                        ForEach(features, id: \.1) { feature in
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.cyan.opacity(0.1))
                                        .frame(width: 44, height: 44)
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                                        .frame(width: 44, height: 44)
                                    Image(systemName: feature.0)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(.cyan)
                                        .shadow(color: .cyan.opacity(0.6), radius: 4)
                                }

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(feature.1)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.white)
                                    Text(feature.2)
                                        .font(.system(size: 12))
                                        .foregroundStyle(.gray)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                Spacer(minLength: 0)

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.cyan.opacity(0.5))
                            }
                            .padding(14)
                            .background(Color.white.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay {
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.07), lineWidth: 1)
                            }
                        }
                    }

                    // Coming Soon
                    HStack(spacing: 12) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.orange)
                            .shadow(color: .orange.opacity(0.6), radius: 4)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("More Coming Soon")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                            Text("New tools dropping regularly")
                                .font(.system(size: 12))
                                .foregroundStyle(.gray)
                        }

                        Spacer(minLength: 0)

                        Text("SOON")
                            .font(.system(size: 10, weight: .black))
                            .tracking(1)
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    .padding(14)
                    .background(Color.orange.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 20)
            }
        }
        .onAppear { pulse = true }
    }
}

// MARK: - Tools

struct ToolsView: View {
    private let tools: [(String, String, String, Color)] = [
        ("Game Mods", "Active game modifications", "bolt.fill", .cyan),
        ("Speed Hack", "Game speed controller", "speedometer", .purple),
        ("Aimbot Tools", "Precision aim assist", "scope", .pink),
        ("Skin Changer", "Custom game skins", "paintbrush.fill", .orange),
        ("ESP / Wallhack", "Visual enhancement tools", "eye.fill", .green),
        ("Coming Soon", "More tools coming soon", "clock.fill", .gray)
    ]

    var body: some View {
        ZStack {
            NeonBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    NeonPageHeader(title: "Tools", subtitle: "Select a tool to get started.")

                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ],
                        spacing: 12
                    ) {
                        ForEach(tools, id: \.0) { tool in
                            VStack(alignment: .leading, spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(tool.3.opacity(0.15))
                                        .frame(width: 40, height: 40)
                                    Image(systemName: tool.2)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(tool.3)
                                        .shadow(color: tool.3.opacity(0.8), radius: 4)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(tool.0)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(.white)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Text(tool.1)
                                        .font(.system(size: 11))
                                        .foregroundStyle(.gray)
                                        .fixedSize(horizontal: false, vertical: true)
                                }

                                Spacer(minLength: 0)

                                HStack {
                                    Spacer()
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(tool.3.opacity(0.6))
                                }
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, minHeight: 140, alignment: .topLeading)
                            .background(Color.white.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay {
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(tool.3.opacity(0.25), lineWidth: 1)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 20)
            }
        }
    }
}

// MARK: - Profile

struct ProfileView: View {
    @EnvironmentObject private var session: SessionManager
    @State private var showLogoutConfirm = false

    private let stats = [("Mods Used", "0"), ("Sessions", "0"), ("Rank", "—")]

    private var displayName: String {
        session.user?.username ?? "Player"
    }

    private var subtitle: String {
        if let mail = session.user?.email, !mail.isEmpty { return mail }
        return "Signed in"
    }

    var body: some View {
        ZStack {
            NeonBackground(glowOffset: CGSize(width: 0, height: -140))

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    NeonPageHeader(title: "Profile", subtitle: "Your gaming identity.")

                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.cyan.opacity(0.3), .blue.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 90, height: 90)

                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.cyan, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 90, height: 90)
                            .shadow(color: .cyan.opacity(0.4), radius: 8)

                        Image(systemName: "person.fill")
                            .font(.system(size: 38))
                            .foregroundStyle(.cyan.opacity(0.9))
                    }

                    VStack(spacing: 6) {
                        Text(displayName)
                            .font(.system(size: 22, weight: .black))
                            .foregroundStyle(.white)

                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundStyle(.gray)
                    }

                    HStack(spacing: 0) {
                        ForEach(Array(stats.enumerated()), id: \.0) { index, stat in
                            VStack(spacing: 4) {
                                Text(stat.1)
                                    .font(.system(size: 20, weight: .black))
                                    .foregroundStyle(.cyan)
                                    .shadow(color: .cyan.opacity(0.5), radius: 4)
                                Text(stat.0)
                                    .font(.system(size: 11))
                                    .foregroundStyle(.gray)
                            }
                            .frame(maxWidth: .infinity)

                            if index < stats.count - 1 {
                                Rectangle()
                                    .fill(Color.white.opacity(0.1))
                                    .frame(width: 1, height: 36)
                            }
                        }
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.cyan.opacity(0.2), lineWidth: 1)
                    }

                    Button {
                        showLogoutConfirm = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Log out")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.red.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.red.opacity(0.35), lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 20)
            }
        }
        .confirmationDialog("Log out of DoniMods?", isPresented: $showLogoutConfirm, titleVisibility: .visible) {
            Button("Log out", role: .destructive) {
                session.logout()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

// MARK: - Settings

struct SettingsView: View {
    @AppStorage("doni_notifications_enabled") private var notificationsEnabled = true
    @AppStorage("doni_haptics_enabled") private var hapticsEnabled = true

    var body: some View {
        ZStack {
            NeonBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    NeonPageHeader(title: "Settings", subtitle: "Configure your experience.")

                    VStack(spacing: 0) {
                        NeonSettingsRow(
                            title: "Notifications",
                            subtitle: "Enable push notifications",
                            icon: "bell.fill",
                            iconColor: .cyan,
                            isOn: $notificationsEnabled
                        )

                        Divider()
                            .overlay(Color.white.opacity(0.07))
                            .padding(.leading, 56)

                        NeonSettingsRow(
                            title: "Haptic Feedback",
                            subtitle: "Enable touch vibration",
                            icon: "iphone.radiowaves.left.and.right",
                            iconColor: .purple,
                            isOn: $hapticsEnabled
                        )
                    }
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.cyan.opacity(0.15), lineWidth: 1)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        Text("ABOUT")
                            .font(.system(size: 11, weight: .black))
                            .tracking(3)
                            .foregroundStyle(.cyan.opacity(0.6))

                        HStack {
                            Label("Application", systemImage: "app.fill")
                                .foregroundStyle(.white)
                            Spacer()
                            Text("DoniMods")
                                .foregroundStyle(.cyan)
                        }

                        Divider().overlay(Color.white.opacity(0.07))

                        HStack {
                            Label("Version", systemImage: "tag.fill")
                                .foregroundStyle(.white)
                            Spacer()
                            Text("1.0.0")
                                .foregroundStyle(.cyan)
                        }

                        Divider().overlay(Color.white.opacity(0.07))

                        HStack {
                            Label("Developer", systemImage: "hammer.fill")
                                .foregroundStyle(.white)
                            Spacer()
                            Text("Doni")
                                .foregroundStyle(.cyan)
                        }
                    }
                    .font(.system(size: 14))
                    .padding(16)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.cyan.opacity(0.15), lineWidth: 1)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 20)
            }
        }
    }
}

// MARK: - Neon Settings Row

struct NeonSettingsRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(iconColor)
                    .shadow(color: iconColor.opacity(0.6), radius: 3)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.gray)
            }

            Spacer(minLength: 8)

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.cyan)
        }
        .padding(14)
    }
}

// MARK: - Neon Page Header

struct NeonPageHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 28, weight: .black))
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.system(size: 13))
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 4)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
