import SwiftUI
import Combine

@MainActor
final class CombatModel: ObservableObject {

    // MARK: Stats
    @Published private(set) var level: Int
    @Published private(set) var exp:   Int
    @Published private(set) var hp:    Int
    @Published private(set) var maxHP: Int
    @Published private(set) var mp:    Int
    @Published private(set) var maxMP: Int
    @Published private(set) var atk:   Int

    // MARK: State
    @Published private(set) var enemies: [Enemy] = []
    @Published private(set) var floatingLabels: [FloatingLabel] = []
    @Published private(set) var combatLog  = "Thế giới phép thuật đang chờ bạn..."
    @Published private(set) var isLevelUpShowing = false
    @Published private(set) var isPlayerHurt     = false
    @Published var selectedSpell: SpellID = .fireball

    let cooldowns = SpellCooldownTracker()

    private let ud = UserDefaults.standard
    private let k  = "doni.combat."

    // MARK: Derived
    var expToNext: Int     { Int(Double(level) * 60 * pow(1.35, Double(level - 1))) }
    var expFraction: Double { min(1, Double(exp) / Double(expToNext)) }
    var hpFraction:  Double { max(0, Double(hp) / Double(maxHP)) }
    var mpFraction:  Double { max(0, Double(mp) / Double(maxMP)) }
    var availableSpells: [SpellID] { SpellID.allCases.filter { $0.requiredLevel <= level } }

    static func calcMaxHP(_ lv: Int) -> Int { 80  + (lv - 1) * 20 }
    static func calcMaxMP(_ lv: Int) -> Int { 60  + (lv - 1) * 12 }
    static func calcATK  (_ lv: Int) -> Int { 12  + (lv - 1) * 5  }

    // MARK: Init
    init() {
        let lv  = max(1, ud.integer(forKey: "doni.combat.level"))
        let mhp = Self.calcMaxHP(lv)
        let mmp = Self.calcMaxMP(lv)
        level = lv
        exp   = ud.integer(forKey: "doni.combat.exp")
        maxHP = mhp
        maxMP = mmp
        hp    = min(max(1, ud.integer(forKey: "doni.combat.hp")), mhp).nonzero ?? mhp
        mp    = min(max(0, ud.integer(forKey: "doni.combat.mp")), mmp)
        atk   = Self.calcATK(lv)
        spawnEnemies()
        startRegen()
    }

    // MARK: Spawn
    func spawnEnemies() {
        enemies = EnemySpawn.makeWorld(playerLevel: level)
    }

    // MARK: Cast
    @discardableResult
    func castSpell(at playerPos: CGPoint) -> Bool {
        let spell = selectedSpell
        guard cooldowns.isReady(spell) else {
            combatLog = "⏳ \(spell.rawValue) đang hồi chiêu..."; return false
        }
        guard mp >= spell.manaCost else {
            combatLog = "💧 Không đủ MP!"; return false
        }

        if spell == .heal {
            let amt = spell.scaledHeal(playerLevel: level)
            hp = min(maxHP, hp + amt)
            mp -= spell.manaCost
            cooldowns.trigger(spell)
            addFloat("+\(amt) HP", color: spell.color, at: playerPos)
            combatLog = "💚 Hồi \(amt) HP!"
            return true
        }

        let alive   = enemies.filter(\.isAlive)
        let inRange = alive.filter {
            hypot($0.position.x - playerPos.x, $0.position.y - playerPos.y) <= spell.range
        }
        guard !inRange.isEmpty else {
            combatLog = "❌ Không có quái trong tầm!"; return false
        }

        mp -= spell.manaCost
        cooldowns.trigger(spell)
        let dmg = spell.scaledDamage(playerLevel: level)

        if spell.isAoE {
            for e in inRange {
                let d = max(1, dmg + Int.random(in: -4...4))
                e.takeDamage(d)
                addFloat("-\(d)", color: spell.color, at: e.position)
                if !e.isAlive { gainExp(e.exp) }
            }
            combatLog = "\(spell.symbol) \(spell.rawValue) đánh \(inRange.count) quái!"
        } else {
            let t = inRange.min {
                hypot($0.position.x - playerPos.x, $0.position.y - playerPos.y) <
                hypot($1.position.x - playerPos.x, $1.position.y - playerPos.y)
            }!
            let d = max(1, dmg + Int.random(in: -3...6))
            t.takeDamage(d)
            addFloat("-\(d)", color: spell.color, at: t.position)
            if !t.isAlive {
                gainExp(t.exp)
                combatLog = "\(spell.symbol) Tiêu diệt \(t.type.rawValue)! +\(t.exp) EXP"
            } else {
                combatLog = "\(spell.symbol) \(spell.rawValue) → \(t.type.rawValue) (-\(d) HP)"
            }
        }

        checkRespawn()
        return true
    }

