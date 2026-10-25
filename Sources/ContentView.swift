import SwiftUI
import QuartzCore
import NetworkExtension

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
                MainView()
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


// MARK: - Server Model

struct ServerConfig: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let host: String
    let port: Int
    let flag: String
}

let predefinedServers: [ServerConfig] = [
    ServerConfig(name: "Mindo",    host: "103.183.120.157",    port: 1300, flag: "🌐"),
    ServerConfig(name: "SonDev",   host: "proxy.sondev.io.vn", port: 1299, flag: "🛡️"),
]

// MARK: - Proxy Credentials Store

final class ProxyCredentials: ObservableObject {
    static let shared = ProxyCredentials()
    private let usernameKey = "doni_proxy_username"
    private let passwordKey = "doni_proxy_password"

    @Published var username: String {
        didSet { UserDefaults.standard.set(username, forKey: usernameKey) }
    }
    @Published var password: String {
        didSet { UserDefaults.standard.set(password, forKey: passwordKey) }
    }

    private init() {
        username = UserDefaults.standard.string(forKey: "doni_proxy_username") ?? ""
        password = UserDefaults.standard.string(forKey: "doni_proxy_password") ?? ""
    }
}

// MARK: - VPN / Proxy Manager

@MainActor
final class VPNManager: ObservableObject {
    static let shared = VPNManager()

    @Published private(set) var status: NEVPNStatus = .disconnected
    @Published private(set) var connectedServer: ServerConfig?
    @Published private(set) var statusMessage = "Chưa kết nối"
    @Published private(set) var log: [String] = []

    private var vpnManager: NETunnelProviderManager?
    private var statusObserver: Any?

    private init() {
        Task { await loadManager() }
        startObserving()
    }

    private func loadManager() async {
        do {
            let managers = try await NETunnelProviderManager.loadAllFromPreferences()
            vpnManager = managers.first ?? NETunnelProviderManager()
        } catch {
            addLog("⚠️ Không tải được config: \(error.localizedDescription)")
        }
    }

    private func startObserving() {
        statusObserver = NotificationCenter.default.addObserver(
            forName: .NEVPNStatusDidChange, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.refreshStatus() }
        }
    }

    private func refreshStatus() {
        guard let mgr = vpnManager else { return }
        status = mgr.connection.status
        switch status {
        case .connected:
            statusMessage = "Đã kết nối · \(connectedServer?.name ?? "")"
            addLog("✅ Kết nối thành công!")
        case .connecting:
            statusMessage = "Đang kết nối..."
        case .disconnecting:
            statusMessage = "Đang ngắt kết nối..."
        case .disconnected:
            statusMessage = connectedServer == nil ? "Chưa kết nối" : "Đã ngắt kết nối"
            if connectedServer != nil { addLog("🔌 Đã ngắt kết nối") }
        case .reasserting:
            statusMessage = "Đang kết nối lại..."
        case .invalid:
            statusMessage = "Cấu hình không hợp lệ"
        @unknown default: break
        }
    }

    func connect(to server: ServerConfig, username: String, password: String) async {
        connectedServer = server
        addLog("⏳ Kết nối tới \(server.name) (\(server.host):\(server.port))...")
        addLog("👤 User: \(username)")
        do {
            let mgr = vpnManager ?? NETunnelProviderManager()
            let proto = NETunnelProviderProtocol()
            proto.providerBundleIdentifier = "com.doni.doniapp.vpn"
            proto.serverAddress = server.host
            proto.providerConfiguration = [
                "host":     server.host,
                "port":     server.port,
                "username": username,
                "password": password,
                "name":     server.name
            ]
            mgr.protocolConfiguration = proto
            mgr.localizedDescription = "DoniMods — \(server.name)"
            mgr.isEnabled = true
            try await mgr.saveToPreferences()
            try await mgr.loadFromPreferences()
            vpnManager = mgr
            try mgr.connection.startVPNTunnel()
        } catch {
            addLog("❌ Lỗi: \(error.localizedDescription)")
            statusMessage = error.localizedDescription
            connectedServer = nil
        }
    }

    func disconnect() {
        vpnManager?.connection.stopVPNTunnel()
        addLog("🔌 Đã ngắt kết nối")
    }

    func addLog(_ line: String) {
        let t = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        log.append("[\(t)] \(line)")
        if log.count > 80 { log.removeFirst() }
    }
    func clearLog() { log.removeAll() }

    var isConnected: Bool  { status == .connected }
    var isConnecting: Bool { status == .connecting || status == .reasserting }
    var statusColor: Color {
        switch status {
        case .connected:                 return .green
        case .connecting, .reasserting,
             .disconnecting:             return .orange
        default:                         return .gray
        }
    }
}

