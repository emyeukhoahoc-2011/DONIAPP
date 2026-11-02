import SwiftUI

// MARK: - Enemy Type

enum EnemyType: String, CaseIterable {
    case slime      = "Slime"
    case goblin     = "Goblin"
    case skeleton   = "Skeleton"
    case darkWolf   = "Dark Wolf"
    case fireSpirit = "Fire Spirit"
    case iceGolem   = "Ice Golem"
    case darkKnight = "Dark Knight"

    var symbol: String {
        switch self {
        case .slime:      return "🟢"
        case .goblin:     return "👺"
        case .skeleton:   return "💀"
        case .darkWolf:   return "🐺"
        case .fireSpirit: return "🔥"
        case .iceGolem:   return "🧊"
        case .darkKnight: return "🗡️"
        }
    }

    var baseHP: Int {
        switch self {
        case .slime:      return 30
        case .goblin:     return 50
        case .skeleton:   return 70
        case .darkWolf:   return 90
        case .fireSpirit: return 110
        case .iceGolem:   return 160
        case .darkKnight: return 220
        }
    }

    var baseATK: Int {
        switch self {
        case .slime:      return 5
        case .goblin:     return 9
        case .skeleton:   return 13
        case .darkWolf:   return 17
        case .fireSpirit: return 22
        case .iceGolem:   return 18
        case .darkKnight: return 30
        }
    }

    var expReward: Int {
        switch self {
        case .slime:      return 12
        case .goblin:     return 20
        case .skeleton:   return 32
        case .darkWolf:   return 45
        case .fireSpirit: return 60
        case .iceGolem:   return 80
        case .darkKnight: return 120
        }
    }

    var fontSize: CGFloat {
        switch self {
        case .slime:      return 26
        case .goblin:     return 28
        case .skeleton:   return 30
        case .darkWolf:   return 32
        case .fireSpirit: return 30
        case .iceGolem:   return 36
        case .darkKnight: return 34
        }
    }

    var hpBarColor: Color {
        switch self {
        case .slime:      return .green
        case .goblin:     return .orange
        case .skeleton:   return .gray
        case .darkWolf:   return Color(red: 0.5, green: 0.2, blue: 0.8)
        case .fireSpirit: return .red
        case .iceGolem:   return .cyan
        case .darkKnight: return Color(red: 0.4, green: 0.1, blue: 0.8)
        }
    }
}

// MARK: - Enemy

@MainActor
final class Enemy: Identifiable, ObservableObject {
    let id = UUID()
    let type: EnemyType
    let position: CGPoint
    let level: Int

    @Published private(set) var currentHP: Int
    @Published private(set) var isAlive = true
    @Published private(set) var isHurt  = false

    var maxHP: Int { Int(Double(type.baseHP) * (1 + Double(level - 1) * 0.3)) }
    var atk:   Int { Int(Double(type.baseATK) * (1 + Double(level - 1) * 0.25)) }
    var exp:   Int { Int(Double(type.expReward) * (1 + Double(level - 1) * 0.5)) }
    var hpFraction: Double { max(0, Double(currentHP) / Double(maxHP)) }

    init(type: EnemyType, position: CGPoint, level: Int = 1) {
        self.type     = type
        self.position = position
        self.level    = max(1, level)
        self.currentHP = Int(Double(type.baseHP) * (1 + Double(max(1, level) - 1) * 0.3))
    }

    func takeDamage(_ amount: Int) {
        guard isAlive else { return }
        currentHP = max(0, currentHP - amount)
        isHurt = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(220))
            isHurt = false
        }
        if currentHP == 0 { isAlive = false }
    }
}

// MARK: - Spawn map

enum EnemySpawn {
    @MainActor static func makeWorld(playerLevel lv: Int) -> [Enemy] {
        [
            Enemy(type: .slime,      position: CGPoint(x: 280,  y: 450),  level: lv),
            Enemy(type: .slime,      position: CGPoint(x: 500,  y: 320),  level: lv),
            Enemy(type: .slime,      position: CGPoint(x: 150,  y: 700),  level: lv),
            Enemy(type: .goblin,     position: CGPoint(x: 750,  y: 500),  level: lv),
            Enemy(type: .goblin,     position: CGPoint(x: 1000, y: 380),  level: lv),
            Enemy(type: .skeleton,   position: CGPoint(x: 1200, y: 600),  level: lv + 1),
            Enemy(type: .skeleton,   position: CGPoint(x: 900,  y: 800),  level: lv + 1),
            Enemy(type: .darkWolf,   position: CGPoint(x: 400,  y: 950),  level: lv + 1),
            Enemy(type: .darkWolf,   position: CGPoint(x: 1400, y: 750),  level: lv + 2),
            Enemy(type: .fireSpirit, position: CGPoint(x: 1550, y: 400),  level: lv + 2),
            Enemy(type: .fireSpirit, position: CGPoint(x: 1300, y: 1000), level: lv + 2),
            Enemy(type: .iceGolem,   position: CGPoint(x: 650,  y: 1100), level: lv + 3),
            Enemy(type: .iceGolem,   position: CGPoint(x: 1650, y: 900),  level: lv + 3),
            Enemy(type: .darkKnight, position: CGPoint(x: 1500, y: 1150), level: lv + 4),
        ]
    }
}
