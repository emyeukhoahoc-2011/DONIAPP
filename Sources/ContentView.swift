import SwiftUI

// MARK: - Root

struct ContentView: View {
    @EnvironmentObject private var game: GameModel

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.04, green: 0.03, blue: 0.12),
                         Color(red: 0.07, green: 0.04, blue: 0.16)],
                startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HeaderBar()
                    .padding(.horizontal, 14).padding(.top, 6)

                StatsBar()
                    .padding(.horizontal, 14).padding(.top, 6)

                WorldView()
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color(red: 0.5, green: 0.3, blue: 0.9).opacity(0.4), lineWidth: 1))
                    .padding(.horizontal, 13).padding(.top, 8).padding(.bottom, 8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                SpellBar()
                    .padding(.horizontal, 14)

                BottomBar()
                    .padding(.horizontal, 14).padding(.top, 6).padding(.bottom, 8)
            }
        }
        .sheet(isPresented: $game.isStatusPresented) {
            StatusSheet().environmentObject(game)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Header

private struct HeaderBar: View {
    @EnvironmentObject private var game: GameModel
    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("DARK REALM")
                    .font(.system(size: 18, weight: .black, design: .rounded)).tracking(2.5)
                    .foregroundStyle(LinearGradient(
                        colors: [Color(red: 0.8, green: 0.5, blue: 1.0), Color(red: 0.5, green: 0.3, blue: 1.0)],
                        startPoint: .leading, endPoint: .trailing))
                Text("Pháp sư huyền thoại")
                    .font(.caption2).foregroundStyle(.white.opacity(0.55))
            }
            Spacer(minLength: 4)
            VStack(spacing: 0) {
                Text("LV").font(.system(size: 8, weight: .heavy, design: .rounded)).foregroundStyle(.white.opacity(0.6))
                Text("\(game.combat.level)").font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(Color(red: 1.0, green: 0.85, blue: 0.3))
            }
            .frame(width: 42, height: 42)
            .background(Color(red: 0.2, green: 0.12, blue: 0.45), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12)
                .stroke(Color(red: 0.6, green: 0.4, blue: 1.0).opacity(0.6), lineWidth: 1))

            Button { game.isStatusPresented = true } label: {
                Image(systemName: "scroll.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 38, height: 38)
                    .background(.white.opacity(0.1), in: Circle())
                    .foregroundStyle(.white)
            }.buttonStyle(.plain)
        }
    }
}

// MARK: - Stats Bar

private struct StatsBar: View {
    @EnvironmentObject private var game: GameModel
    var body: some View {
        VStack(spacing: 5) {
            StatRow(icon: "❤️", label: "\(game.combat.hp)/\(game.combat.maxHP)",
                    frac: game.combat.hpFraction,
                    bar: Color(red: 0.95, green: 0.25, blue: 0.3),
                    track: Color(red: 0.25, green: 0.08, blue: 0.1))
            StatRow(icon: "💧", label: "\(game.combat.mp)/\(game.combat.maxMP)",
                    frac: game.combat.mpFraction,
                    bar: Color(red: 0.3, green: 0.55, blue: 1.0),
                    track: Color(red: 0.08, green: 0.1, blue: 0.28))
            StatRow(icon: "✨", label: "\(game.combat.exp)/\(game.combat.expToNext)",
                    frac: game.combat.expFraction,
                    bar: Color(red: 1.0, green: 0.85, blue: 0.2),
                    track: Color(red: 0.2, green: 0.16, blue: 0.05))
        }
        .padding(.horizontal, 10).padding(.vertical, 8)
        .background(.black.opacity(0.28), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.07), lineWidth: 1))
    }
}

private struct StatRow: View {
    let icon: String; let label: String; let frac: Double; let bar: Color; let track: Color
    var body: some View {
        HStack(spacing: 6) {
            Text(icon).font(.system(size: 12)).frame(width: 18)
            GeometryReader { g in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(track)
                    RoundedRectangle(cornerRadius: 4).fill(bar)
                        .frame(width: g.size.width * frac)
                        .animation(.easeOut(duration: 0.25), value: frac)
                }
            }.frame(height: 8)
            Text(label)
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.7)).frame(width: 64, alignment: .trailing)
        }
    }
}

// MARK: - Spell Bar

