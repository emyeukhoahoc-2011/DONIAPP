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
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    showSplash = false
                }
            }
        }
    }
}

// MARK: - Splash

struct SplashView: View {
    @State private var animate = false
    @State private var glowPulse = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Background glow
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
    @State private var pulse = false

    private let features = [
        ("bolt.fill", "Speed Boost", "Optimize game performance instantly"),
        ("shield.fill", "Protection", "Anti-ban & safety tools"),
        ("star.fill", "Premium Mods", "Exclusive modded features"),
    ]

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(red: 0.03, green: 0.03, blue: 0.08), .black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Top glow accent
            Circle()
                .fill(Color.cyan.opacity(0.12))
                .frame(width: 250, height: 250)
                .blur(radius: 70)
                .offset(x: 80, y: -120)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {

                    // Top Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Welcome Back")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.gray)
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

                        Spacer()

                        // Status badge
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
                    ZStack {
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

                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [.cyan.opacity(0.6), .blue.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )

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

                            Text("Access powerful mods, tweaks and tools to level up your gaming experience.")
                                .font(.system(size: 13))
                                .foregroundStyle(.white.opacity(0.6))
                                .lineSpacing(3)

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
                    }
                    .frame(height: 240)

                    // Features Grid
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
                                }

                                Spacer()

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

                        Spacer()

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
            LinearGradient(
                colors: [Color(red: 0.03, green: 0.03, blue: 0.08), .black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    NeonPageHeader(title: "Tools", subtitle: "Select a tool to get started.")

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
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
                                    Text(tool.1)
                                        .font(.system(size: 11))
                                        .foregroundStyle(.gray)
                                        .lineLimit(2)
                                }

                                Spacer()

                                HStack {
                                    Spacer()
                                    Image(systemName: "arrow.right.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(tool.3.opacity(0.6))
                                }
                            }
                            .padding(14)
                            .frame(height: 130)
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
    private let stats = [("Mods Used", "0"), ("Sessions", "0"), ("Rank", "—")]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.03, green: 0.03, blue: 0.08), .black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            Circle()
                .fill(Color.cyan.opacity(0.08))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(y: -100)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    NeonPageHeader(title: "Profile", subtitle: "Your gaming identity.")

                    // Avatar
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
                                LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 2
                            )
                            .frame(width: 90, height: 90)
                            .shadow(color: .cyan.opacity(0.4), radius: 8)

                        Image(systemName: "person.fill")
                            .font(.system(size: 38))
                            .foregroundStyle(.cyan.opacity(0.9))
                    }

                    VStack(spacing: 6) {
                        Text("Guest Player")
                            .font(.system(size: 22, weight: .black))
                            .foregroundStyle(.white)

                        Text("Login coming soon")
                            .font(.system(size: 13))
                            .foregroundStyle(.gray)
                    }

                    // Stats row
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

                    // Login button
                    Button(action: {}) {
                        HStack(spacing: 8) {
                            Image(systemName: "person.badge.plus")
                            Text("Login / Register")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            LinearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: .cyan.opacity(0.3), radius: 8, y: 4)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 20)
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
            LinearGradient(
                colors: [Color(red: 0.03, green: 0.03, blue: 0.08), .black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    NeonPageHeader(title: "Settings", subtitle: "Configure your experience.")

                    // Toggles
                    VStack(spacing: 0) {
                        NeonSettingsRow(title: "Notifications", subtitle: "Enable push notifications", icon: "bell.fill", iconColor: .cyan, isOn: $notificationsEnabled)
                        Divider().overlay(Color.white.opacity(0.07)).padding(.leading, 56)
                        NeonSettingsRow(title: "Haptic Feedback", subtitle: "Enable touch vibration", icon: "iphone.radiowaves.left.and.right", iconColor: .purple, isOn: $hapticsEnabled)
                    }
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.cyan.opacity(0.15), lineWidth: 1)
                    }

                    // About
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

            Spacer()

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
                .foregroundStyle(
                    LinearGradient(colors: [.white, .white.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                )
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
