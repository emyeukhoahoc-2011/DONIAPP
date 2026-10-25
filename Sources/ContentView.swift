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

// MARK: - Patch Model

struct PatchEntry: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let fileName: String       // Tên file .3105 trong Sources/
    let targetBundleID: String
    let icon: String
    let color: Color
}

struct PatchGroup: Identifiable {
    let id = UUID()
    let title: String          // Tên nhóm hiển thị
    let subtitle: String       // Mô tả nhóm
    let icon: String
    let color: Color
    let patches: [PatchEntry]
}

// ── Danh sách nhóm patch ──────────────────────────────────────────────────
// Thêm file .3105 vào Sources/ rồi khai báo ở đây.
let patchGroups: [PatchGroup] = [

    PatchGroup(
        title:    "FFTH",
        subtitle: "Free Fire Thường ",
        icon:     "flame.fill",
        color:    .orange,
        patches: [
            PatchEntry(
                name:           "AIM NECK",
                description:    "<<<>>>",
                fileName:       "NECKTH.3105",
                targetBundleID: "com.dts.freefireth",
                icon:           "bolt.fill",
                color:          .orange
            ),
            // Thêm patch FFTH ở đây ↑
        ]
    ),

    PatchGroup(
        title:    "FFMX",
        subtitle: "Free Fire Max",
        icon:     "sparkles",
        color:    .purple,
        patches: [
            PatchEntry(
                name:           "AIM NECK",
                description:    "<<<>>>",
                fileName:       "NECKMAX.3105",
                targetBundleID: "com.dts.freefiremax",
                icon:           "bolt.fill",
                color:          .purple
            ),
            // Thêm patch FFMX ở đây ↑
        ]
    ),

]

// MARK: - Patch State (per patch)

enum PatchStatus: Equatable {
    case idle
    case applying
    case applied
    case restoring
    case error(String)
}

// MARK: - .3105 Engine
//
// File .3105 là ZIP chứa cây thư mục với path tuyệt đối, ví dụ:
//   var/mobile/Containers/Data/Application/<UUID>/Documents/config.plist
//
// Engine sẽ:
//   1. Giải nén .3105 ra thư mục tạm
//   2. Duyệt toàn bộ file bên trong
//   3. Với mỗi file: strip prefix "var/mobile/Containers/Data/Application/<UUID>"
//      → lấy path tương đối trong container
//   4. Resolve UUID thật trên máy từ bundle ID
//   5. Backup file gốc → ghi đè file mới
//
// Để giải nén ZIP trên iOS, dùng ZipFoundation (SPM package).
// Thêm vào project.yml:
//   packages:
//     ZipFoundation:
//       url: https://github.com/weichsel/ZIPFoundation
//       exactVersion: "0.9.19"
// Rồi thêm vào target:
//   dependencies:
//     - package: ZipFoundation

import Foundation
import ZIPFoundation

@MainActor
final class PatchEngine: ObservableObject {
    static let shared = PatchEngine()
    private init() {}

    @Published var statuses: [String: PatchStatus] = [:]
    @Published var log: [String] = []