private struct SpellBar: View {
    @EnvironmentObject private var game: GameModel
    var body: some View {
        HStack(spacing: 8) {
            ForEach(game.combat.availableSpells) { spell in
                SpellBtn(spell: spell,
                         selected: game.combat.selectedSpell == spell,
                         cd: game.combat.cooldowns) {
                    game.combat.selectedSpell = spell
                }
            }
        }.padding(.vertical, 6)
    }
}

private struct SpellBtn: View {
    let spell: SpellID; let selected: Bool
    @ObservedObject var cd: SpellCooldownTracker
    let onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            ZStack {
                if !cd.isReady(spell) {
                    Circle().trim(from: 0, to: 1 - cd.fraction(spell))
                        .stroke(.black.opacity(0.6), lineWidth: 20)
                        .rotationEffect(.degrees(-90))
                }
                Circle()
                    .fill(selected ? spell.color.opacity(0.35) : .white.opacity(0.07))
                    .overlay(Circle().stroke(selected ? spell.color : .white.opacity(0.15),
                                            lineWidth: selected ? 2 : 1))
                Text(spell.symbol).font(.system(size: 18)).opacity(cd.isReady(spell) ? 1 : 0.4)
            }.frame(width: 46, height: 46)
        }.buttonStyle(.plain)
    }
}

// MARK: - Bottom Bar

private struct BottomBar: View {
    @EnvironmentObject private var game: GameModel
    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(game.combat.combatLog)
                    .font(.system(.subheadline, design: .rounded).semibold())
                    .foregroundStyle(.white).lineLimit(2).minimumScaleFactor(0.8)
                Text("Joystick di chuyển • Chọn phép • Nhấn ⚔️ tấn công")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
            }.frame(maxWidth: .infinity, alignment: .leading)

            Joystick().frame(width: 108, height: 108)
            AttackBtn()
        }
    }
}

// MARK: - Joystick

private struct Joystick: View {
    @EnvironmentObject private var game: GameModel
    @State private var knob = CGSize.zero
    private let r: CGFloat = 30

    var body: some View {
        GeometryReader { proxy in
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            ZStack {
                Circle()
                    .fill(Color(red: 0.15, green: 0.08, blue: 0.3).opacity(0.85))
                    .overlay(Circle().stroke(Color(red: 0.5, green: 0.3, blue: 0.9).opacity(0.5), lineWidth: 1.5))
                Circle()
                    .fill(Color(red: 0.55, green: 0.3, blue: 0.9).opacity(0.8))
                    .frame(width: 40, height: 40)
                    .overlay(Circle().stroke(Color(red: 0.8, green: 0.6, blue: 1.0).opacity(0.6), lineWidth: 1))
                    .offset(knob)
                Image(systemName: "circle.grid.cross")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(red: 0.7, green: 0.5, blue: 1.0).opacity(0.4))
                    .allowsHitTesting(false)
            }
            .contentShape(Circle())
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { v in
                    let dx = v.location.x - center.x
                    let dy = v.location.y - center.y
                    let dist = hypot(dx, dy)
                    let clamped = min(dist, r)
                    if dist > 0 {
                        knob = CGSize(width: dx / dist * clamped, height: dy / dist * clamped)
                        game.setMovement(CGVector(dx: dx / r, dy: dy / r))
                    } else { knob = .zero; game.setMovement(.zero) }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.65)) { knob = .zero }
                    game.stopMovement()
                })
        }.onDisappear { game.stopMovement() }
    }
}

// MARK: - Attack Button

private struct AttackBtn: View {
    @EnvironmentObject private var game: GameModel
    @State private var pressed = false
    var body: some View {
        Button {
            pressed = true
            game.castSpell()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { pressed = false }
        } label: {
            ZStack {
                Circle()
                    .fill(RadialGradient(
                        colors: [Color(red: 0.7, green: 0.2, blue: 1.0), Color(red: 0.35, green: 0.1, blue: 0.6)],
                        center: .center, startRadius: 0, endRadius: 28))
                    .frame(width: 60, height: 60)
                    .overlay(Circle().stroke(Color(red: 0.9, green: 0.7, blue: 1.0).opacity(0.7), lineWidth: 2))
                    .shadow(color: Color(red: 0.6, green: 0.2, blue: 1.0).opacity(0.7), radius: pressed ? 6 : 14)
                Text("⚔️").font(.system(size: 24))
            }
            .scaleEffect(pressed ? 0.88 : 1.0)
            .animation(.spring(response: 0.15, dampingFraction: 0.5), value: pressed)
        }.buttonStyle(.plain)
    }
}
