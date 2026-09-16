import Foundation
import SwiftUI

@Observable
class GameState {
    var board: [BoardTile] = []
    var tray: [BoardTile] = []
    var overflowTray: [BoardTile] = []
    var statusMessage = "Clear the covered tiles"
    var isGameOver = false
    var didWin = false
    var shufflesRemaining = 1
    var undosRemaining = 2
    var lastUndoableTileID: UUID?
    var justMatched = false
    var justClearedTray = false
    private var hasPlacedInTrayThisLevel = false
    var lives = 3
    var score = 0
    var level = 1
    var highScore = 0
    var isNewHighScore = false
    var lifeBank = 0
    var totalLevelsCompleted = 0
    var justEarnedBankLife = false
    
    let maxTraySize = 7
    let overflowSlotCount = 6
    private static let highScoreKey = "highScore"
    private static let lifeBankKey = "lifeBank"
    private static let totalLevelsKey = "totalLevelsCompleted"
    static let pendingBankHighlightKey = "pendingBankLifeHighlight"
    private static let backgroundNames = [
        "game-background",
        "game-background-1",
        "game-background-2",
        "game-background-3",
        "game-background-4"
    ]
    
    var shufflesForCurrentLevel: Int {
        max(1, (max(1, level) - 1) / 10)
    }
    
    /// Starts at 2. +1 after completing 5, 15, 25… (the Extra Undo bonus).
    var undosForCurrentLevel: Int {
        let current = max(1, level)
        guard current > 5 else { return 2 }
        return 3 + (current - 6) / 10
    }
    
    var canUndo: Bool {
        guard undosRemaining > 0, !isGameOver, let id = lastUndoableTileID else { return false }
        return tray.contains(where: { $0.id == id })
            || overflowTray.contains(where: { $0.id == id })
    }
    
    /// Extra free overflow slots. 0 before level 21 (second tray hidden).
    static func overflowFreeCount(for level: Int) -> Int {
        switch max(1, level) {
        case ..<21: return 0
        case 21...25: return 1
        case 26...30: return 2
        case 31...35: return 3
        default: return 4
        }
    }
    
    var overflowFreeCount: Int { Self.overflowFreeCount(for: level) }
    
    var showsOverflowTray: Bool { overflowFreeCount > 0 }
    
    var totalTrayCapacity: Int { maxTraySize + overflowFreeCount }
    
    var allTrayTiles: [BoardTile] { tray + overflowTray }
    
    var availableIconCount: Int {
        min(20, 5 + (level - 1) / 5)
    }
    
    var backgroundName: String {
        backgroundName(for: level)
    }
    
    func backgroundName(for level: Int) -> String {
        let index = (max(1, level) - 1) / 10
        return Self.backgroundNames[index % Self.backgroundNames.count]
    }
    
    init(startingLevel: Int = 1) {
        highScore = UserDefaults.standard.integer(forKey: Self.highScoreKey)
        lifeBank = UserDefaults.standard.integer(forKey: Self.lifeBankKey)
        totalLevelsCompleted = UserDefaults.standard.integer(forKey: Self.totalLevelsKey)
        level = max(1, startingLevel)
        startNewLevel()
    }
    
    func addToLifeBank(_ amount: Int) {
        guard amount != 0 else { return }
        lifeBank = max(0, lifeBank + amount)
        UserDefaults.standard.set(lifeBank, forKey: Self.lifeBankKey)
    }
    
    func useBankedLife() -> Bool {
        guard lifeBank > 0, lives <= 0, isGameOver, !didWin else { return false }
        addToLifeBank(-1)
        lives = 1
        startNewLevel()
        statusMessage = "Banked life used! \(lifeBank) left in bank"
        return true
    }
    
    func updateHighScoreIfNeeded() {
        guard score > highScore else { return }
        highScore = score
        isNewHighScore = true
        UserDefaults.standard.set(highScore, forKey: Self.highScoreKey)
    }
    
    func startNewLevel() {
        board = generateLevel(iconCount: availableIconCount)
        updateFreeTiles()
        tray = []
        overflowTray = []
        statusMessage = "Level \(level) – match 3 tiles"
        isGameOver = false
        didWin = false
        shufflesRemaining = shufflesForCurrentLevel
        undosRemaining = undosForCurrentLevel
        justMatched = false
        justClearedTray = false
        hasPlacedInTrayThisLevel = false
        justEarnedBankLife = false
        lastUndoableTileID = nil
        // don’t reset lives, score, or life bank here – only reset those on full restart / title
    }
    
