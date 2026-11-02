import SwiftUI
import Combine

// MARK: - Spell

enum SpellID: String, CaseIterable, Identifiable {
    case fireball  = "Fireball"
    case iceSpike  = "Ice Spike"
    case lightning = "Lightning"
    case darkNova  = "Dark Nova"
    case heal      = "Heal"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .fireball:  return "🔥"
        case .iceSpike:  return "❄️"
        case .lightning: return "⚡"
        case .darkNova:  return "🌀"
        case .heal:      return "💚"
        }
    }

    var color: Color {
        switch self {
        case .fireball:  return Color(red: 1.0, green: 0.35, blue: 0.1)
        case .iceSpike:  return Color(red: 0.45, green: 0.85, blue: 1.0)
        case .lightning: return Color(red: 1.0, green: 0.95, blue: 0.2)
        case .darkNova:  return Color(red: 0.7, green: 0.2, blue: 1.0)
        case .heal:      return Color(red: 0.3, green: 1.0, blue: 0.5)
        }
    }

    var baseDamage: Int {
        switch self {
        case .fireball:  return 35
        case .iceSpike:  return 28
        case .lightning: return 45
        case .darkNova:  return 60
        case .heal:      return 0
        }
    }

    var baseHeal: Int { self == .heal ? 40 : 0 }

    var manaCost: Int {
        switch self {
        case .fireball:  return 15
        case .iceSpike:  return 12
        case .lightning: return 22
        case .darkNova:  return 35
        case .heal:      return 20
        }
    }

    var cooldown: Double {
        switch self {
        case .fireball:  return 1.2
        case .iceSpike:  return 1.0
        case .lightning: return 1.8
        case .darkNova:  return 4.0
        case .heal:      return 5.0
        }
    }

    var range: CGFloat {
        switch self {
        case .fireball:  return 200
        case .iceSpike:  return 180
        case .lightning: return 220
        case .darkNova:  return 260
        case .heal:      return 0
        }
    }

    var requiredLevel: Int {
        switch self {
        case .fireball:  return 1
        case .iceSpike:  return 1
        case .lightning: return 3
        case .darkNova:  return 5
        case .heal:      return 2
        }
    }

    var isAoE: Bool { self == .darkNova }

    func scaledDamage(playerLevel: Int) -> Int {
        Int(Double(baseDamage) * (1 + Double(playerLevel - 1) * 0.18))
    }
    func scaledHeal(playerLevel: Int) -> Int {
        Int(Double(baseHeal) * (1 + Double(playerLevel - 1) * 0.15))
    }
}

// MARK: - Cooldown Tracker

@MainActor
final class SpellCooldownTracker: ObservableObject {
    @Published private(set) var cooldowns: [SpellID: Double] = [:]
    private var timers: [SpellID: AnyCancellable] = [:]
    private let tick = 0.05

    func isReady(_ s: SpellID) -> Bool { (cooldowns[s] ?? 0) <= 0 }
    func remaining(_ s: SpellID) -> Double { max(0, cooldowns[s] ?? 0) }
    func fraction(_ s: SpellID) -> Double {
        let r = remaining(s); return r > 0 ? 1 - r / s.cooldown : 1
    }

    func trigger(_ s: SpellID) {
        cooldowns[s] = s.cooldown
        timers[s]?.cancel()
        timers[s] = Timer.publish(every: tick, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                let prev = self.cooldowns[s] ?? 0
                if prev <= self.tick {
                    self.cooldowns[s] = 0
                    self.timers[s]?.cancel()
                    self.timers[s] = nil
                } else {
                    self.cooldowns[s] = prev - self.tick
                }
            }
    }
}

// MARK: - Floating Label

struct FloatingLabel: Identifiable {
    let id   = UUID()
    let text: String
    let color: Color
    let position: CGPoint
}
