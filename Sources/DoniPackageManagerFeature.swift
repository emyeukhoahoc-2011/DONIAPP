import SwiftUI
import UniformTypeIdentifiers
import CryptoKit

// MARK: - Safe package library models

/// A user-assigned label only. It does not inspect or identify a game's internal data.
enum DoniPackageTarget: String, Codable, CaseIterable, Identifiable {
    case freeFire = "Free Fire"
    case freeFireMax = "Free Fire MAX"
    case unassigned = "Chưa gán"

    var id: String { rawValue }

    var tint: Color {
        switch self {
        case .freeFire: return .orange
        case .freeFireMax: return .cyan
        case .unassigned: return .gray
        }
    }
}

struct DoniManagedPackage: Codable, Identifiable, Equatable {
    let id: UUID
    let originalFilename: String
    let storedFilename: String
    var target: DoniPackageTarget
    let importedAt: Date
    let byteCount: Int64
    let sha256: String
}

private enum DoniPackageError: LocalizedError {
    case wrongExtension
    case notRegularFile
    case emptyFile
    case tooLarge
    case duplicate
    case missingFile

    var errorDescription: String? {
        switch self {
        case .wrongExtension: return "Chỉ nhận file có phần mở rộng .3105."
        case .notRegularFile: return "Mục được chọn không phải file thông thường."
        case .emptyFile: return "File rỗng nên không được nhập."
        case .tooLarge: return "File vượt quá giới hạn 512 MB."
        case .duplicate: return "Package này đã có trong thư viện (SHA-256 trùng)."
        case .missingFile: return "Không tìm thấy bản sao trong thư viện."
        }
    }
}

// MARK: - Local package store

@MainActor
final class DoniPackageManagerStore: ObservableObject {
    @Published private(set) var packages: [DoniManagedPackage] = []
    @Published var errorMessage: String?
    @Published var statusMessage: String?

    private let fileManager = FileManager.default
    private let maxFileSize: Int64 = 512 * 1024 * 1024

    private var rootURL: URL {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("DoniPackageManager", isDirectory: true)
    }

    private var packagesURL: URL {
        rootURL.appendingPathComponent("Packages", isDirectory: true)
    }

    private var indexURL: URL {
        rootURL.appendingPathComponent("packages-index.json", isDirectory: false)
    }

    init() {
        load()
    }

    func load() {
        do {
            try fileManager.createDirectory(at: packagesURL, withIntermediateDirectories: true)
            guard fileManager.fileExists(atPath: indexURL.path) else {
                packages = []
                return
            }
            let data = try Data(contentsOf: indexURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            packages = try decoder.decode([DoniManagedPackage].self, from: data)
                .filter { fileManager.fileExists(atPath: packagesURL.appendingPathComponent($0.storedFilename).path) }
                .sorted { $0.importedAt > $1.importedAt }
        } catch {
            errorMessage = "Không đọc được thư viện package: \(error.localizedDescription)"
        }
    }

    /// Imports only the original .3105 file into DONIAPP's own sandbox.
    /// It does not decode, modify, install, or apply any package payload.
    func importFiles(_ urls: [URL], target: DoniPackageTarget) {
        errorMessage = nil
        statusMessage = nil
        var succeeded = 0
        var failures: [String] = []

        for sourceURL in urls {
            do {
                try importOne(sourceURL, target: target)
                succeeded += 1
            } catch {
                failures.append("\(sourceURL.lastPathComponent): \(error.localizedDescription)")
            }
        }

        if succeeded > 0 {
            statusMessage = "Đã nhập \(succeeded) package vào thư viện DONIAPP."
        }
        if !failures.isEmpty {
            errorMessage = failures.prefix(3).joined(separator: "\n")
            if failures.count > 3 {
                errorMessage! += "\n… và \(failures.count - 3) file khác."
            }
        }
    }

    private func importOne(_ sourceURL: URL, target: DoniPackageTarget) throws {
        let didStartAccessing = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing { sourceURL.stopAccessingSecurityScopedResource() }
        }

        guard sourceURL.pathExtension.lowercased() == "3105" else {
            throw DoniPackageError.wrongExtension
        }

        let values = try sourceURL.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
        guard values.isRegularFile == true else { throw DoniPackageError.notRegularFile }
        let size = Int64(values.fileSize ?? 0)
        guard size > 0 else { throw DoniPackageError.emptyFile }
        guard size <= maxFileSize else { throw DoniPackageError.tooLarge }

        try fileManager.createDirectory(at: packagesURL, withIntermediateDirectories: true)
        let storedName = "\(UUID().uuidString).3105"
        let destinationURL = packagesURL.appendingPathComponent(storedName)
        try fileManager.copyItem(at: sourceURL, to: destinationURL)

        do {
            let digest = try Self.sha256(fileURL: destinationURL)
            guard !packages.contains(where: { $0.sha256 == digest }) else {
                try? fileManager.removeItem(at: destinationURL)
                throw DoniPackageError.duplicate
            }

            let item = DoniManagedPackage(
                id: UUID(),
                originalFilename: sourceURL.lastPathComponent,
                storedFilename: storedName,
                target: target,
                importedAt: Date(),
                byteCount: size,
                sha256: digest
            )

            let previous = packages
            packages.insert(item, at: 0)
            do {
                try saveIndex()
            } catch {
                packages = previous
                try? fileManager.removeItem(at: destinationURL)
                throw error
            }
        } catch {
            if fileManager.fileExists(atPath: destinationURL.path) {
                try? fileManager.removeItem(at: destinationURL)
            }
            throw error
        }
    }

