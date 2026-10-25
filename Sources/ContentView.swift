import SwiftUI
import QuartzCore

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

// MARK: - Network Manager

@MainActor
final class NetworkManager: ObservableObject {
    @Published private(set) var isConnected = false
    @Published private(set) var isConnecting = false
    @Published private(set) var statusMessage = "Chưa kết nối"
    @Published private(set) var statusColor: Color = .gray
    @Published private(set) var log: [String] = []

    private var inputStream: InputStream?
    private var outputStream: OutputStream?

    let host: String
    let port: Int

    init(host: String = "1123.123.123.123", port: Int = 1233) {
        self.host = host
        self.port = port
    }

    func connect() {
        guard !isConnected, !isConnecting else { return }
        isConnecting = true
        statusMessage = "Đang kết nối..."
        statusColor = .orange
        addLog("⏳ Đang kết nối tới \(host):\(port)...")

        var readStream: Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?
        CFStreamCreatePairWithSocketToHost(
            nil,
            host as CFString,
            UInt32(port),
            &readStream,
            &writeStream
        )

        guard let rs = readStream?.takeRetainedValue(),
              let ws = writeStream?.takeRetainedValue() else {
            setFailed("Không tạo được stream")
            return
        }

        inputStream  = rs as InputStream
        outputStream = ws as OutputStream
        inputStream?.open()
        outputStream?.open()

        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            await checkConnection()
        }
    }

    private func checkConnection() async {
        guard let out = outputStream else { setFailed("Không có stream"); return }
        isConnecting = false
        if out.streamStatus == .open || out.streamStatus == .writing {
            isConnected = true
            statusMessage = "Đã kết nối · \(host):\(port)"
            statusColor = .green
            addLog("✅ Kết nối thành công!")
        } else {
            let reason = out.streamError?.localizedDescription ?? "Server từ chối kết nối"
            setFailed(reason)
        }
    }

    func disconnect() {
        inputStream?.close()
        outputStream?.close()
        inputStream  = nil
        outputStream = nil
        isConnected  = false
        isConnecting = false
        statusMessage = "Đã ngắt kết nối"
        statusColor   = .gray
        addLog("🔌 Đã ngắt kết nối")
    }

    func toggle() {
        if isConnected || isConnecting { disconnect() } else { connect() }
    }

    private func setFailed(_ reason: String) {
        isConnected  = false
        isConnecting = false
        statusMessage = reason
        statusColor   = .red
        addLog("❌ Lỗi: \(reason)")
        inputStream?.close(); outputStream?.close()
        inputStream  = nil;  outputStream  = nil
    }

    private func addLog(_ line: String) {
        let time = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        log.append("[\(time)] \(line)")
        if log.count > 50 { log.removeFirst() }
    }

    func clearLog() { log.removeAll() }
}

// MARK: - Main View (Network Only)

struct MainView: View {
    @EnvironmentObject private var session: SessionManager
    @StateObject private var network = NetworkManager()
    @State private var pulse = false
    @State private var showLog = false
    @State private var showLogoutConfirm = false

    private var statusIcon: String {
        if network.isConnecting { return "arrow.trianglehead.2.clockwise.rotate.90" }
        return network.isConnected
            ? "antenna.radiowaves.left.and.right"
            : "antenna.radiowaves.left.and.right.slash"
    }

