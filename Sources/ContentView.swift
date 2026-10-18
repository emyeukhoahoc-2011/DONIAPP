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
        appearance.backgroundColor = UIColor(white: 0.05, alpha: 1)
        appearance.shadowColor = .clear
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView { selectedTab = 1 }
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

// MARK: - Splash

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
            withAnimation(.easeOut(duration: 0.7)) { animate = true }
        }
    }
}

// MARK: - Home

struct HomeView: View {
    let onExploreTools: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {

                    // Header
                    VStack(spacing: 6) {
                        Text("Welcome Back")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white)

                        Text("Everything you need, in one place.")
                            .font(.system(size: 14))
                            .foregroundStyle(.gray)
                    }
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)

                    // DoniMods Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.white.opacity(0.1))
                                    .frame(width: 52, height: 52)
                                Image(systemName: "sparkles")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundStyle(.white)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("DoniMods")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(.white)
                                Text("Your personal toolbox")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.gray)
                            }
                            Spacer()
                        }

                        Divider().overlay(Color.white.opacity(0.12))

                        Text("Explore your tools and discover what's available.")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.8))

                        Button(action: onExploreTools) {
                            HStack {
                                Text("Explore Tools")
                                    .font(.system(size: 15, weight: .semibold))
                                Spacer()
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            .foregroundStyle(.black)
                            .padding(.horizontal, 16)
                            .frame(height: 46)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 11))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(18)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    }

                    // More Features Card
                    HStack(spacing: 12) {
                        Image(systemName: "clock")
                            .font(.system(size: 18))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 11))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("More Features")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white)
                            Text("More features are coming soon.")
                                .font(.system(size: 12))
                                .foregroundStyle(.gray)
                        }
                        Spacer()
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 16)
            }
        }
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
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    PageHeader(title: "Tools", subtitle: "Explore your available tools.")

                    ForEach(tools, id: \.0) { tool in
                        HStack(spacing: 12) {
                            Image(systemName: tool.2)
                                .font(.system(size: 18))
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 11))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(tool.0)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(.white)
                                Text(tool.1)
                                    .font(.system(size: 12))
                                    .foregroundStyle(.gray)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(.gray)
                        }
                        .padding(14)
                        .background(Color.white.opacity(0.05))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.09), lineWidth: 1)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 16)
            }
        }
    }
}

// MARK: - Profile

struct ProfileView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                PageHeader(title: "Profile", subtitle: "Your account information.")
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                Spacer()

                VStack(spacing: 14) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 72))
                        .foregroundStyle(.white.opacity(0.85))

                    VStack(spacing: 6) {
                        Text("Guest User")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                        Text("Login feature coming soon")
                            .font(.system(size: 14))
                            .foregroundStyle(.gray)
                    }
                }

                Spacer()
            }
        }
    }
}

// MARK: - Settings

struct SettingsView: View {
    @AppStorage("doni_notifications_enabled") private var notificationsEnabled = true
    @AppStorage("doni_haptics_enabled") private var hapticsEnabled = true

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    PageHeader(title: "Settings", subtitle: "Customize your experience.")

                    VStack(spacing: 0) {
                        SettingsRow(title: "Notifications", subtitle: "Enable app notifications", isOn: $notificationsEnabled)
                        Divider().overlay(Color.white.opacity(0.09)).padding(.leading, 16)
                        SettingsRow(title: "Haptic Feedback", subtitle: "Enable touch feedback", isOn: $hapticsEnabled)
                    }
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.09), lineWidth: 1)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("ABOUT")
                            .font(.system(size: 11, weight: .bold))
                            .tracking(2)
                            .foregroundStyle(.gray)

                        HStack {
                            Text("Application").foregroundStyle(.white)
                            Spacer()
                            Text("DoniMods").foregroundStyle(.gray)
                        }

                        HStack {
                            Text("Version").foregroundStyle(.white)
                            Spacer()
                            Text("1.0.0").foregroundStyle(.gray)
                        }
                    }
                    .font(.system(size: 14))
                    .padding(16)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.09), lineWidth: 1)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 16)
            }
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
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.gray)
            }
            Spacer()
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
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.system(size: 14))
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 6)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
