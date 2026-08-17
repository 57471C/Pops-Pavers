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
    // MARK: - Level Generation (controlled complexity)

    private func generateLevel() -> [BoardTile] {
        var tiles: [BoardTile] = []
        
        func add(_ type: TileType, row: Int, col: Int, layer: Int) {
            tiles.append(BoardTile(type: type, row: row, col: col, layer: layer))
        }
        
        // We work on a conceptual 6x5 grid of positions
        // Each tile still occupies one "slot" but we offset them for overlaps
        
        let patterns: [[(row: Int, col: Int, layer: Int)]] = [
            // Pattern A – classic stack + side overlap
            [
                (1,1,0), (1,2,0), (1,3,0),
                (2,1,0), (2,2,0),
                (1,2,1), (2,2,1)          // two tiles sitting on top with overlap
            ],
            // Pattern B – wider base with corner sits
            [
                (0,0,0), (0,1,0), (0,2,0), (0,3,0),
                (1,0,0), (1,1,0), (1,2,0),
                (0,1,1), (1,1,1)          // overlapping upper layer
            ],
            // Pattern C – more vertical
            [
                (0,2,0), (1,1,0), (1,2,0), (1,3,0),
                (2,1,0), (2,2,0), (2,3,0),
                (1,2,1), (2,2,1)
            ]
        ]
        
        // Pick 1 or 2 patterns and merge them with an offset
        let chosen = patterns.shuffled().prefix(Int.random(in: 1...2))
        
        var typePool = TileType.allCases.shuffled()
        var typeIndex = 0
        
        for (patternIndex, pattern) in chosen.enumerated() {
            let rowOffset = patternIndex * 3
            let colOffset = patternIndex * 1
            
            for pos in pattern {
                let type = typePool[typeIndex % typePool.count]
                typeIndex += 1
                add(type, row: pos.row + rowOffset, col: pos.col + colOffset, layer: pos.layer)
            }
        }
        
        return tiles
    }
    // MARK: - Free tile logic
    private func updateFreeTiles() {
        for i in board.indices {
            let tile = board[i]
            
            // Strict for now: only blocked by a higher tile on the exact same cell
            // (We can expand this later once the visuals are solid)
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