    var body: some View {
        ZStack {
            // Background
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.03, green: 0.03, blue: 0.08), .black],
                    startPoint: .top, endPoint: .bottom
                )
                Circle()
                    .fill(network.statusColor.opacity(0.08))
                    .frame(width: 300, height: 300)
                    .blur(radius: 80)
                    .offset(x: 60, y: -140)
                    .animation(.easeInOut(duration: 1.0), value: network.statusColor)
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("DoniMods")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(colors: [.cyan, .blue],
                                               startPoint: .leading, endPoint: .trailing)
                            )
                        Text("Hi, \(session.user?.username ?? "Player")")
                            .font(.system(size: 12))
                            .foregroundStyle(.gray)
                    }
                    Spacer()
                    Button {
                        showLogoutConfirm = true
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 16))
                            .foregroundStyle(.gray)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 20)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {

                        // Big Status Circle
                        ZStack {
                            // Outer pulse ring
                            Circle()
                                .stroke(network.statusColor.opacity(0.15), lineWidth: 20)
                                .frame(width: 180, height: 180)
                                .scaleEffect(pulse && network.isConnected ? 1.15 : 1.0)
                                .animation(
                                    network.isConnected
                                        ? .easeInOut(duration: 1.1).repeatForever(autoreverses: true)
                                        : .easeInOut(duration: 0.4),
                                    value: pulse
                                )

                            // Mid ring
                            Circle()
                                .stroke(network.statusColor.opacity(0.3), lineWidth: 2)
                                .frame(width: 160, height: 160)
                                .shadow(color: network.statusColor.opacity(0.6), radius: 12)

                            // Fill
                            Circle()
                                .fill(network.statusColor.opacity(0.1))
                                .frame(width: 148, height: 148)

                            // Icon
                            VStack(spacing: 8) {
                                Image(systemName: statusIcon)
                                    .font(.system(size: 42, weight: .medium))
                                    .foregroundStyle(network.statusColor)
                                    .shadow(color: network.statusColor, radius: 10)
                                    .rotationEffect(network.isConnecting ? .degrees(360) : .zero)
                                    .animation(
                                        network.isConnecting
                                            ? .linear(duration: 1.0).repeatForever(autoreverses: false)
                                            : .default,
                                        value: network.isConnecting
                                    )

                                Text(network.isConnecting ? "CONNECTING" :
                                     network.isConnected  ? "ONLINE" : "OFFLINE")
                                    .font(.system(size: 10, weight: .black))
                                    .tracking(2)
                                    .foregroundStyle(network.statusColor)
                            }
                        }
                        .padding(.vertical, 10)
                        .animation(.easeInOut(duration: 0.4), value: network.isConnected)

                        // Status message
                        Text(network.statusMessage)
                            .font(.system(size: 13))
                            .foregroundStyle(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)

                        // Big Toggle Button
                        Button {
                            network.toggle()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: network.isConnected ? "poweroff" : "power")
                                    .font(.system(size: 16, weight: .bold))
                                Text(network.isConnecting ? "Đang kết nối..." :
                                     network.isConnected  ? "Ngắt kết nối" : "Kết nối")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .foregroundStyle(network.isConnected ? .black : .black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                network.isConnected
                                    ? LinearGradient(colors: [.red.opacity(0.9), .red],
                                                     startPoint: .leading, endPoint: .trailing)
                                    : LinearGradient(colors: [.cyan, .blue],
                                                     startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(
                                color: (network.isConnected ? Color.red : Color.cyan).opacity(0.4),
                                radius: 12, y: 4
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(network.isConnecting)
                        .padding(.horizontal, 4)
                        .animation(.easeInOut(duration: 0.3), value: network.isConnected)

                        // Server Info Card
                        VStack(spacing: 0) {
                            infoRow(
                                icon: "server.rack", iconColor: .cyan,
                                label: "Host", value: network.host
                            )
                            Divider().overlay(Color.white.opacity(0.07)).padding(.leading, 54)
                            infoRow(
                                icon: "network", iconColor: .purple,
                                label: "Port", value: "\(network.port)"
                            )
                            Divider().overlay(Color.white.opacity(0.07)).padding(.leading, 54)
                            infoRow(
                                icon: "lock.shield.fill", iconColor: .orange,
                                label: "Protocol", value: "TCP"
                            )
                        }
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.cyan.opacity(0.13), lineWidth: 1)
                        }

                        // Log toggle
                        Button {
                            withAnimation(.easeInOut(duration: 0.25)) { showLog.toggle() }
                        } label: {
                            HStack {
                                Image(systemName: "terminal")
                                    .font(.system(size: 13))
                                Text("Connection Log")
                                    .font(.system(size: 13, weight: .semibold))
                                Spacer()
                                Image(systemName: showLog ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 11))
                            }
                            .foregroundStyle(.cyan.opacity(0.8))
                            .padding(14)
                            .background(Color.cyan.opacity(0.05))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.cyan.opacity(0.2), lineWidth: 1)
                            }
                        }
                        .buttonStyle(.plain)

                        if showLog {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("LOG")
                                        .font(.system(size: 10, weight: .black))
                                        .tracking(2)
                                        .foregroundStyle(.gray)
                                    Spacer()
                                    Button("Clear") { network.clearLog() }
                                        .font(.system(size: 11))
                                        .foregroundStyle(.gray)
                                        .buttonStyle(.plain)
                                }
                                if network.log.isEmpty {
                                    Text("Chưa có log nào.")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.gray.opacity(0.6))
                                        .frame(maxWidth: .infinity, alignment: .center)
                                        .padding(.vertical, 10)
                                } else {
                                    ForEach(network.log.reversed(), id: \.self) { line in
                                        Text(line)
                                            .font(.system(size: 11, design: .monospaced))
                                            .foregroundStyle(.white.opacity(0.7))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }
                            }
                            .padding(14)
                            .background(Color.black.opacity(0.4))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.07), lineWidth: 1)
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
        }
        .onAppear { pulse = true }
        .confirmationDialog("Đăng xuất khỏi DoniMods?", isPresented: $showLogoutConfirm, titleVisibility: .visible) {
            Button("Đăng xuất", role: .destructive) {
                network.disconnect()
                session.logout()
            }
            Button("Huỷ", role: .cancel) {}
        }
    }

    @ViewBuilder
    private func infoRow(icon: String, iconColor: Color, label: String, value: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(iconColor)
            }
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(.gray)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