    // Backup lưu trong Documents/DoniBackups/<patchFileName>/<relative path>
    private var backupRoot: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("DoniBackups", isDirectory: true)
    }

    // ── Apply ──────────────────────────────────────────────────────────────
    func apply(_ patch: PatchEntry) async {
        setStatus(patch, .applying)
        addLog("▶ Áp dụng \(patch.name)...")

        do {
            // 1. Tìm file .3105 trong app bundle
            let name = (patch.fileName as NSString).deletingPathExtension
            let ext  = (patch.fileName as NSString).pathExtension
            guard let bundleURL = Bundle.main.url(forResource: name, withExtension: ext) else {
                throw PatchError.bundleFileNotFound(patch.fileName)
            }
            addLog("📦 Tìm thấy: \(patch.fileName)")

            // 2. Giải nén ZIP vào thư mục tạm
            let tmpDir = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString, isDirectory: true)
            try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: tmpDir) }

            try extractZip(at: bundleURL, to: tmpDir)
            addLog("📂 Giải nén xong")

            // 3. Resolve UUID container từ bundle ID
            let containerUUID = try resolveContainerUUID(bundleID: patch.targetBundleID)
            let containerRoot = URL(fileURLWithPath: "/var/mobile/Containers/Data/Application")
                .appendingPathComponent(containerUUID)
            addLog("🔍 Container: \(containerUUID)")

            // 4. Enumerate tất cả file trong tmpDir
            //    Path trong ZIP dạng: var/mobile/Containers/Data/Application/<UUID>/xxx/yyy
            //    → tách lấy phần sau UUID → đó là relative path trong container
            let fm = FileManager.default
            guard let enumerator = fm.enumerator(
                at: tmpDir,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            ) else { throw PatchError.cannotEnumerate }

            var applied = 0
            let containerPrefix = "var/mobile/Containers/Data/Application/"

            while let srcURL = enumerator.nextObject() as? URL {
                guard (try? srcURL.resourceValues(forKeys: [.isRegularFileKey]))?.isRegularFile == true
                else { continue }

                // Lấy path tương đối so với tmpDir
                var relPath = srcURL.path
                    .replacingOccurrences(of: tmpDir.path + "/", with: "")

                // Strip "var/mobile/Containers/Data/Application/<UUID>/"
                if relPath.hasPrefix(containerPrefix) {
                    let afterPrefix = String(relPath.dropFirst(containerPrefix.count))
                    // afterPrefix = "<UUID>/Documents/..." → bỏ UUID đầu
                    if let slashIdx = afterPrefix.firstIndex(of: "/") {
                        relPath = String(afterPrefix[afterPrefix.index(after: slashIdx)...])
                    } else {
                        continue // chỉ là folder UUID, không phải file
                    }
                }
                // Nếu không có prefix container thì dùng thẳng relPath
                // (trường hợp .3105 chỉ chứa path tương đối)

                let destURL = containerRoot.appendingPathComponent(relPath)

                // Backup file gốc (chỉ lần đầu)
                if fm.fileExists(atPath: destURL.path) {
                    try backupFile(at: destURL, patchFileName: patch.fileName, relativePath: relPath)
                }

                // Tạo thư mục cha nếu cần
                let parentDir = destURL.deletingLastPathComponent()
                if !fm.fileExists(atPath: parentDir.path) {
                    try fm.createDirectory(at: parentDir, withIntermediateDirectories: true)
                }

                // Ghi đè
                if fm.fileExists(atPath: destURL.path) {
                    try fm.removeItem(at: destURL)
                }
                try fm.copyItem(at: srcURL, to: destURL)
                addLog("✅ \(relPath)")
                applied += 1
            }

            guard applied > 0 else { throw PatchError.noFilesFound }
            addLog("🎉 Đã ghi đè \(applied) file.")
            setStatus(patch, .applied)

        } catch {
            addLog("❌ \(error.localizedDescription)")
            setStatus(patch, .error(error.localizedDescription))
        }
    }

    // ── Restore ────────────────────────────────────────────────────────────
    func restore(_ patch: PatchEntry) async {
        setStatus(patch, .restoring)
        addLog("↩ Khôi phục \(patch.name)...")

        do {
            let containerUUID = try resolveContainerUUID(bundleID: patch.targetBundleID)
            let containerRoot = URL(fileURLWithPath: "/var/mobile/Containers/Data/Application")
                .appendingPathComponent(containerUUID)

            let patchBackupDir = backupRoot.appendingPathComponent(patch.fileName, isDirectory: true)
            guard FileManager.default.fileExists(atPath: patchBackupDir.path) else {
                throw PatchError.noBackupFound
            }

            let fm = FileManager.default
            guard let enumerator = fm.enumerator(
                at: patchBackupDir,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            ) else { throw PatchError.cannotEnumerate }

            var restored = 0
            while let bakURL = enumerator.nextObject() as? URL {
                guard (try? bakURL.resourceValues(forKeys: [.isRegularFileKey]))?.isRegularFile == true
                else { continue }

                let relPath = bakURL.path
                    .replacingOccurrences(of: patchBackupDir.path + "/", with: "")
                let destURL = containerRoot.appendingPathComponent(relPath)

                if fm.fileExists(atPath: destURL.path) {
                    try fm.removeItem(at: destURL)
                }
                let parentDir = destURL.deletingLastPathComponent()
                if !fm.fileExists(atPath: parentDir.path) {
                    try fm.createDirectory(at: parentDir, withIntermediateDirectories: true)
                }
                try fm.copyItem(at: bakURL, to: destURL)
                addLog("↩ \(relPath)")
                restored += 1
            }

            try? fm.removeItem(at: patchBackupDir)
            addLog("✅ Đã khôi phục \(restored) file.")
            setStatus(patch, .idle)

        } catch {
            addLog("❌ \(error.localizedDescription)")
            setStatus(patch, .error(error.localizedDescription))
        }
    }

    // ── ZIP Extraction ─────────────────────────────────────────────────────
    private func extractZip(at src: URL, to dst: URL) throws {
        // .3105 là file ZIP — dùng ZIPFoundation để giải nén
        try FileManager.default.unzipItem(at: src, to: dst)
    }

    // ── Resolve container UUID từ bundle ID ───────────────────────────────
    private func resolveContainerUUID(bundleID: String) throws -> String {
        let appsRoot = URL(fileURLWithPath: "/var/mobile/Containers/Data/Application")
        let uuids = try FileManager.default.contentsOfDirectory(
            at: appsRoot, includingPropertiesForKeys: nil
        )
        for uuidURL in uuids {
            let metaURL = uuidURL
                .appendingPathComponent(".com.apple.mobile_container_manager.metadata.plist")
            if let dict = NSDictionary(contentsOf: metaURL),
               let id = dict["MCMMetadataIdentifier"] as? String,
               id == bundleID {
                return uuidURL.lastPathComponent
            }
        }
        throw PatchError.containerNotFound(bundleID)
    }

    // ── Backup ────────────────────────────────────────────────────────────
    private func backupFile(at url: URL, patchFileName: String, relativePath: String) throws {
        let dest = backupRoot
            .appendingPathComponent(patchFileName, isDirectory: true)
            .appendingPathComponent(relativePath)
        guard !FileManager.default.fileExists(atPath: dest.path) else { return } // đã backup rồi
        let parentDir = dest.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: parentDir.path) {
            try FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true)
        }
        try FileManager.default.copyItem(at: url, to: dest)
    }

    // ── Helpers ───────────────────────────────────────────────────────────
    private func setStatus(_ patch: PatchEntry, _ s: PatchStatus) { statuses[patch.fileName] = s }
    func status(for patch: PatchEntry) -> PatchStatus { statuses[patch.fileName] ?? .idle }
    func hasBackup(for patch: PatchEntry) -> Bool {
        FileManager.default.fileExists(atPath:
            backupRoot.appendingPathComponent(patch.fileName).path)
    }
    func addLog(_ line: String) {
        let t = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        log.append("[\(t)] \(line)")
        if log.count > 100 { log.removeFirst() }
    }
    func clearLog() { log.removeAll() }
}

