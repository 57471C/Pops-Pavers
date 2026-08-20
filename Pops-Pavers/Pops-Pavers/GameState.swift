import Foundation
import SwiftUI

@Observable
class GameState {
    var board: [BoardTile] = []
    var tray: [BoardTile] = []
    var statusMessage = "Clear the covered tiles"
    var isGameOver = false
    var didWin = false
    var shufflesRemaining = 1
    var undosRemaining = 2
    var lastUndoableTileID: UUID?
    var justMatched = false
    var lives = 3
    var score = 0
    var level = 1
    var highScore = 0
    var isNewHighScore = false
    var lifeBank = 0
    var totalLevelsCompleted = 0
    var justEarnedBankLife = false
    
    let maxTraySize = 7
    private static let highScoreKey = "highScore"
    private static let lifeBankKey = "lifeBank"
    private static let totalLevelsKey = "totalLevelsCompleted"
    static let pendingBankHighlightKey = "pendingBankLifeHighlight"
    
    var canUndo: Bool {
        guard undosRemaining > 0, !isGameOver, let id = lastUndoableTileID else { return false }
        return tray.contains(where: { $0.id == id })
    }
    
    var availableIconCount: Int {
        min(20, 5 + (level - 1) / 5)
    }
    
    var backgroundName: String {
        backgroundName(for: level)
    }
    
    func backgroundName(for level: Int) -> String {
        let names = [
            "game-background",
            "game-background-1",
            "game-background-2",
            "game-background-3",
            "game-background-4"
        ]
        let index = (max(1, level) - 1) / 10
        return names[index % names.count]
    }
    
