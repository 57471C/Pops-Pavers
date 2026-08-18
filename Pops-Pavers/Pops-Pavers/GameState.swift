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
    
    let maxTraySize = 7
    
    init() {
        startNewLevel()
    }
    
    func startNewLevel() {
        board = generateLevel()
        updateFreeTiles()
        tray = []
        statusMessage = "Only free (bright) tiles can be selected"
        isGameOver = false
        didWin = false
        shufflesRemaining = 2
    }
    
    // MARK: - Level generation
    private func generateLevel() -> [BoardTile] {
        var tiles: [BoardTile] = []
        
        func add(icon: String, paver: String, row: Int, col: Int, layer: Int) {
            tiles.append(BoardTile(iconName: icon, paverName: paver, row: row, col: col, layer: layer))
        }
        
        // Balanced pool – every icon in multiples of 3
        var typePool: [String] = []
        let availableIcons = ["icon-1", "icon-2", "icon-3", "icon-4", "icon-5"]
        
        for icon in availableIcons {
            let count = 3 * Int.random(in: 1...3) // 3, 6 or 9
            typePool += Array(repeating: icon, count: count)
        }
        typePool.shuffle()
        
        var iconIndex = 0
        func nextIcon() -> String {
            let icon = typePool[iconIndex % typePool.count]
            iconIndex += 1
            return icon
        }
        
        let pavers = (1...6).map { "paver-\($0)" }
        
        // Layer 0
        for row in 0...3 {
            for col in 0...5 {
                if (row == 0 || row == 3) && (col == 0 || col == 5) { continue }
                add(icon: nextIcon(),
                    paver: pavers.randomElement()!,
                    row: row, col: col, layer: 0)
            }
        }
        
        // Layer 1
        let layer1 = [
            (0,2), (0,3),
            (1,1), (1,2), (1,3), (1,4),
            (2,1), (2,2), (2,3), (2,4),
            (3,2), (3,3)
        ]
        for pos in layer1 {
            add(icon: nextIcon(),
                paver: pavers.randomElement()!,
                row: pos.0, col: pos.1, layer: 1)
        }
        
        // Layer 2
        let layer2 = [(1,2), (1,3), (2,2), (2,3)]
        for pos in layer2 {
            add(icon: nextIcon(),
                paver: pavers.randomElement()!,
                row: pos.0, col: pos.1, layer: 2)
        }
        
        return tiles
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
                statusMessage = "Matched 3!"
                return
            }
        }
    }
    
    private func checkWinLose() {
        if board.isEmpty {
            // Board cleared = win (even if a few tiles remain in tray we still count it as success for now)
            didWin = true
            isGameOver = true
            statusMessage = "Level Complete!"
        } else if tray.count >= maxTraySize {
            isGameOver = true
            didWin = false
            statusMessage = "Tray full – try again"
        }
    }
    
    // MARK: - Shuffle
    func shuffleTray() {
        guard shufflesRemaining > 0, !tray.isEmpty else { return }
        
        tray.shuffle()
        shufflesRemaining -= 1
        statusMessage = "Tray shuffled! (\(shufflesRemaining) left)"
    }
    
    func restart() {
        startNewLevel()
    }
}
