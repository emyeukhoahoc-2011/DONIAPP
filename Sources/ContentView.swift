
import SwiftUI

// MARK: - Main View

struct ContentView: View {
    @State private var showSplash = true
    @State private var selectedTab: AppTab = .home

    var body: some View {
        ZStack {
            Color(uiColor: .systemBackground)
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

            withAnimation(.easeInOut(duration: 0.55)) {
                showSplash = false
            }
        }
    }
}

// MARK: - Navigation

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
                .opacity(0.18)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                Text("DoniMods")
                    .font(.system(size: 38, weight: .semibold, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 18)
                    .background {
                        RoundedRectangle(cornerRadius: 22)
                            .fill(.ultraThinMaterial)
                            .environment(\.colorScheme, .dark)
                            .overlay {
                                RoundedRectangle(cornerRadius: 22)
                                    .stroke(
                                        .white.opacity(0.24),
                                        lineWidth: 1
                                    )
                            }
                    }
                    .shadow(color: .white.opacity(0.10), radius: 28)

                Text("WELCOME")
                    .font(.system(size: 10, weight: .medium))
                    .tracking(5)
                    .foregroundStyle(.white.opacity(0.48))
            }
            .scaleEffect(animateLogo ? 1 : 0.92)
            .opacity(animateLogo ? 1 : 0)
            .onAppear {
                withAnimation(.easeOut(duration: 0.7)) {
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
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 26) {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("DONIMODS")
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(3)
                            .foregroundStyle(.secondary)

                        Text("Welcome back.")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(.white)

                        Text("Your gaming companion.")
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 14) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 25, weight: .medium))
                            .foregroundStyle(.white)
                            .frame(width: 54, height: 54)
                            .background(.white.opacity(0.09))
                            .clipShape(RoundedRectangle(cornerRadius: 16))

                        VStack(alignment: .leading, spacing: 5) {
                            Text("DoniMods")
                                .font(.system(size: 18, weight: .semibold))

                            Text("Your tools, all in one place.")
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .padding(18)
                    .background(Color.white.opacity(0.045))
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .overlay {
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(.white.opacity(0.08), lineWidth: 1)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        Text("QUICK ACCESS")
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(2)
                            .foregroundStyle(.secondary)

                        NavigationLink {
                            ToolsView()
                        } label: {
                            HStack {
                                Label("Explore Tools", systemImage: "square.grid.2x2")
                                    .font(.system(size: 15, weight: .medium))
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .foregroundStyle(.secondary)
                            }
                            .foregroundStyle(.white)
                            .padding(18)
                            .background(Color.white.opacity(0.055))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }

                    Text("More features coming soon.")
                        .font(.system(size: 13))
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                }
                .padding(22)
            }
            .background(Color(uiColor: .systemBackground))
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

// MARK: - Tools

struct ToolsView: View {
    private let tools: [(String, String, String)] = [
        ("Game Tools", "square.grid.2x2", "Game utilities"),
        ("Performance", "speedometer", "Performance options"),
        ("Coming Soon", "sparkles", "More tools are on the way")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    pageHeader(
                        title: "Tools",
                        subtitle: "Your gaming utilities."
                    )

                    ForEach(tools, id: \.0) { tool in
                        HStack(spacing: 15) {
                            Image(systemName: tool.1)
                                .font(.system(size: 20))
                                .frame(width: 48, height: 48)
                                .background(.white.opacity(0.07))
                                .clipShape(RoundedRectangle(cornerRadius: 14))

                            VStack(alignment: .leading, spacing: 5) {
                                Text(tool.0)
                                    .font(.system(size: 16, weight: .semibold))

                                Text(tool.2)
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(16)
                        .background(.white.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    }

                    Text("These are interface placeholders. Tool functionality can be added later.")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }
                .padding(22)
            }
            .background(Color(uiColor: .systemBackground))
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

// MARK: - Profile

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    pageHeader(
                        title: "Profile",
                        subtitle: "Your DoniMods account."
                    )

                    VStack(spacing: 14) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 76, weight: .ultraLight))
                            .foregroundStyle(.white.opacity(0.9))

                        Text("Guest User")
                            .font(.system(size: 21, weight: .semibold))

                        Text("Login feature coming soon")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 35)
                    .background(.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 24))

                    Text("Your profile and account options will appear here.")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(22)
            }
            .background(Color(uiColor: .systemBackground))
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
                    Toggle("Haptic Feedback", isOn: $hapticsEnabled)
                    Toggle("Animations", isOn: $animationsEnabled)
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
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(uiColor: .systemBackground))
            .navigationTitle("Settings")
        }
    }
}

// MARK: - Shared Header

@ViewBuilder
func pageHeader(title: String, subtitle: String) -> some View {
    VStack(alignment: .leading, spacing: 7) {
        Text(title)
            .font(.system(size: 32, weight: .bold))
            .foregroundStyle(.white)

        Text(subtitle)
            .font(.system(size: 15))
            .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
}