    // MARK: Enemy AI tick (được gọi từ GameModel mỗi 1.5s)
    func enemyTick(playerPos: CGPoint) {
        guard hp > 0 else { return }
        for e in enemies where e.isAlive {
            let dist = hypot(e.position.x - playerPos.x, e.position.y - playerPos.y)
            if dist <= 55 {
                let d = max(1, e.atk + Int.random(in: -2...3))
                hp = max(0, hp - d)
                isPlayerHurt = true
                addFloat("-\(d)", color: .red, at: CGPoint(x: playerPos.x, y: playerPos.y - 20))
                combatLog = "💥 \(e.type.rawValue) tấn công! -\(d) HP"
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(300))
                    self.isPlayerHurt = false
                }
                if hp == 0 {
                    combatLog = "☠️ Bạn đã ngã xuống! Hồi sinh..."
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(2))
                        self.hp = self.maxHP / 2
                        self.combatLog = "🌟 Hồi sinh với \(self.hp) HP!"
                    }
                }
                break
            }
        }
    }

    // MARK: EXP / Level Up
    private func gainExp(_ amount: Int) {
        exp += amount
        while exp >= expToNext {
            exp -= expToNext
            levelUp()
        }
        saveProgress()
    }

    private func levelUp() {
        level += 1
        maxHP = Self.calcMaxHP(level)
        maxMP = Self.calcMaxMP(level)
        atk   = Self.calcATK(level)
        hp = maxHP; mp = maxMP
        isLevelUpShowing = true
        combatLog = "🎉 LÊN CẤP \(level)! HP/MP hồi đầy!"
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(2500))
            self.isLevelUpShowing = false
        }
        spawnEnemies()
    }

    // MARK: Regen
    private func startRegen() {
        Task { @MainActor [weak self] in
            while true {
                try? await Task.sleep(for: .seconds(3))
                guard let self else { return }
                if self.hp > 0 && self.hp < self.maxHP {
                    self.hp = min(self.maxHP, self.hp + max(1, self.maxHP / 20))
                }
            }
        }
        Task { @MainActor [weak self] in
            while true {
                try? await Task.sleep(for: .seconds(2))
                guard let self else { return }
                if self.mp < self.maxMP {
                    self.mp = min(self.maxMP, self.mp + max(1, self.maxMP / 15))
                }
            }
        }
    }

    // MARK: Respawn
    private func checkRespawn() {
        if enemies.allSatisfy({ !$0.isAlive }) {
            combatLog = "Tất cả quái đã bị tiêu diệt! Hồi sinh..."
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(2500))
                self.spawnEnemies()
                self.combatLog = "Quái vật xuất hiện trở lại!"
            }
        }
    }

    // MARK: Floating
    private func addFloat(_ text: String, color: Color, at pos: CGPoint) {
        let lbl = FloatingLabel(text: text, color: color, position: pos)
        floatingLabels.append(lbl)
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1100))
            self.floatingLabels.removeAll { $0.id == lbl.id }
        }
    }

    // MARK: Save / Reset
    func saveProgress() {
        ud.set(level, forKey: "doni.combat.level")
        ud.set(exp,   forKey: "doni.combat.exp")
        ud.set(hp,    forKey: "doni.combat.hp")
        ud.set(mp,    forKey: "doni.combat.mp")
    }

    func reset() {
        level = 1; exp = 0
        maxHP = Self.calcMaxHP(1); maxMP = Self.calcMaxMP(1)
        hp = maxHP; mp = maxMP; atk = Self.calcATK(1)
        combatLog = "Bắt đầu từ đầu!"
        spawnEnemies(); saveProgress()
    }
}

private extension Int {
    var nonzero: Int? { self == 0 ? nil : self }
}