    init() {
        highScore = UserDefaults.standard.integer(forKey: Self.highScoreKey)
        lifeBank = UserDefaults.standard.integer(forKey: Self.lifeBankKey)
        totalLevelsCompleted = UserDefaults.standard.integer(forKey: Self.totalLevelsKey)
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
        statusMessage = "Level \(level) – match 3 tiles"
        isGameOver = false
        didWin = false
        justMatched = false
        justEarnedBankLife = false
        lastUndoableTileID = nil
        // don’t reset lives, score, shuffles, life bank, or undos here – only reset those on full restart / title
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
        case 11...15: extraLayers = 1
        case 16...25: extraLayers = 2
        default: extraLayers = 3
        }
        return stackedShape(pickShape(for: level), extraLayers: extraLayers)
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
                (0, 1), (0, 4),
                (1, 1), (1, 2), (1, 3), (1, 4),
                (2, 1), (2, 2), (2, 3), (2, 4),
                (3, 1), (3, 4)
            ]
        case .plus:
            return [
                (0, 2), (0, 3),
                (1, 1), (1, 2), (1, 3), (1, 4),
                (2, 1), (2, 2), (2, 3), (2, 4),
                (3, 2), (3, 3)
            ]
        case .ring:
            return [
                (0, 1), (0, 2), (0, 3), (0, 4),
                (1, 0), (1, 5),
                (2, 0), (2, 5),
                (3, 1), (3, 2), (3, 3), (3, 4)
            ]
        case .diamond:
            return [
                (0, 3),
                (1, 2), (1, 3), (1, 4),
                (2, 1), (2, 2), (2, 3), (2, 4), (2, 5),
                (3, 2), (3, 3), (3, 4)
            ]
        case .frame:
            return [
                (0, 0), (0, 1), (0, 2), (0, 3), (0, 4), (0, 5),
                (1, 0), (1, 5),
                (2, 0), (2, 5),
                (3, 0), (3, 1), (3, 2), (3, 3), (3, 4), (3, 5)
            ]
        }
    }
    
    private func stackedShape(_ shape: BoardShape, extraLayers: Int) -> [TilePos] {
        let base = shapeCells(shape)
        var positions: [TilePos] = base.map { ($0.0, $0.1, 0) }
        
        let inward = base.sorted {
            let da = hypot(Double($0.0) - 1.5, Double($0.1) - 2.5)
            let db = hypot(Double($1.0) - 1.5, Double($1.1) - 2.5)
            return da < db
        }
        
        if extraLayers >= 1 {
            let count = max(3, min(inward.count, (inward.count * 2) / 3))
            positions += inward.prefix(count).map { ($0.0, $0.1, 1) }
        }
        if extraLayers >= 2 {
            let count = max(3, min(inward.count, inward.count / 2))
            positions += inward.prefix(count).map { ($0.0, $0.1, 2) }
        }
        if extraLayers >= 3 {
            let count = max(3, min(inward.count, inward.count / 3))
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
        for i in board.indices {
            let tile = board[i]
            
            let isCovered = board.contains { other in
                guard other.id != tile.id && other.layer > tile.layer else { return false }
                
                let rowDiff = abs(other.row - tile.row)
                let colDiff = abs(other.col - tile.col)
                
                return rowDiff <= 1 && colDiff <= 1
            }
            
            board[i].isFree = !isCovered
        }
    }
    
    func select(_ tile: BoardTile) {
        guard !isGameOver,
              tile.isFree,
              tray.count < maxTraySize,
              let index = board.firstIndex(where: { $0.id == tile.id }) else { return }
        
        let moved = board.remove(at: index)
        tray.append(moved)
        lastUndoableTileID = moved.id
        
        updateFreeTiles()
        checkForMatch()
        if let id = lastUndoableTileID, !tray.contains(where: { $0.id == id }) {
            lastUndoableTileID = nil
        }
        checkWinLose()
    }
    
    func undoLastMove() {
        guard canUndo, let id = lastUndoableTileID,
              let trayIndex = tray.firstIndex(where: { $0.id == id }) else { return }
        
        let tile = tray.remove(at: trayIndex)
        board.append(tile)
        lastUndoableTileID = nil
        undosRemaining -= 1
        updateFreeTiles()
        statusMessage = "Undo! (\(undosRemaining) left)"
    }
    
    private func checkForMatch() {
        let counts = Dictionary(grouping: tray, by: { $0.iconName })
        
        for (iconName, group) in counts {
            if group.count >= 3 {
                var removed = 0
                tray.removeAll { tile in
                    if tile.iconName == iconName && removed < 3 {
                        removed += 1
                        return true
                    }
                    return false
                }
                score += 10
                statusMessage = "Matched 3!  +10"
                justMatched = true
                updateHighScoreIfNeeded()
                return
            }
        }
    }
    
    private func checkWinLose() {
        if board.isEmpty {
            didWin = true
            isGameOver = true
            statusMessage = "Level Complete!"
            recordLevelCompleted()
            updateHighScoreIfNeeded()
        } else if tray.count >= maxTraySize {
            lives -= 1
            isGameOver = true
            didWin = false
            statusMessage = lives <= 0 ? "Game Over" : "Tray full – try again"
            updateHighScoreIfNeeded()
        }
    }
    
    func shuffleBoard() {
        guard shufflesRemaining > 0, !isGameOver, board.count >= 2 else { return }
        
        var tiles = board
        tiles.shuffle()
        
        let slots = shuffledSlots(count: tiles.count)
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
    
    private func shuffledSlots(count: Int) -> [TilePos] {
        var slots = layoutPositions(for: level)
        
        if slots.count < count {
            slots = board.map { ($0.row, $0.col, $0.layer) }
        }
        
        slots.shuffle()
        slots.sort { $0.layer < $1.layer }
        return Array(slots.prefix(count))
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
        
        if level > 0 && level % 10 == 0 {
            shufflesRemaining += 1
            if statusMessage.contains("Life Bank") {
                statusMessage += "  Reshuffle +1"
            } else {
                statusMessage = "Level Complete!  Reshuffle +1"
            }
        }
    }
    
    func restart() {
        startNewLevel()
    }
    
    func advanceToNextLevel() {
        level += 1
        startNewLevel()
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