    // MARK: - Level generation
    private func generateLevel(iconCount: Int) -> [BoardTile] {
        let positions = layoutPositions(for: level)
        let icons = balancedIconPool(tileCount: positions.count, iconCount: iconCount)
        let pavers = (1...6).map { "paver-\($0)" }
        
        return zip(positions, icons).map { pos, icon in
            BoardTile(
                iconName: icon,
                paverName: pavers.randomElement()!,
                row: pos.row,
                col: pos.col,
                layer: pos.layer
            )
        }
    }
    
    private func balancedIconPool(tileCount: Int, iconCount: Int) -> [String] {
        let groups = tileCount / 3
        let iconsToUse = max(1, min(iconCount, groups))
        let names = (1...iconsToUse).map { "icon-\($0)" }
        
        var pool: [String] = []
        for i in 0..<groups {
            pool += Array(repeating: names[i % iconsToUse], count: 3)
        }
        pool.shuffle()
        return pool
    }
    
    private typealias TilePos = (row: Int, col: Int, layer: Int)
    
    private func rect(
        rows: ClosedRange<Int>,
        cols: ClosedRange<Int>,
        layer: Int,
        skip: Set<String> = []
    ) -> [TilePos] {
        var result: [TilePos] = []
        for row in rows {
            for col in cols {
                if skip.contains("\(row),\(col)") { continue }
                result.append((row, col, layer))
            }
        }
        return result
    }
    
    private enum BoardShape {
        case h, plus, ring, diamond, frame
    }
    
    private func layoutPositions(for level: Int) -> [TilePos] {
        if level <= 10 {
            return earlyRectangularLayout(level)
        }
        let extraLayers: Int
        switch level {
        case 11...20: extraLayers = 2
        case 21...30: extraLayers = 3
        default: extraLayers = 3
        }
        return stackedShape(pickShape(for: level), extraLayers: extraLayers, dense: level > 20)
    }
    
    private func earlyRectangularLayout(_ level: Int) -> [TilePos] {
        switch level {
        case 1:
            return rect(rows: 1...3, cols: 1...5, layer: 0)
                + [(2, 2, 1), (2, 3, 1), (2, 4, 1)]
        case 2:
            return rect(rows: 0...3, cols: 1...4, layer: 0)
                + [(1, 1, 1), (1, 2, 1), (1, 3, 1), (2, 2, 1), (2, 3, 1)]
        case 3, 4:
            return rect(rows: 0...3, cols: 1...5, layer: 0)
                + [(1, 1, 1), (1, 2, 1), (1, 3, 1), (1, 4, 1),
                   (2, 1, 1), (2, 2, 1), (2, 3, 1)]
        case 5:
            return rect(rows: 0...3, cols: 0...5, layer: 0, skip: ["0,0", "0,5", "3,0", "3,5"])
                + rect(rows: 1...2, cols: 1...4, layer: 1)
                + [(1, 2, 2), (1, 3, 2)]
        case 6, 7, 8:
            return rect(rows: 0...3, cols: 0...5, layer: 0, skip: ["0,0", "0,5", "3,0", "3,5"])
                + [(0, 1, 1), (0, 2, 1), (0, 3, 1), (0, 4, 1),
                   (1, 0, 1), (1, 2, 1), (1, 3, 1), (1, 5, 1),
                   (2, 0, 1), (2, 2, 1), (2, 3, 1), (2, 5, 1)]
                + [(1, 2, 2), (1, 3, 2), (2, 2, 2), (2, 3, 2)]
        default:
            return rect(rows: 0...3, cols: 0...5, layer: 0)
                + [(0, 2, 1), (0, 3, 1),
                   (1, 1, 1), (1, 2, 1), (1, 3, 1), (1, 4, 1),
                   (2, 1, 1), (2, 2, 1), (2, 3, 1), (2, 4, 1),
                   (3, 2, 1), (3, 3, 1)]
                + [(1, 1, 2), (1, 2, 2), (1, 3, 2), (2, 2, 2), (2, 3, 2), (2, 4, 2)]
        }
    }
    
    private func pickShape(for level: Int) -> BoardShape {
        let pool: [BoardShape]
        switch level {
        case 11...15:
            pool = [.h, .plus, .diamond]
        case 16...20:
            pool = [.h, .plus, .diamond, .ring]
        case 21...30:
            pool = [.h, .ring, .diamond, .frame, .plus]
        default:
            pool = Bool.random()
                ? [.frame, .h, .ring]
                : [.frame, .h, .ring, .diamond, .plus]
        }
        return pool.randomElement() ?? .plus
    }
    