    func setTarget(_ target: DoniPackageTarget, for item: DoniManagedPackage) {
        guard let index = packages.firstIndex(where: { $0.id == item.id }) else { return }
        let previous = packages[index].target
        packages[index].target = target
        do {
            try saveIndex()
            statusMessage = "Đã đổi nhãn thành \(target.rawValue)."
            errorMessage = nil
        } catch {
            packages[index].target = previous
            errorMessage = "Không lưu được nhãn package: \(error.localizedDescription)"
        }
    }

    func delete(_ item: DoniManagedPackage) {
        guard let existingIndex = packages.firstIndex(where: { $0.id == item.id }) else { return }
        let fileURL = packagesURL.appendingPathComponent(item.storedFilename)
        var updated = packages
        updated.remove(at: existingIndex)
        do {
            try persist(updated)
            packages = updated
            if fileManager.fileExists(atPath: fileURL.path) {
                try fileManager.removeItem(at: fileURL)
            }
            statusMessage = "Đã xoá bản sao package khỏi thư viện DONIAPP."
            errorMessage = nil
        } catch {
            errorMessage = "Không xoá được package: \(error.localizedDescription)"
            load()
        }
    }

    func fileURL(for item: DoniManagedPackage) -> URL? {
        let url = packagesURL.appendingPathComponent(item.storedFilename)
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    private func saveIndex() throws {
        try persist(packages)
    }

    private func persist(_ values: [DoniManagedPackage]) throws {
        try fileManager.createDirectory(at: rootURL, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(values)
        try data.write(to: indexURL, options: .atomic)
    }

    private static func sha256(fileURL: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: fileURL)
        defer { try? handle.close() }

        var hasher = SHA256()
        while true {
            guard let chunk = try handle.read(upToCount: 1024 * 1024), !chunk.isEmpty else { break }
            hasher.update(data: chunk)
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - DONIAPP UI

struct DoniPackageManagerView: View {
    @StateObject private var store = DoniPackageManagerStore()
    @State private var showingImporter = false
    @State private var selectedTarget: DoniPackageTarget = .unassigned
    @State private var searchText = ""
    @State private var packagePendingDelete: DoniManagedPackage?

    private var filteredPackages: [DoniManagedPackage] {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return store.packages
        }
        return store.packages.filter {
            $0.originalFilename.localizedCaseInsensitiveContains(searchText)
                || $0.target.rawValue.localizedCaseInsensitiveContains(searchText)
                || $0.sha256.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.025, green: 0.03, blue: 0.08), .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ).ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    importPanel

                    if let message = store.statusMessage {
                        messageBanner(message, isError: false)
                    }
                    if let message = store.errorMessage {
                        messageBanner(message, isError: true)
                    }

                    HStack {
                        Text("PACKAGE LIBRARY")
                            .font(.system(size: 10, weight: .black))
                            .tracking(2)
                            .foregroundStyle(.cyan.opacity(0.75))
                        Spacer()
                        Text("\(store.packages.count) FILE(S)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(.gray)
                    }

                    TextField("Tìm theo tên file, nhãn hoặc SHA-256", text: $searchText)
                        .font(.system(size: 13))
                        .padding(12)
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.08)))

                    if filteredPackages.isEmpty {
                        emptyState
                    } else {
                        LazyVStack(spacing: 10) {
                            ForEach(filteredPackages) { package in
                                packageCard(package)
                            }
                        }
                    }

                    Text("DONIAPP chỉ lưu bản sao, nhãn do bạn chọn và SHA-256 để phát hiện file trùng. Module này không xác minh payload bên trong và không áp dụng patch lên Free Fire/Free Fire MAX.")
                        .font(.system(size: 11))
                        .foregroundStyle(.gray)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.035))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(18)
            }
        }
        .navigationTitle("Package Manager")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.item],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                store.importFiles(urls, target: selectedTarget)
            case .failure(let error):
                store.errorMessage = "Không mở được file: \(error.localizedDescription)"
            }
        }
        .confirmationDialog(
            "Xoá package khỏi thư viện?",
            isPresented: Binding(
                get: { packagePendingDelete != nil },
                set: { if !$0 { packagePendingDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Xoá bản sao", role: .destructive) {
                if let item = packagePendingDelete { store.delete(item) }
                packagePendingDelete = nil
            }
            Button("Huỷ", role: .cancel) { packagePendingDelete = nil }
        } message: {
            Text("Thao tác chỉ xoá bản sao đang lưu trong DONIAPP, không xoá file gốc đã nhập.")
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 10) {
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.cyan)
                    .shadow(color: .cyan.opacity(0.5), radius: 8)
                VStack(alignment: .leading, spacing: 3) {
                    Text("DONI PACKAGE MANAGER")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Import · Organize · Export")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.gray)
                }
                Spacer()
            }
            Text("Quản lý các file .3105 do bạn chọn. Nhãn Free Fire/Free Fire MAX chỉ là nhãn tổ chức, không phải xác nhận package dành cho game đó.")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.65))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LinearGradient(colors: [.cyan.opacity(0.13), .blue.opacity(0.035)], startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.cyan.opacity(0.22), lineWidth: 1))
    }

    private var importPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("GÁN NHÃN KHI NHẬP")
                .font(.system(size: 10, weight: .black))
                .tracking(1.5)
                .foregroundStyle(.gray)

            Picker("Nhãn package", selection: $selectedTarget) {
                ForEach(DoniPackageTarget.allCases) { target in
                    Text(target.rawValue).tag(target)
                }
            }
            .pickerStyle(.menu)
            .tint(.cyan)
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                showingImporter = true
            } label: {
                Label("Nhập file .3105", systemImage: "square.and.arrow.down.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(LinearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing))
                    .clipShape(RoundedRectangle(cornerRadius: 11))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Color.white.opacity(0.045))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "tray")
                .font(.system(size: 30))
                .foregroundStyle(.cyan.opacity(0.75))
            Text(searchText.isEmpty ? "Chưa có package nào" : "Không tìm thấy package")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
            Text("Nhập file .3105 để tạo thư viện bản sao trong DONIAPP.")
                .font(.system(size: 11))
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .background(Color.white.opacity(0.035))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func packageCard(_ package: DoniManagedPackage) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "doc.zipper")
                    .font(.system(size: 20))
                    .foregroundStyle(package.target.tint)
                    .frame(width: 38, height: 38)
                    .background(package.target.tint.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 4) {
                    Text(package.originalFilename)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .textSelection(.enabled)
                    Text("\(ByteCountFormatter.string(fromByteCount: package.byteCount, countStyle: .file)) · \(package.importedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.system(size: 10))
                        .foregroundStyle(.gray)
                }
                Spacer(minLength: 2)

                Menu {
                    ForEach(DoniPackageTarget.allCases) { target in
                        Button {
                            store.setTarget(target, for: package)
                        } label: {
                            if target == package.target {
                                Label(target.rawValue, systemImage: "checkmark")
                            } else {
                                Text(target.rawValue)
                            }
                        }
                    }
                } label: {
                    Text(package.target.rawValue)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(package.target.tint)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(package.target.tint.opacity(0.12))
                        .clipShape(Capsule())
                }
            }

            HStack(spacing: 6) {
                Image(systemName: "number")
                    .foregroundStyle(.gray)
                Text(String(package.sha256.prefix(20)) + "…")
                    .foregroundStyle(.gray)
                    .textSelection(.enabled)
                    .lineLimit(1)
                Spacer(minLength: 4)
                if let url = store.fileURL(for: package) {
                    ShareLink(item: url, preview: SharePreview(package.originalFilename)) {
                        Label("Xuất", systemImage: "square.and.arrow.up")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.cyan)
                    }
                    .buttonStyle(.plain)
                }
                Button(role: .destructive) {
                    packagePendingDelete = package
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.red.opacity(0.9))
                        .padding(.leading, 4)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Xoá bản sao \(package.originalFilename)")
            }
            .font(.system(size: 10, design: .monospaced))

            Text("SHA-256 dùng để so sánh file trùng, không phải kết quả xác minh nguồn gốc hay tính an toàn của package.")
                .font(.system(size: 9))
                .foregroundStyle(.gray.opacity(0.8))
        }
        .padding(13)
        .background(Color.white.opacity(0.045))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(package.target.tint.opacity(0.20), lineWidth: 1))
    }

    private func messageBanner(_ message: String, isError: Bool) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: isError ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                .foregroundStyle(isError ? .red : .green)
            Text(message)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background((isError ? Color.red : Color.green).opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke((isError ? Color.red : Color.green).opacity(0.22), lineWidth: 1))
    }
}
