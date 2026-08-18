import Foundation
import SwiftUI

@Observable
class GameState {
    var board: [BoardTile] = []
    var tray: [BoardTile] = []
    var statusMessage = "Clear the covered tiles"
    var isGameOver = false
    var didWin = false
    var shufflesRemaining = 2
    var justMatched = false
    var lives = 3
    var score = 0
    var level = 1
    var highScore = 0
    var isNewHighScore = false
    
    let maxTraySize = 7
    private static let highScoreKey = "highScore"
    
    var availableIconCount: Int {
        min(20, 5 + (level - 1) / 5)
    }
    
    init() {
        highScore = UserDefaults.standard.integer(forKey: Self.highScoreKey)
        startNewLevel()
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
        shufflesRemaining = 2
        justMatched = false
        // don’t reset lives or score here – only reset on full restart / returning to title
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
    
    private func layoutPositions(for level: Int) -> [TilePos] {
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
        case 9, 10:
            return rect(rows: 0...3, cols: 0...5, layer: 0)
                + [(0, 2, 1), (0, 3, 1),
                   (1, 1, 1), (1, 2, 1), (1, 3, 1), (1, 4, 1),
                   (2, 1, 1), (2, 2, 1), (2, 3, 1), (2, 4, 1),
                   (3, 2, 1), (3, 3, 1)]
                + [(1, 1, 2), (1, 2, 2), (1, 3, 2), (2, 2, 2), (2, 3, 2), (2, 4, 2)]
        case 11, 12, 13:
            return rect(rows: 0...3, cols: 0...5, layer: 0)
                + rect(rows: 0...3, cols: 1...4, layer: 1)
                + [(0, 2, 2), (0, 3, 2), (1, 1, 2), (1, 2, 2),
                   (1, 3, 2), (2, 2, 2), (2, 3, 2), (3, 2, 2)]
        case 14, 15:
            return rect(rows: 0...3, cols: 0...5, layer: 0)
                + rect(rows: 0...3, cols: 1...4, layer: 1)
                + rect(rows: 1...2, cols: 1...4, layer: 2)
        default:
            if level <= 20 {
                return rect(rows: 0...3, cols: 0...5, layer: 0)
                    + rect(rows: 0...3, cols: 1...4, layer: 1)
                    + [(0, 2, 2), (0, 3, 2), (1, 1, 2), (1, 2, 2), (1, 3, 2),
                       (1, 4, 2), (2, 1, 2), (2, 2, 2), (2, 3, 2), (3, 2, 2)]
                    + [(1, 2, 3), (1, 3, 3), (2, 2, 3), (2, 3, 3)]
            }
            return rect(rows: 0...3, cols: 0...5, layer: 0)
                + rect(rows: 0...3, cols: 1...5, layer: 1, skip: ["0,5", "3,5"])
                + rect(rows: 0...2, cols: 1...4, layer: 2)
                + [(1, 1, 3), (1, 2, 3), (1, 3, 3), (2, 1, 3), (2, 2, 3), (2, 3, 3)]
        }
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
        
        updateFreeTiles()
        checkForMatch()
        checkWinLose()
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
            updateHighScoreIfNeeded()
        } else if tray.count >= maxTraySize {
            lives -= 1
            isGameOver = true
            didWin = false
            statusMessage = lives <= 0 ? "Game Over" : "Tray full – try again"
            updateHighScoreIfNeeded()
        }
    }
    
    func shuffleTray() {
        guard shufflesRemaining > 0, !tray.isEmpty else { return }
        tray.shuffle()
        shufflesRemaining -= 1
        statusMessage = "Tray shuffled! (\(shufflesRemaining) left)"
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
        startNewLevel()
    }
}