    private func shapeCells(_ shape: BoardShape) -> [(Int, Int)] {
        switch shape {
        case .h:
            return [
                (0, 0), (0, 1), (0, 4), (0, 5),
                (1, 0), (1, 1), (1, 2), (1, 3), (1, 4), (1, 5),
                (2, 0), (2, 1), (2, 2), (2, 3), (2, 4), (2, 5),
                (3, 0), (3, 1), (3, 4), (3, 5)
            ]
        case .plus:
            return [
                (0, 1), (0, 2), (0, 3), (0, 4),
                (1, 0), (1, 1), (1, 2), (1, 3), (1, 4), (1, 5),
                (2, 0), (2, 1), (2, 2), (2, 3), (2, 4), (2, 5),
                (3, 1), (3, 2), (3, 3), (3, 4)
            ]
        case .ring:
            return [
                (0, 0), (0, 1), (0, 2), (0, 3), (0, 4), (0, 5),
                (1, 0), (1, 1), (1, 4), (1, 5),
                (2, 0), (2, 1), (2, 4), (2, 5),
                (3, 0), (3, 1), (3, 2), (3, 3), (3, 4), (3, 5)
            ]
        case .diamond:
            return [
                (0, 1), (0, 2), (0, 3), (0, 4),
                (1, 0), (1, 1), (1, 2), (1, 3), (1, 4), (1, 5),
                (2, 0), (2, 1), (2, 2), (2, 3), (2, 4), (2, 5),
                (3, 1), (3, 2), (3, 3), (3, 4)
            ]
        case .frame:
            return [
                (0, 0), (0, 1), (0, 2), (0, 3), (0, 4), (0, 5),
                (1, 0), (1, 1), (1, 4), (1, 5),
                (2, 0), (2, 1), (2, 4), (2, 5),
                (3, 0), (3, 1), (3, 2), (3, 3), (3, 4), (3, 5)
            ]
        }
    }
    
    private func stackedShape(_ shape: BoardShape, extraLayers: Int, dense: Bool) -> [TilePos] {
        let base = shapeCells(shape)
        var positions: [TilePos] = base.map { ($0.0, $0.1, 0) }
        
        let inward = base.sorted {
            let da = hypot(Double($0.0) - 1.5, Double($0.1) - 2.5)
            let db = hypot(Double($1.0) - 1.5, Double($1.1) - 2.5)
            return da < db
        }
        
        let layer1Fraction = dense ? 4 : 3
        let layer2Fraction = dense ? 3 : 2
        let layer3Fraction = dense ? 2 : 3
        
        if extraLayers >= 1 {
            let count = max(6, min(inward.count, (inward.count * layer1Fraction) / 4))
            positions += inward.prefix(count).map { ($0.0, $0.1, 1) }
        }
        if extraLayers >= 2 {
            let count = max(6, min(inward.count, (inward.count * layer2Fraction) / 4))
            positions += inward.prefix(count).map { ($0.0, $0.1, 2) }
        }
        if extraLayers >= 3 {
            let count = max(6, min(inward.count, inward.count / layer3Fraction))
            positions += inward.prefix(count).map { ($0.0, $0.1, 3) }
        }
        
        return snappedToMultipleOfThree(positions)
    }
    
    private func snappedToMultipleOfThree(_ positions: [TilePos]) -> [TilePos] {
        var result = positions
        let extra = result.count % 3
        guard extra != 0 else { return result }
        
        let high = result.map(\.layer).max() ?? 0
        var removed = 0
        result.removeAll { pos in
            guard removed < extra, pos.layer == high else { return false }
            removed += 1
            return true
        }
        while result.count % 3 != 0 && !result.isEmpty {
            result.removeLast()
        }
        return result
    }
    
    // MARK: - Free tile logic
    private func updateFreeTiles() {
        struct Pos: Hashable {
            let r: Int
            let c: Int
        }

        var maxLayerAt = [Pos: Int]()
        maxLayerAt.reserveCapacity(board.count)

        for tile in board {
            let pos = Pos(r: tile.row, c: tile.col)
            if let currentMax = maxLayerAt[pos] {
                if tile.layer > currentMax {
                    maxLayerAt[pos] = tile.layer
                }
            } else {
                maxLayerAt[pos] = tile.layer
            }
        }

        for i in board.indices {
            let tile = board[i]
            var isCovered = false
            
            for dr in -1...1 {
                for dc in -1...1 {
                    let pos = Pos(r: tile.row + dr, c: tile.col + dc)
                    if let maxLayer = maxLayerAt[pos], maxLayer > tile.layer {
                        isCovered = true
                        break
                    }
                }
                if isCovered { break }
            }
            
            board[i].isFree = !isCovered
        }
    }
    
