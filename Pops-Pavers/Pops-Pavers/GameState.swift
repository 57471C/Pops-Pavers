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
        
        func add(_ type: TileType, row: Int, col: Int, layer: Int) {
            tiles.append(BoardTile(type: type, row: row, col: col, layer: layer))
        }
        
        // Create a balanced pool (multiples of 3)
        var typePool: [TileType] = []
        for type in TileType.allCases {
            let count = 3 * Int.random(in: 1...2)   // 3 or 6 of each
            typePool += Array(repeating: type, count: count)
        }
        typePool.shuffle()
        
        var index = 0
        func nextType() -> TileType {
            defer { index += 1 }
            return typePool[index % typePool.count]
        }
        
        // ===== One solid layout for now (we can expand later) =====
        // Layer 0 - solid base
        for row in 0...3 {
            for col in 0...5 {
                if (row == 0 || row == 3) && (col == 0 || col == 5) { continue } // slightly shape it
                add(nextType(), row: row, col: col, layer: 0)
            }
        }
        
        // Layer 1 - offset stacks
        let layer1Positions = [
            (0,2), (0,3),
            (1,1), (1,2), (1,3), (1,4),
            (2,1), (2,2), (2,3), (2,4),
            (3,2), (3,3)
        ]
        
        for pos in layer1Positions {
            if index < typePool.count {
                add(nextType(), row: pos.0, col: pos.1, layer: 1)
            }
        }
        
        // Layer 2 - top pieces
        let layer2Positions = [(1,2), (1,3), (2,2), (2,3)]
        for pos in layer2Positions {
            if index < typePool.count {
                add(nextType(), row: pos.0, col: pos.1, layer: 2)
            }
        }
        
        return tiles
    }
    
    
    // MARK: - Free tile logic
    private func updateFreeTiles() {
        for i in board.indices {
            let tile = board[i]
            
            let isCovered = board.contains { other in
                guard other.id != tile.id && other.layer > tile.layer else { return false }
                
                // Higher tile blocks a small area (allows one tile to cover multiple below)
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
