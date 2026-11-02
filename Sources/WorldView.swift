import SwiftUI

// MARK: - World decorations

struct WorldDeco: Identifiable {
    let id: Int; let position: CGPoint; let symbol: String; let size: CGFloat
    static let all: [WorldDeco] = [
        .init(id:1,  position:.init(x:170,  y:210),  symbol:"🌑", size:30),
        .init(id:2,  position:.init(x:420,  y:160),  symbol:"💀", size:22),
        .init(id:3,  position:.init(x:680,  y:270),  symbol:"🌑", size:28),
        .init(id:4,  position:.init(x:980,  y:170),  symbol:"⚗️", size:26),
        .init(id:5,  position:.init(x:1330, y:230),  symbol:"🌑", size:32),
        .init(id:6,  position:.init(x:1600, y:180),  symbol:"🕯️", size:24),
        .init(id:7,  position:.init(x:250,  y:560),  symbol:"🕯️", size:22),
        .init(id:8,  position:.init(x:580,  y:760),  symbol:"🌑", size:34),
        .init(id:9,  position:.init(x:900,  y:1010), symbol:"⚗️", size:26),
        .init(id:10, position:.init(x:1450, y:900),  symbol:"🌑", size:36),
        .init(id:11, position:.init(x:1660, y:1120), symbol:"💀", size:22),
        .init(id:12, position:.init(x:300,  y:1080), symbol:"🌑", size:30),
        .init(id:13, position:.init(x:800,  y:400),  symbol:"🕯️", size:20),
        .init(id:14, position:.init(x:1100, y:700),  symbol:"⚗️", size:24),
        .init(id:15, position:.init(x:1700, y:600),  symbol:"🕯️", size:22),
    ]
}

// MARK: - World View

struct WorldView: View {
    @EnvironmentObject private var game: GameModel

    var body: some View {
        GeometryReader { proxy in
            let cam = game.cameraOrigin(viewport: proxy.size)
            ZStack(alignment: .topLeading) {

                Canvas { ctx, sz in drawBackground(&ctx, sz, cam) }

                ForEach(WorldDeco.all) { d in
                    Text(d.symbol).font(.system(size: d.size))
                        .position(x: d.position.x - cam.x, y: d.position.y - cam.y)
                }

                ForEach(game.combat.enemies) { e in
                    EnemyView(enemy: e, cam: cam)
                }

                PlayerSprite(isHurt: game.combat.isPlayerHurt,
                             levelUp: game.combat.isLevelUpShowing)
                    .position(x: game.playerPosition.x - cam.x,
                              y: game.playerPosition.y - cam.y)

                ForEach(game.combat.floatingLabels) { lbl in
                    FloatView(lbl: lbl, cam: cam)
                }

                Label("DARK MAGIC REALM", systemImage: "sparkles")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(1.1)
                    .padding(.horizontal, 11).padding(.vertical, 8)
                    .background(.black.opacity(0.35), in: Capsule())
                    .foregroundStyle(.white)
                    .padding(12)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
    }

    private func drawBackground(_ ctx: inout GraphicsContext, _ sz: CGSize, _ cam: CGPoint) {
        let b = CGRect(origin: .zero, size: sz)
        ctx.fill(Path(b), with: .color(Color(red: 0.10, green: 0.08, blue: 0.18)))
        for i in 0..<60 {
            let wx = CGFloat((i * 179 + 43) % 1760) + 20
            let wy = CGFloat((i * 251 + 77) % 1260) + 20
            let r  = CGRect(x: wx - cam.x - 30, y: wy - cam.y - 20, width: 60, height: 40)
            guard r.intersects(b) else { continue }
            ctx.fill(Path(ellipseIn: r),
                     with: .color(Color(red: 0.5, green: 0.3, blue: 1.0).opacity(i.isMultiple(of: 3) ? 0.06 : 0.04)))
        }
        var p = Path()
        p.move(to: CGPoint(x: -cam.x - 80, y: 760 - cam.y))
        p.addCurve(to:       CGPoint(x: 1880 - cam.x, y: 500  - cam.y),
                   control1: CGPoint(x: 510  - cam.x, y: 420  - cam.y),
                   control2: CGPoint(x: 1120 - cam.x, y: 1010 - cam.y))
        ctx.stroke(p, with: .color(Color(red: 0.35, green: 0.2, blue: 0.6).opacity(0.8)),
                   style: .init(lineWidth: 48, lineCap: .round))
        ctx.stroke(p, with: .color(Color(red: 0.8, green: 0.6, blue: 1.0).opacity(0.5)),
                   style: .init(lineWidth: 2, dash: [8, 9]))
    }
}

// MARK: - Enemy View

struct EnemyView: View {
    @ObservedObject var enemy: Enemy
    let cam: CGPoint

    var body: some View {
        if enemy.isAlive {
            VStack(spacing: 2) {
                Text("Lv.\(enemy.level)")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.horizontal, 4).padding(.vertical, 1)
                    .background(.black.opacity(0.5), in: Capsule())

                Text(enemy.type.symbol)
                    .font(.system(size: enemy.type.fontSize))
                    .scaleEffect(enemy.isHurt ? 1.25 : 1.0)
                    .opacity(enemy.isHurt ? 0.6 : 1.0)
                    .animation(.spring(response: 0.18, dampingFraction: 0.5), value: enemy.isHurt)
                    .shadow(color: enemy.type.hpBarColor.opacity(0.7), radius: enemy.isHurt ? 10 : 4)

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(.black.opacity(0.55)).frame(width: 44, height: 5)
                    RoundedRectangle(cornerRadius: 3).fill(enemy.type.hpBarColor)
                        .frame(width: 44 * enemy.hpFraction, height: 5)
                        .animation(.easeOut(duration: 0.2), value: enemy.hpFraction)
                }
            }
            .position(x: enemy.position.x - cam.x, y: enemy.position.y - cam.y)
        }
    }
}