    func select(_ tile: BoardTile) {
        guard !isGameOver,
              tile.isFree,
              allTrayTiles.count < totalTrayCapacity,
              let index = board.firstIndex(where: { $0.id == tile.id }) else { return }
        
        let moved = board.remove(at: index)
        if tray.count < maxTraySize {
            tray.append(moved)
        } else {
            overflowTray.append(moved)
        }
        hasPlacedInTrayThisLevel = true
        lastUndoableTileID = moved.id
        
        updateFreeTiles()
        checkForMatch()
        if let id = lastUndoableTileID, !allTrayTiles.contains(where: { $0.id == id }) {
            lastUndoableTileID = nil
        }
        checkWinLose()
    }
    
    func undoLastMove() {
        guard canUndo, let id = lastUndoableTileID else { return }
        
        let tile: BoardTile
        if let overflowIndex = overflowTray.firstIndex(where: { $0.id == id }) {
            tile = overflowTray.remove(at: overflowIndex)
        } else if let trayIndex = tray.firstIndex(where: { $0.id == id }) {
            tile = tray.remove(at: trayIndex)
        } else {
            return
        }
        board.append(tile)
        lastUndoableTileID = nil
        undosRemaining -= 1
        updateFreeTiles()
        statusMessage = "Undo! (\(undosRemaining) left)"
    }
    
    private func checkForMatch() {
        let allTiles = allTrayTiles
        var matchedIcon: String?
        
        for i in 0..<allTiles.count {
            let iconName = allTiles[i].iconName
            var count = 1
            for j in (i + 1)..<allTiles.count {
                if allTiles[j].iconName == iconName {
                    count += 1
                    if count == 3 {
                        matchedIcon = iconName
                        break
                    }
                }
            }
            if matchedIcon != nil { break }
        }

        if let icon = matchedIcon {
            var removedCount = 0
            tray.removeAll {
                guard removedCount < 3, $0.iconName == icon else { return false }
                removedCount += 1
                return true
            }
            overflowTray.removeAll {
                guard removedCount < 3, $0.iconName == icon else { return false }
                removedCount += 1
                return true
            }
            score += 10
            justMatched = true
            if tray.isEmpty && overflowTray.isEmpty && !board.isEmpty && hasPlacedInTrayThisLevel {
                score += 5
                justClearedTray = true
                statusMessage = "Matched 3!  +10   Tray +5"
            } else {
                statusMessage = "Matched 3!  +10"
            }
            updateHighScoreIfNeeded()
            return
        }
    }
    
    private func checkWinLose() {
        if board.isEmpty {
            didWin = true
            isGameOver = true
            statusMessage = "Level Complete!"
            recordLevelCompleted()
            updateHighScoreIfNeeded()
        } else if allTrayTiles.count >= totalTrayCapacity {
            lives -= 1
            isGameOver = true
            didWin = false
            statusMessage = lives <= 0 ? "Game Over" : "Tray full – try again"
            updateHighScoreIfNeeded()
        }
    }
    
    func shuffleBoard() {
        guard shufflesRemaining > 0, !isGameOver, board.count >= 2 else { return }
        
        // Keep the same stacked slots so the same number of tiles stay covered.
        var slots = board.map { TilePos(row: $0.row, col: $0.col, layer: $0.layer) }
        slots.shuffle()
        
        var tiles = board
        tiles.shuffle()
        for i in tiles.indices {
            tiles[i].row = slots[i].row
            tiles[i].col = slots[i].col
            tiles[i].layer = slots[i].layer
        }
        
        board = tiles
        updateFreeTiles()
        shufflesRemaining -= 1
        statusMessage = "Board shuffled! (\(shufflesRemaining) left)"
    }
    
    private func recordLevelCompleted() {
        totalLevelsCompleted += 1
        UserDefaults.standard.set(totalLevelsCompleted, forKey: Self.totalLevelsKey)
        
        if totalLevelsCompleted > 0 && totalLevelsCompleted % 10 == 0 {
            addToLifeBank(1)
            justEarnedBankLife = true
            UserDefaults.standard.set(true, forKey: Self.pendingBankHighlightKey)
            statusMessage = "Level Complete!  Life Bank +1"
        }
    }
    
    func restart() {
        startNewLevel()
    }
    
    func advanceToNextLevel() {
        level += 1
        startNewLevel()
    }
    
    func applyBonusRewards(afterCompletingLevel _: Int) {
        // Shuffle, banked life, and Extra Undo are already applied by
        // startNewLevel() / recordLevelCompleted() / undosForCurrentLevel.
    }
    
    func addBonusPoints(_ points: Int) {
        guard points > 0 else { return }
        score += points
        updateHighScoreIfNeeded()
    }
    
    func loseLifeAndRestart() {
        startNewLevel()
    }
    
    func fullReset() {
        lives = 3
        score = 0
        level = 1
        isNewHighScore = false
        undosRemaining = 2
        shufflesRemaining = 1
        lastUndoableTileID = nil
        startNewLevel()
    }
}