// MARK: - Main View

struct MainView: View {
    @EnvironmentObject private var session: SessionManager
    @ObservedObject private var vpn   = VPNManager.shared
    @ObservedObject private var creds = ProxyCredentials.shared

    @State private var selectedServer: ServerConfig? = nil
    @State private var showLogoutConfirm = false
    @State private var showLog   = false
    @State private var pulse     = false
    @State private var showPass  = false
    @FocusState private var focusField: CredField?

    enum CredField { case username, password }

    // Validation
    private var canConnect: Bool {
        selectedServer != nil &&
        !creds.username.trimmingCharacters(in: .whitespaces).isEmpty &&
        !creds.password.isEmpty
    }

    var body: some View {
        ZStack {
            background
            VStack(spacing: 0) {
                topBar
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        statusCircle
                        serverList
                        credentialsCard
                        connectButton
                        logSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 34)
                }
            }
        }
        .onAppear { pulse = true }
        .confirmationDialog("Đăng xuất?", isPresented: $showLogoutConfirm, titleVisibility: .visible) {
            Button("Đăng xuất", role: .destructive) { vpn.disconnect(); session.logout() }
            Button("Huỷ", role: .cancel) {}
        }
    }

    // MARK: Background
    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.03, green: 0.03, blue: 0.08), .black],
                startPoint: .top, endPoint: .bottom
            )
            Circle()
                .fill(vpn.statusColor.opacity(0.09))
                .frame(width: 320, height: 320)
                .blur(radius: 80)
                .offset(x: 50, y: -160)
                .animation(.easeInOut(duration: 0.8), value: vpn.statusColor)
        }
        .ignoresSafeArea()
    }

    // MARK: Top Bar
    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("DoniMods")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(LinearGradient(
                        colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing
                    ))
                Text("Hi, \(session.user?.username ?? "Player")")
                    .font(.system(size: 12)).foregroundStyle(.gray)
            }
            Spacer()
            Button { showLogoutConfirm = true } label: {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 15)).foregroundStyle(.gray)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Circle())
            }.buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 18)
    }

    // MARK: Status Circle
    private var statusCircle: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .stroke(vpn.statusColor.opacity(0.12), lineWidth: 22)
                    .frame(width: 150, height: 150)
                    .scaleEffect(pulse && vpn.isConnected ? 1.12 : 1.0)
                    .animation(
                        vpn.isConnected
                            ? .easeInOut(duration: 1.0).repeatForever(autoreverses: true)
                            : .easeInOut(duration: 0.3),
                        value: pulse
                    )
                Circle()
                    .stroke(vpn.statusColor.opacity(0.4), lineWidth: 1.5)
                    .frame(width: 130, height: 130)
                    .shadow(color: vpn.statusColor.opacity(0.5), radius: 10)
                Circle()
                    .fill(vpn.statusColor.opacity(0.08))
                    .frame(width: 120, height: 120)

                VStack(spacing: 7) {
                    Image(systemName: vpn.isConnected
                          ? "shield.lefthalf.filled"
                          : vpn.isConnecting
                            ? "arrow.trianglehead.2.clockwise.rotate.90"
                            : "shield.slash")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundStyle(vpn.statusColor)
                        .shadow(color: vpn.statusColor, radius: 8)
                        .rotationEffect(vpn.isConnecting ? .degrees(360) : .zero)
                        .animation(
                            vpn.isConnecting
                                ? .linear(duration: 1.0).repeatForever(autoreverses: false)
                                : .default,
                            value: vpn.isConnecting
                        )
                    Text(vpn.isConnecting ? "CONNECTING" : vpn.isConnected ? "PROTECTED" : "EXPOSED")
                        .font(.system(size: 9, weight: .black)).tracking(2)
                        .foregroundStyle(vpn.statusColor)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: vpn.status)

            Text(vpn.statusMessage)
                .font(.system(size: 12)).foregroundStyle(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 4).padding(.bottom, 2)
    }

    // MARK: Server List
    private var serverList: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("CHỌN SERVER")
                    .font(.system(size: 11, weight: .black)).tracking(2)
                    .foregroundStyle(.cyan.opacity(0.7))
                Spacer()
                if vpn.isConnected, let s = vpn.connectedServer {
                    HStack(spacing: 4) {
                        Circle().fill(Color.green).frame(width: 6, height: 6)
                            .shadow(color: .green, radius: 3)
                        Text(s.name)
                            .font(.system(size: 11, weight: .semibold)).foregroundStyle(.green)
                    }
                }
            }

            VStack(spacing: 0) {
                ForEach(predefinedServers) { server in
                    serverRow(server)
                    if server.id != predefinedServers.last?.id {
                        Divider().overlay(Color.white.opacity(0.07)).padding(.leading, 54)
                    }
                }
            }
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.cyan.opacity(0.13), lineWidth: 1)
            }
        }
    }

    @ViewBuilder
    private func serverRow(_ server: ServerConfig) -> some View {
        let isSelected = selectedServer?.id == server.id
        let isActive   = vpn.connectedServer?.id == server.id && vpn.isConnected

        Button {
            guard !vpn.isConnected else { return }
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedServer = isSelected ? nil : server
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(isActive   ? Color.green.opacity(0.18) :
                              isSelected ? Color.cyan.opacity(0.15)  : Color.white.opacity(0.06))
                        .frame(width: 40, height: 40)
                    Text(server.flag).font(.system(size: 20))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(server.name)
                        .font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
                    Text("\(server.host):\(server.port)")
                        .font(.system(size: 11, design: .monospaced)).foregroundStyle(.gray)
                }

                Spacer()

                if isActive {
                    Text("ACTIVE")
                        .font(.system(size: 9, weight: .black)).tracking(1).foregroundStyle(.green)
                } else if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18)).foregroundStyle(.cyan)
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 18)).foregroundStyle(.white.opacity(0.2))
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 13)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(vpn.isConnected && !isActive ? 0.4 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .animation(.easeInOut(duration: 0.2), value: isActive)
    }

    // MARK: Credentials Card
    private var credentialsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("XÁC THỰC PROXY")
                    .font(.system(size: 11, weight: .black)).tracking(2)
                    .foregroundStyle(.cyan.opacity(0.7))
                Spacer()
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 12)).foregroundStyle(.cyan.opacity(0.5))
            }

            VStack(spacing: 0) {
                // Username row
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.cyan.opacity(0.12)).frame(width: 34, height: 34)
                        Image(systemName: "person.fill")
                            .font(.system(size: 13)).foregroundStyle(.cyan)
                    }
                    TextField("", text: $creds.username,
                              prompt: Text("Tên đăng nhập").foregroundColor(.gray))
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                        .textContentType(.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                        .focused($focusField, equals: .username)
                        .onSubmit { focusField = .password }
                        .disabled(vpn.isConnected)
                }
                .padding(.horizontal, 14).padding(.vertical, 13)

                Divider().overlay(Color.white.opacity(0.07)).padding(.leading, 54)

                // Password row
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.purple.opacity(0.12)).frame(width: 34, height: 34)
                        Image(systemName: "key.fill")
                            .font(.system(size: 13)).foregroundStyle(.purple)
                    }
                    Group {
                        if showPass {
                            TextField("", text: $creds.password,
                                      prompt: Text("Mật khẩu").foregroundColor(.gray))
                        } else {
                            SecureField("", text: $creds.password,
                                        prompt: Text("Mật khẩu").foregroundColor(.gray))
                        }
                    }
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
                    .textContentType(.password)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .focused($focusField, equals: .password)
                    .onSubmit { focusField = nil }
                    .disabled(vpn.isConnected)

                    Button {
                        showPass.toggle()
                    } label: {
                        Image(systemName: showPass ? "eye.slash.fill" : "eye.fill")
                            .font(.system(size: 13)).foregroundStyle(.gray)
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                    .disabled(vpn.isConnected)
                }
                .padding(.horizontal, 14).padding(.vertical, 13)
            }
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.cyan.opacity(0.13), lineWidth: 1)
            }

            HStack(spacing: 5) {
                Image(systemName: "internaldrive.fill")
                    .font(.system(size: 10)).foregroundStyle(.gray.opacity(0.6))
                Text("Tên đăng nhập & mật khẩu được lưu tự động trên thiết bị.")
                    .font(.system(size: 11)).foregroundStyle(.gray.opacity(0.6))
            }
        }
    }

    // MARK: Connect Button
    private var connectButton: some View {
        Button {
            focusField = nil
            Task {
                if vpn.isConnected || vpn.isConnecting {
                    vpn.disconnect()
                } else if let server = selectedServer {
                    await vpn.connect(
                        to: server,
                        username: creds.username.trimmingCharacters(in: .whitespaces),
                        password: creds.password
                    )
                }
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: vpn.isConnected ? "poweroff" : "power")
                    .font(.system(size: 15, weight: .bold))
                Text(
                    vpn.isConnecting     ? "Đang kết nối..." :
                    vpn.isConnected      ? "Ngắt kết nối"    :
                    selectedServer == nil ? "Chọn server trước" :
                    !canConnect          ? "Nhập thông tin xác thực" : "Kết nối"
                )
                .font(.system(size: 15, weight: .bold))
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity).frame(height: 52)
            .background(
                vpn.isConnected
                    ? LinearGradient(colors: [.red.opacity(0.9), .red],
                                     startPoint: .leading, endPoint: .trailing)
                    : canConnect
                        ? LinearGradient(colors: [.cyan, .blue],
                                         startPoint: .leading, endPoint: .trailing)
                        : LinearGradient(colors: [.gray.opacity(0.35), .gray.opacity(0.25)],
                                         startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(
                color: vpn.isConnected ? Color.red.opacity(0.3) :
                       canConnect       ? Color.cyan.opacity(0.3) : .clear,
                radius: 10, y: 4
            )
        }
        .buttonStyle(.plain)
        .disabled(vpn.isConnecting || (!vpn.isConnected && !canConnect))
        .animation(.easeInOut(duration: 0.25), value: vpn.isConnected)
        .animation(.easeInOut(duration: 0.15), value: canConnect)
    }

    // MARK: Log Section
    private var logSection: some View {
        VStack(spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.22)) { showLog.toggle() }
            } label: {
                HStack {
                    Image(systemName: "terminal").font(.system(size: 12))
                    Text("Connection Log").font(.system(size: 13, weight: .semibold))
                    Spacer()
                    Image(systemName: showLog ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11))
                }
                .foregroundStyle(.cyan.opacity(0.75))
                .padding(13)
                .background(Color.cyan.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.cyan.opacity(0.18), lineWidth: 1)
                }
            }.buttonStyle(.plain)

            if showLog {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("LOG").font(.system(size: 10, weight: .black)).tracking(2).foregroundStyle(.gray)
                        Spacer()
                        Button("Clear") { vpn.clearLog() }
                            .font(.system(size: 11)).foregroundStyle(.gray).buttonStyle(.plain)
                    }
                    if vpn.log.isEmpty {
                        Text("Chưa có log.")
                            .font(.system(size: 12)).foregroundStyle(.gray.opacity(0.5))
                            .frame(maxWidth: .infinity, alignment: .center).padding(.vertical, 8)
                    } else {
                        ForEach(vpn.log.reversed(), id: \.self) { line in
                            Text(line)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.65))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(13)
                .background(Color.black.opacity(0.45))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.07), lineWidth: 1)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
