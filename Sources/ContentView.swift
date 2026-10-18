
import SwiftUI

// MARK: - App Root

struct ContentView: View {
    @State private var showSplash = true
    @State private var selectedTab: AppTab = .home

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            MainTabView(selectedTab: $selectedTab)
                .opacity(showSplash ? 0 : 1)

            if showSplash {
                SplashView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .preferredColorScheme(.dark)
        .task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)

            withAnimation(.easeInOut(duration: 0.45)) {
                showSplash = false
            }
        }
    }
}

// MARK: - Tabs

enum AppTab: String, CaseIterable {
    case home = "Home"
    case tools = "Tools"
    case profile = "Profile"
    case settings = "Settings"

    var icon: String {
        switch self {
        case .home: return "house"
        case .tools: return "square.grid.2x2"
        case .profile: return "person.crop.circle"
        case .settings: return "gearshape"
        }
    }
}

struct MainTabView: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }
                .tag(AppTab.home)

            ToolsView()
                .tabItem {
                    Label("Tools", systemImage: "square.grid.2x2")
                }
                .tag(AppTab.tools)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
                .tag(AppTab.profile)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(AppTab.settings)
        }
        .tint(.white)
    }
}

// MARK: - Splash Screen

struct SplashView: View {
    @State private var animateLogo = false

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.12)
                .ignoresSafeArea()

            VStack(spacing: 13) {
                Text("DoniMods")
                    .font(.system(size: 36, weight: .semibold, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 17)
                    .background {
                        RoundedRectangle(cornerRadius: 22)
                            .fill(.ultraThinMaterial)
                            .overlay {
                                RoundedRectangle(cornerRadius: 22)
                                    .stroke(
                                        .white.opacity(0.22),
                                        lineWidth: 1
                                    )
                            }
                    }
                    .shadow(color: .white.opacity(0.08), radius: 24)

                Text("WELCOME")
                    .font(.system(size: 10, weight: .medium))
                    .tracking(5)
                    .foregroundStyle(.white.opacity(0.48))
            }
            .scaleEffect(animateLogo ? 1 : 0.94)
            .opacity(animateLogo ? 1 : 0)
            .onAppear {
                withAnimation(.easeOut(duration: 0.65)) {
                    animateLogo = true
                }
            }
        }
        .statusBarHidden(true)
    }
}

// MARK: - Home

struct HomeView: View {
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        // Welcome heading
                        VStack(alignment: .leading, spacing: 8) {
                            Text("DONIMODS")
                                .font(.system(size: 11, weight: .semibold))
                                .tracking(3)
                                .foregroundStyle(.secondary)

                            Text("Welcome back.")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundStyle(.white)
                                .minimumScaleFactor(0.8)
                                .lineLimit(1)

                            Text("Your gaming companion.")
                                .font(.system(size: 15))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        // Main app card
                        HStack(spacing: 14) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 23, weight: .medium))
                                .foregroundStyle(.white)
                                .frame(width: 52, height: 52)
                                .background(.white.opacity(0.08))
                                .clipShape(
                                    RoundedRectangle(cornerRadius: 16)
                                )

                            VStack(alignment: .leading, spacing: 5) {
                                Text("DoniMods")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(.white)

                                Text("Your tools, all in one place.")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                                    .fixedSize(
                                        horizontal: false,
                                        vertical: true
                                    )
                            }

                            Spacer(minLength: 0)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.white.opacity(0.045))
                        .clipShape(RoundedRectangle(cornerRadius: 21))
                        .overlay {
                            RoundedRectangle(cornerRadius: 21)
                                .stroke(
                                    .white.opacity(0.08),
                                    lineWidth: 1
                                )
                        }

                        // Quick access
                        VStack(alignment: .leading, spacing: 13) {
                            Text("QUICK ACCESS")
                                .font(.system(size: 11, weight: .semibold))
                                .tracking(2)
                                .foregroundStyle(.secondary)

                            NavigationLink {
                                ToolsView()
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "square.grid.2x2")
                                        .font(.system(size: 17))

                                    Text("Explore Tools")
                                        .font(
                                            .system(
                                                size: 15,
                                                weight: .medium
                                            )
                                        )

                                    Spacer()

                                    Image(systemName: "arrow.up.right")
                                        .font(
                                            .system(
                                                size: 16,
                                                weight: .medium
                                            )
                                        )
                                        .foregroundStyle(.secondary)
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 17)
                                .frame(height: 56)
                                .background(.white.opacity(0.055))
                                .clipShape(
                                    RoundedRectangle(cornerRadius: 17)
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        Text("More features coming soon.")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.42))
                            .frame(maxWidth: .infinity)
                            .padding(.top, 1)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 24)
                    .frame(maxWidth: 520)
                    .frame(
                        maxWidth: .infinity,
                        minHeight: geometry.size.height,
                        alignment: .top
                    )
                }
                .background(Color.black)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

