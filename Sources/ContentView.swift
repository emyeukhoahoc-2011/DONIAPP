import SwiftUI

// MARK: - App Entry

struct ContentView: View {
    @State private var showSplash = true

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if showSplash {
                SplashView()
                    .transition(.opacity)
                    .zIndex(1)
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.easeInOut(duration: 0.35)) {
                    showSplash = false
                }
            }
        }
    }
}

// MARK: - Main Tabs

struct MainTabView: View {
    @State private var selectedTab = 0

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.black
        appearance.shadowColor = UIColor.white.withAlphaComponent(0.1)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView {
                selectedTab = 1
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text("Home")
            }
            .tag(0)

            ToolsView()
                .tabItem {
                    Image(systemName: "hammer.fill")
                    Text("Tools")
                }
                .tag(1)

            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .tag(3)
        }
        .tint(.white)
    }
}

// MARK: - Splash Screen

struct SplashView: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 14) {
                Text("DoniMods")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .scaleEffect(animate ? 1 : 0.88)
                    .opacity(animate ? 1 : 0)

                Text("WELCOME")
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(5)
                    .foregroundStyle(.gray)
                    .opacity(animate ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.7)) {
                animate = true
            }
        }
    }
}

// MARK: - Home

struct HomeView: View {
    let onExploreTools: () -> Void

    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 22) {
                VStack(spacing: 8) {
                    Text("Welcome Back")
                        .font(.system(size: 29, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Text("Everything you need, in one place.")
                        .font(.system(size: 14))
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 60)

                // Main DoniMods Card
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.10))
                                .frame(width: 58, height: 58)

                            Image(systemName: "sparkles")
                                .font(.system(size: 25, weight: .semibold))
                                .foregroundStyle(.white)
                        }

                        VStack(alignment: .leading, spacing: 5) {
                            Text("DoniMods")
                                .font(.system(size: 21, weight: .bold))
                                .foregroundStyle(.white)

                            Text("Your personal toolbox")
                                .font(.system(size: 13))
                                .foregroundStyle(.gray)
                        }

                        Spacer(minLength: 0)
                    }

                    Rectangle()
                        .fill(Color.white.opacity(0.12))
                        .frame(height: 1)

                    Text("Explore your tools and discover what's available.")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.82))
                        .fixedSize(horizontal: false, vertical: true)

                    Button(action: onExploreTools) {
                        HStack {
                            Text("Explore Tools")
                                .font(.system(size: 15, weight: .semibold))
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundStyle(Color.black)
                        .padding(.horizontal, 18)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .contentShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
                .padding(20)
                .frame(maxWidth: 440)
                .background(Color.white.opacity(0.055))
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: 20))

                // More Features Card
                HStack(spacing: 14) {
                    Image(systemName: "clock")
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                        .frame(width: 46, height: 46)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 5) {
                        Text("More Features")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)

                        Text("More features are coming soon.")
                            .font(.system(size: 12))
                            .foregroundStyle(.gray)
                    }

                    Spacer(minLength: 0)
                }
                .padding(16)
                .frame(maxWidth: 440)
                .background(Color.white.opacity(0.035))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 22)
            .padding(.bottom, 40)
        }
        .scrollIndicators(.hidden)
        .background(Color.black)
        .ignoresSafeArea(edges: .top)
    }
}

// MARK: - Tools

struct ToolsView: View {
    private let tools: [(String, String, String)] = [
        ("Game Tools", "Explore available game tools", "gamecontroller.fill"),
        ("Performance", "Performance tools and utilities", "speedometer"),
        ("Coming Soon", "More tools will be added later", "clock")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        PageHeader(
                            title: "Tools",
                            subtitle: "Explore your available tools."
                        )

                        ForEach(tools, id: \.0) { tool in
                            HStack(spacing: 14) {
                                Image(systemName: tool.2)
                                    .font(.system(size: 20))
                                    .foregroundStyle(.white)
                                    .frame(width: 48, height: 48)
                                    .background(Color.white.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 13))

                                VStack(alignment: .leading, spacing: 5) {
                                    Text(tool.0)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(.white)

                                    Text(tool.1)
                                        .font(.system(size: 12))
                                        .foregroundStyle(.gray)
                                }

                                Spacer(minLength: 0)

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.gray)
                            }
                            .padding(15)
                            .background(Color.white.opacity(0.045))
                            .overlay {
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.09), lineWidth: 1)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    .padding(22)
                }
                .scrollIndicators(.hidden)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

// MARK: - Profile

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 20) {
                    PageHeader(
                        title: "Profile",
                        subtitle: "Your account information."
                    )

                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 76))
                        .foregroundStyle(.white.opacity(0.85))

                    VStack(spacing: 7) {
                        Text("Guest User")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)

                        Text("Login feature coming soon")
                            .font(.system(size: 14))
                            .foregroundStyle(.gray)
                    }

                    Spacer(minLength: 0)
                }
                .padding(22)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

// MARK: - Settings

struct SettingsView: View {
    @AppStorage("doni_notifications_enabled")
    private var notificationsEnabled = true

    @AppStorage("doni_haptics_enabled")
    private var hapticsEnabled = true

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        PageHeader(
                            title: "Settings",
                            subtitle: "Customize your app experience."
                        )

                        VStack(spacing: 0) {
                            SettingsRow(
                                title: "Notifications",
                                subtitle: "Enable app notifications",
                                isOn: $notificationsEnabled
                            )

                            Rectangle()
                                .fill(Color.white.opacity(0.09))
                                .frame(height: 1)
                                .padding(.leading, 16)

                            SettingsRow(
                                title: "Haptic Feedback",
                                subtitle: "Enable touch feedback",
                                isOn: $hapticsEnabled
                            )
                        }
                        .background(Color.white.opacity(0.045))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.09), lineWidth: 1)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        VStack(alignment: .leading, spacing: 12) {
                            Text("ABOUT")
                                .font(.system(size: 11, weight: .bold))
                                .tracking(2)
                                .foregroundStyle(.gray)

                            HStack {
                                Text("Application")
                                    .foregroundStyle(.white)
                                Spacer()
                                Text("DoniMods")
                                    .foregroundStyle(.gray)
                            }

                            HStack {
                                Text("Version")
                                    .foregroundStyle(.white)
                                Spacer()
                                Text("1.0.0")
                                    .foregroundStyle(.gray)
                            }
                        }
                        .font(.system(size: 14))
                        .padding(18)
                        .background(Color.white.opacity(0.045))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.09), lineWidth: 1)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(22)
                }
                .scrollIndicators(.hidden)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

// MARK: - Settings Row

struct SettingsRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.gray)
            }

            Spacer(minLength: 8)

            Toggle(title, isOn: $isOn)
                .labelsHidden()
                .tint(.white)
        }
        .padding(16)
    }
}

// MARK: - Page Header

struct PageHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 29, weight: .bold))
                .foregroundStyle(.white)

            Text(subtitle)
                .font(.system(size: 14))
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 8)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