// MARK: - Player Sprite

struct PlayerSprite: View {
    let isHurt:  Bool
    let levelUp: Bool
    @State private var aura = false

    var body: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(
                    colors: [Color(red: 0.6, green: 0.3, blue: 1.0).opacity(aura ? 0.45 : 0.18), .clear],
                    center: .center, startRadius: 0, endRadius: aura ? 30 : 20))
                .frame(width: 60, height: 60)
                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: aura)

            if levelUp {
                Text("⭐").font(.system(size: 22)).offset(y: -44).transition(.scale.combined(with: .opacity))
            }

            VStack(spacing: -4) {
                Text("🧙").font(.system(size: 28))
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color(red: 0.55, green: 0.2, blue: 0.85), Color(red: 0.3, green: 0.1, blue: 0.6)],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 26, height: 26)
                        .overlay(Circle().stroke(Color(red: 0.8, green: 0.6, blue: 1.0).opacity(0.9), lineWidth: 2))
                    Image(systemName: "sparkles").font(.system(size: 11, weight: .bold)).foregroundStyle(.white)
                }
            }
        }
        .colorMultiply(isHurt ? Color(red: 1, green: 0.3, blue: 0.3) : .white)
        .animation(.easeOut(duration: 0.15), value: isHurt)
        .shadow(color: Color(red: 0.7, green: 0.4, blue: 1.0).opacity(0.6), radius: 8, y: 3)
        .onAppear { aura = true }
    }
}

// MARK: - Floating Label

struct FloatView: View {
    let lbl: FloatingLabel
    let cam: CGPoint
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1

    var body: some View {
        Text(lbl.text)
            .font(.system(size: 14, weight: .black, design: .rounded))
            .foregroundStyle(lbl.color)
            .shadow(color: .black.opacity(0.7), radius: 3)
            .position(x: lbl.position.x - cam.x, y: lbl.position.y - cam.y + offset)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 1.0)) { offset = -50; opacity = 0 }
            }
    }
}