// MARK: - Patch Errors

enum PatchError: LocalizedError {
    case bundleFileNotFound(String)
    case containerNotFound(String)
    case noBackupFound
    case noFilesFound
    case cannotEnumerate

    var errorDescription: String? {
        switch self {
        case .bundleFileNotFound(let f): return "Không tìm thấy \(f) trong app bundle"
        case .containerNotFound(let id): return "Không tìm thấy container của \(id) — app chưa cài?"
        case .noBackupFound:             return "Không có backup để khôi phục"
        case .noFilesFound:              return "Không tìm thấy file nào trong .3105"
        case .cannotEnumerate:           return "Không duyệt được thư mục tạm"
        }
    }
}

// MARK: - Main View

struct MainView: View {
    @EnvironmentObject private var session: SessionManager
    @ObservedObject private var engine = PatchEngine.shared
    @State private var showLogoutConfirm = false
    @State private var showLog = false

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(red: 0.04, green: 0.04, blue: 0.09), .black],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            // Glow
            Circle()
                .fill(Color.cyan.opacity(0.07))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: 60, y: -180)
                .allowsHitTesting(false)

            VStack(spacing: 0) {
                topBar

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        // Groups
                        ForEach(patchGroups) { group in
                            PatchGroupSection(group: group)
                        }

                        // Log
                        logSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 34)
                }
            }
        }
        .confirmationDialog("Đăng xuất?", isPresented: $showLogoutConfirm, titleVisibility: .visible) {
            Button("Đăng xuất", role: .destructive) { session.logout() }
            Button("Huỷ", role: .cancel) {}
        }
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
        .padding(.horizontal, 24).padding(.top, 16).padding(.bottom, 18)
    }

    // MARK: Log Section
    private var logSection: some View {
        VStack(spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.22)) { showLog.toggle() }
            } label: {
                HStack {
                    Image(systemName: "terminal").font(.system(size: 12))
                    Text("Log").font(.system(size: 13, weight: .semibold))
                    Spacer()
                    if !engine.log.isEmpty {
                        Text("\(engine.log.count)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 7).padding(.vertical, 2)
                            .background(Color.cyan)
                            .clipShape(Capsule())
                    }
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
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("LOG").font(.system(size: 10, weight: .black)).tracking(2).foregroundStyle(.gray)
                        Spacer()
                        Button("Xoá") { engine.clearLog() }
                            .font(.system(size: 11)).foregroundStyle(.gray).buttonStyle(.plain)
                    }
                    if engine.log.isEmpty {
                        Text("Chưa có log.")
                            .font(.system(size: 12)).foregroundStyle(.gray.opacity(0.5))
                            .frame(maxWidth: .infinity, alignment: .center).padding(.vertical, 8)
                    } else {
                        ForEach(engine.log.reversed(), id: \.self) { line in
                            Text(line)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.7))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding(13)
                .background(Color.black.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.07), lineWidth: 1)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Patch Group Section

struct PatchGroupSection: View {
    let group: PatchGroup
    @State private var collapsed = false

    var appliedCount: Int {
        group.patches.filter { PatchEngine.shared.hasBackup(for: $0) }.count
    }

    var body: some View {
        VStack(spacing: 10) {
            // Group header — tap để thu gọn
            Button {
                withAnimation(.easeInOut(duration: 0.25)) { collapsed.toggle() }
            } label: {
                HStack(spacing: 12) {
                    // Group icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(group.color.opacity(0.18))
                            .frame(width: 38, height: 38)
                        Image(systemName: group.icon)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(group.color)
                            .shadow(color: group.color.opacity(0.5), radius: 4)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(group.title)
                            .font(.system(size: 16, weight: .black))
                            .foregroundStyle(.white)
                        Text(group.subtitle)
                            .font(.system(size: 11))
                            .foregroundStyle(.gray)
                    }

                    Spacer()

                    // Badge số patch đã áp dụng
                    if appliedCount > 0 {
                        Text("\(appliedCount)/\(group.patches.count)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(group.color)
                            .clipShape(Capsule())
                    } else {
                        Text("\(group.patches.count) patch")
                            .font(.system(size: 11))
                            .foregroundStyle(.gray)
                    }

                    Image(systemName: collapsed ? "chevron.right" : "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.gray)
                }
                .padding(.horizontal, 14).padding(.vertical, 12)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(group.color.opacity(0.2), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)

            // Patch cards (collapsible)
            if !collapsed {
                VStack(spacing: 10) {
                    ForEach(group.patches) { patch in
                        PatchCard(patch: patch)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - Patch Card

struct PatchCard: View {
    let patch: PatchEntry
    @ObservedObject private var engine = PatchEngine.shared
    @State private var showConfirmApply   = false
    @State private var showConfirmRestore = false

    private var status: PatchStatus { engine.status(for: patch) }
    private var hasBackup: Bool     { engine.hasBackup(for: patch) }

    private var isApplied: Bool {
        if case .applied = status { return true }
        // Coi như applied nếu đã có backup (persist qua relaunch)
        return hasBackup
    }
    private var isBusy: Bool {
        status == .applying || status == .restoring
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top row: icon + info
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(patch.color.opacity(0.15))
                        .frame(width: 50, height: 50)
                    Image(systemName: patch.icon)
                        .font(.system(size: 22))
                        .foregroundStyle(patch.color)
                        .shadow(color: patch.color.opacity(0.5), radius: 6)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(patch.name)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                        if isApplied {
                            Text("ĐÃ ÁP DỤNG")
                                .font(.system(size: 9, weight: .black)).tracking(1)
                                .foregroundStyle(.black)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color.green)
                                .clipShape(Capsule())
                        }
                    }
                    Text(patch.description)
                        .font(.system(size: 12)).foregroundStyle(.gray)
                    Text(patch.fileName)
                        .font(.system(size: 10, design: .monospaced)).foregroundStyle(.gray.opacity(0.5))
                }

                Spacer()

                // Busy spinner
                if isBusy {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.cyan)
                        .scaleEffect(0.85)
                }
            }
            .padding(16)

            // Error banner
            if case .error(let msg) = status {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12)).foregroundStyle(.red)
                    Text(msg)
                        .font(.system(size: 11)).foregroundStyle(.red.opacity(0.9))
                        .lineLimit(2)
                    Spacer()
                }
                .padding(.horizontal, 16).padding(.bottom, 10)
            }

            Divider().overlay(Color.white.opacity(0.07))

            // Action buttons
            HStack(spacing: 0) {
                // Apply button
                Button {
                    showConfirmApply = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 14))
                        Text(isApplied ? "Áp dụng lại" : "Áp dụng")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(isBusy ? .gray : .cyan)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                }
                .buttonStyle(.plain)
                .disabled(isBusy)

                // Divider
                Rectangle()
                    .fill(Color.white.opacity(0.07))
                    .frame(width: 1, height: 28)

                // Restore button
                Button {
                    showConfirmRestore = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.uturn.backward.circle.fill")
                            .font(.system(size: 14))
                        Text("Khôi phục")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(isBusy || !isApplied ? .gray.opacity(0.4) : .orange)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                }
                .buttonStyle(.plain)
                .disabled(isBusy || !isApplied)
            }
        }
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    isApplied ? Color.green.opacity(0.35) : Color.white.opacity(0.08),
                    lineWidth: 1
                )
        }
        .shadow(color: isApplied ? Color.green.opacity(0.1) : .clear, radius: 10)
        .animation(.easeInOut(duration: 0.25), value: isApplied)
        .confirmationDialog(
            "Áp dụng \"\(patch.name)\"?",
            isPresented: $showConfirmApply,
            titleVisibility: .visible
        ) {
            Button("Áp dụng", role: .none) {
                Task { await PatchEngine.shared.apply(patch) }
            }
            Button("Huỷ", role: .cancel) {}
        } message: {
            Text("File gốc sẽ được backup tự động trước khi ghi đè.")
        }
        .confirmationDialog(
            "Khôi phục \"\(patch.name)\"?",
            isPresented: $showConfirmRestore,
            titleVisibility: .visible
        ) {
            Button("Khôi phục file gốc", role: .destructive) {
                Task { await PatchEngine.shared.restore(patch) }
            }
            Button("Huỷ", role: .cancel) {}
        } message: {
            Text("File đã patch sẽ bị thay bằng bản backup gốc.")
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
