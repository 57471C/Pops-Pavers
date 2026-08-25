import Foundation

struct BoardTile: Identifiable, Equatable {
    let id = UUID()
    let iconName: String
    let paverName: String
    var row: Int
    var col: Int
    var layer: Int
    var isFree: Bool = true
}

class GameState {
    var board: [BoardTile] = []

    // Original O(N^2) method
    func updateFreeTilesOriginal() {
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

    // Optimized O(N) method
    func updateFreeTilesOptimized() {
        struct Pos: Hashable {
            let r: Int
            let c: Int
        }

        var maxLayerAt = [Pos: Int]()
        // Depending on average board size, reserveCapacity can help
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

            // Check 3x3 grid around the tile
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
}

// Generate a random board
let gs = GameState()
for layer in 0..<5 {
    for row in 0..<10 {
        for col in 0..<10 {
            // Randomly place tiles
            if Int.random(in: 0..<100) < 30 {
                gs.board.append(BoardTile(iconName: "", paverName: "", row: row, col: col, layer: layer))
            }
        }
    }
}

print("Board size: \(gs.board.count)")

// Benchmark Original
let startOriginal = Date()
for _ in 0..<1000 {
    gs.updateFreeTilesOriginal()
}
let durationOriginal = Date().timeIntervalSince(startOriginal)
print("Original duration: \(durationOriginal) seconds")

// Verify they produce the same result
gs.updateFreeTilesOriginal()
let originalResult = gs.board.map { $0.isFree }

// Benchmark Optimized
let startOptimized = Date()
for _ in 0..<1000 {
    gs.updateFreeTilesOptimized()
}
let durationOptimized = Date().timeIntervalSince(startOptimized)
print("Optimized duration: \(durationOptimized) seconds")

gs.updateFreeTilesOptimized()
let optimizedResult = gs.board.map { $0.isFree }

print("Results match: \(originalResult == optimizedResult)")

