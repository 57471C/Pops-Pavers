import Foundation
import SwiftUI

@Observable
class GameState {
    var board: [BoardTile] = []
    var tray: [BoardTile] = []
    var statusMessage = "Clear the covered tiles"
    var isGameOver = false
    var didWin = false
    
    let maxTraySize = 7
    let columns = 4
    let rows = 3
    
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
    }
    
    // MARK: - Level generation (simple layered + some randomness)
    private func generateLevel() -> [BoardTile] {
        var tiles: [BoardTile] = []
        
        // Base layer (layer 0)
        let baseTypes = TileType.allCases.shuffled()
        for row in 0..<rows {
            for col in 0..<columns {
                let type = baseTypes[(row * columns + col) % baseTypes.count]
                tiles.append(BoardTile(type: type, row: row, col: col, layer: 0))
            }
        }
        
        // Add a second layer on some positions (randomly)
        let extraCount = Int.random(in: 4...7)
        for _ in 0..<extraCount {
            let row = Int.random(in: 0..<rows)
            let col = Int.random(in: 0..<columns)
            let type = TileType.allCases.randomElement()!
            tiles.append(BoardTile(type: type, row: row, col: col, layer: 1))
        }
        
        // Make sure we have multiples of 3 overall (roughly)
        // (We'll keep it simple for now)
        
        return tiles
    }
    
    // MARK: - Free tile logic
    private func updateFreeTiles() {
        for i in board.indices {
            let tile = board[i]
            // A tile is free if no other tile is on the same position with a higher layer
            let isCovered = board.contains { other in
                other.id != tile.id &&
                other.row == tile.row &&
                other.col == tile.col &&
                other.layer > tile.layer
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
        
        updateFreeTiles()          // important – some tiles may now become free
        checkForMatch()
        checkWinLose()
    }
    
    private func checkForMatch() {
        let counts = Dictionary(grouping: tray, by: { $0.type })
        
        for (type, group) in counts {
            if group.count >= 3 {
                var removed = 0
                tray.removeAll { tile in
                    if tile.type == type && removed < 3 {
                        removed += 1
                        return true
                    }
                    return false
                }
                statusMessage = "Matched 3 \(type.symbol)"
                return
            }
        }
    }
    
    private func checkWinLose() {
        if board.isEmpty && tray.isEmpty {
            didWin = true
            isGameOver = true
            statusMessage = "Level cleared! 🎉"
        } else if tray.count >= maxTraySize {
            isGameOver = true
            statusMessage = "Tray full – try again"
        }
    }
    
    func restart() {
        startNewLevel()
    }
}
