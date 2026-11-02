import SwiftUI

@MainActor
final class GameModel: ObservableObject {
    static let worldSize = CGSize(width: 1800, height: 1300)

    @Published private(set) var playerPosition: CGPoint
    @Published var isStatusPresented = false

    let combat = CombatModel()

    private let ud = UserDefaults.standard
    private var moveVec = CGVector.zero
    private var moveTask: Task<Void, Never>?
    private var aiTask:   Task<Void, Never>?

    init() {
        let x = ud.object(forKey: "doni.playerX") as? Double
        let y = ud.object(forKey: "doni.playerY") as? Double
        playerPosition = CGPoint(
            x: min(max(CGFloat(x ?? Double(Self.worldSize.width * 0.5)),  32), Self.worldSize.width  - 32),
            y: min(max(CGFloat(y ?? Double(Self.worldSize.height * 0.5)), 32), Self.worldSize.height - 32)
        )
        startAI()
    }

    // MARK: Movement
    func setMovement(_ vec: CGVector) {
        let cx = min(max(vec.dx, -1), 1)
        let cy = min(max(vec.dy, -1), 1)
        let mag = hypot(cx, cy)
        moveVec = mag > 1 ? CGVector(dx: cx / mag, dy: cy / mag) : CGVector(dx: cx, dy: cy)
        startMoveLoop()
    }

    func stopMovement() { moveVec = .zero }

    private func startMoveLoop() {
        guard moveTask == nil else { return }
        moveTask = Task { [weak self] in
            while !Task.isCancelled {
                do { try await Task.sleep(for: .nanoseconds(16_666_667)) } catch { break }
                self?.tick()
            }
        }
    }

    private func tick() {
        guard abs(moveVec.dx) > 0.001 || abs(moveVec.dy) > 0.001 else { return }
        let delta: CGFloat = 205 / 60
        playerPosition = CGPoint(
            x: min(max(playerPosition.x + moveVec.dx * delta, 28), Self.worldSize.width  - 28),
            y: min(max(playerPosition.y + moveVec.dy * delta, 28), Self.worldSize.height - 28)
        )
    }

    // MARK: Camera
    func cameraOrigin(viewport: CGSize) -> CGPoint {
        CGPoint(
            x: min(max(playerPosition.x - viewport.width  / 2, 0), max(0, Self.worldSize.width  - viewport.width)),
            y: min(max(playerPosition.y - viewport.height / 2, 0), max(0, Self.worldSize.height - viewport.height))
        )
    }

    // MARK: Enemy AI
    private func startAI() {
        aiTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(1500))
                guard let self else { return }
                self.combat.enemyTick(playerPos: self.playerPosition)
            }
        }
    }

    func castSpell() { combat.castSpell(at: playerPosition) }

    // MARK: Save / Reset
    func saveProgress() {
        ud.set(Double(playerPosition.x), forKey: "doni.playerX")
        ud.set(Double(playerPosition.y), forKey: "doni.playerY")
        combat.saveProgress()
    }

    func resetProgress() {
        ud.removeObject(forKey: "doni.playerX")
        ud.removeObject(forKey: "doni.playerY")
        playerPosition = CGPoint(x: Self.worldSize.width * 0.5, y: Self.worldSize.height * 0.5)
        combat.reset()
    }
}