// MARK: - Tools

struct ToolsView: View {
    private let tools: [(title: String, icon: String, subtitle: String)] = [
        (
            title: "Game Tools",
            icon: "square.grid.2x2",
            subtitle: "Game utilities"
        ),
        (
            title: "Performance",
            icon: "speedometer",
            subtitle: "Performance options"
        ),
        (
            title: "Coming Soon",
            icon: "sparkles",
            subtitle: "More tools are on the way"
        )
    ]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    PageHeader(
                        title: "Tools",
                        subtitle: "Your gaming utilities."
                    )

                    VStack(spacing: 12) {
                        ForEach(tools, id: \.title) { tool in
                            HStack(spacing: 14) {
                                Image(systemName: tool.icon)
                                    .font(.system(size: 19))
                                    .foregroundStyle(.white)
                                    .frame(width: 46, height: 46)
                                    .background(.white.opacity(0.07))
                                    .clipShape(
                                        RoundedRectangle(cornerRadius: 14)
                                    )

                                VStack(alignment: .leading, spacing: 5) {
                                    Text(tool.title)
                                        .font(
                                            .system(
                                                size: 15,
                                                weight: .semibold
                                            )
                                        )
                                        .foregroundStyle(.white)

                                    Text(tool.subtitle)
                                        .font(.system(size: 12))
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(
                                        .system(size: 11, weight: .semibold)
                                    )
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(14)
                            .background(.white.opacity(0.045))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                    }

                    Text("Tool functionality will be added in future updates.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 24)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity, alignment: .top)
            }
            .background(Color.black)
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

// MARK: - Profile

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    PageHeader(
                        title: "Profile",
                        subtitle: "Your DoniMods account."
                    )

                    VStack(spacing: 14) {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 68, weight: .ultraLight))
                            .foregroundStyle(.white.opacity(0.9))

                        Text("Guest User")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)

                        Text("Login feature coming soon")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .background(.white.opacity(0.045))
                    .clipShape(RoundedRectangle(cornerRadius: 22))

                    Text("Your profile and account options will appear here.")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 24)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity, alignment: .top)
            }
            .background(Color.black)
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

// MARK: - Settings

struct SettingsView: View {
    @AppStorage("doni_haptics") private var hapticsEnabled = true
    @AppStorage("doni_animations") private var animationsEnabled = true

    var body: some View {
        NavigationStack {
            Form {
                Section("Preferences") {
                    Toggle(
                        "Haptic Feedback",
                        isOn: $hapticsEnabled
                    )

                    Toggle(
                        "Animations",
                        isOn: $animationsEnabled
                    )
                }

                Section("About") {
                    HStack {
                        Text("App")
                        Spacer()
                        Text("DoniMods")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Text("More settings will be added in future updates.")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.black)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Shared Header

struct PageHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(.white)

            Text(subtitle)
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
