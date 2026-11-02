import SwiftUI

struct StatusSheet: View {
    @EnvironmentObject private var game: GameModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    playerCard
                    spellBook
                    enemyGuide
                    Button(role: .destructive) { game.resetProgress(); dismiss() } label: {
                        Label("Bắt đầu lại từ đầu", systemImage: "arrow.counterclockwise")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity).padding(.vertical, 12)
                    }.buttonStyle(.bordered).padding(.bottom, 8)
                }
                .padding(.horizontal, 16).padding(.top, 8)
            }
            .navigationTitle("📜 Nhật ký pháp sư")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) { Button("Đóng") { dismiss() } } }
            .preferredColorScheme(.dark)
        }
    }

    private var playerCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("🧙 Pháp Sư").font(.headline)
                Spacer()
                Text("Cấp \(game.combat.level)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color(red: 1.0, green: 0.85, blue: 0.3))
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Color(red: 0.2, green: 0.12, blue: 0.45), in: Capsule())
            }
            Divider().opacity(0.3)
            VStack(spacing: 8) {
                row("❤️ HP",  "\(game.combat.hp)/\(game.combat.maxHP)",  Color(red: 0.95, green: 0.25, blue: 0.3))
                row("💧 MP",  "\(game.combat.mp)/\(game.combat.maxMP)",  Color(red: 0.3, green: 0.55, blue: 1.0))
                row("⚔️ ATK", "\(game.combat.atk)",                       Color(red: 1.0, green: 0.7, blue: 0.2))
                row("✨ EXP", "\(game.combat.exp)/\(game.combat.expToNext)", Color(red: 0.9, green: 0.8, blue: 0.2))
            }
            ProgressView(value: game.combat.expFraction).tint(Color(red: 1.0, green: 0.85, blue: 0.2))
        }
        .padding(14)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
    }

    private func row(_ label: String, _ val: String, _ color: Color) -> some View {
        HStack {
            Text(label).font(.subheadline).foregroundStyle(.white.opacity(0.75))
            Spacer()
            Text(val).font(.subheadline.weight(.semibold)).foregroundStyle(color).monospacedDigit()
        }
    }

    private var spellBook: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("📖 Phép Thuật").font(.headline)
            ForEach(SpellID.allCases) { s in
                let unlocked = s.requiredLevel <= game.combat.level
                HStack(spacing: 12) {
                    Text(s.symbol).font(.title2).frame(width: 38, height: 38)
                        .background(unlocked ? s.color.opacity(0.2) : .white.opacity(0.04),
                                    in: RoundedRectangle(cornerRadius: 10))
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(s.rawValue).font(.subheadline.weight(.semibold))
                                .foregroundStyle(unlocked ? .white : .white.opacity(0.35))
                            if !unlocked {
                                Text("Cần Lv.\(s.requiredLevel)").font(.caption2)
                                    .foregroundStyle(.orange.opacity(0.8))
                                    .padding(.horizontal, 5).padding(.vertical, 2)
                                    .background(.orange.opacity(0.15), in: Capsule())
                            }
                        }
                        Text(desc(s)).font(.caption).foregroundStyle(.white.opacity(0.45))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("💧\(s.manaCost)").font(.caption.weight(.semibold))
                            .foregroundStyle(Color(red: 0.3, green: 0.55, blue: 1.0))
                        Text("⏱\(String(format: "%.1fs", s.cooldown))").font(.caption)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }.opacity(unlocked ? 1 : 0.4)
            }
        }
        .padding(14)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
    }

    private func desc(_ s: SpellID) -> String {
        switch s {
        case .fireball:  return "Cầu lửa — sát thương cao, tầm xa"
        case .iceSpike:  return "Mũi băng — nhanh, chi phí thấp"
        case .lightning: return "Sét đánh — sát thương cực cao"
        case .darkNova:  return "Nổ bóng tối — đánh tất cả quái xung quanh"
        case .heal:      return "Hồi phục HP của bản thân"
        }
    }

    private var enemyGuide: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("👹 Quái Vật").font(.headline)
            ForEach(EnemyType.allCases, id: \.self) { t in
                HStack(spacing: 10) {
                    Text(t.symbol).font(.title3).frame(width: 34, height: 34)
                        .background(t.hpBarColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 9))
                    VStack(alignment: .leading, spacing: 1) {
                        Text(t.rawValue).font(.subheadline.weight(.semibold))
                        Text("HP \(t.baseHP)  ATK \(t.baseATK)")
                            .font(.caption).foregroundStyle(.white.opacity(0.45))
                    }
                    Spacer()
                    Text("+\(t.expReward) EXP").font(.caption.weight(.bold))
                        .foregroundStyle(Color(red: 1.0, green: 0.85, blue: 0.2))
                }
            }
        }
        .padding(14)
        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
    }
}
