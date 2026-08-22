import Foundation
import SwiftUI

enum FlowColor: String, CaseIterable, Codable, Hashable {
    case red
    case blue
    case green
    case yellow
    case orange
    case cyan
    case purple
    
    var uiColor: Color {
        switch self {
        case .red:    Color(red: 0.90, green: 0.22, blue: 0.21)
        case .blue:   Color(red: 0.20, green: 0.48, blue: 0.90)
        case .green:  Color(red: 0.22, green: 0.72, blue: 0.35)
        case .yellow: Color(red: 0.95, green: 0.80, blue: 0.18)
        case .orange: Color(red: 0.95, green: 0.52, blue: 0.16)
        case .cyan:   Color(red: 0.18, green: 0.78, blue: 0.82)
        case .purple: Color(red: 0.62, green: 0.32, blue: 0.82)
        }
    }
    
    var hoseStraightAsset: String { "hose-\(rawValue)-h" }
    var hoseInsideAsset: String { "hose-\(rawValue)-inside" }
    var hoseOutsideAsset: String { "hose-\(rawValue)-outside" }
    var tapAsset: String { "tap-\(rawValue)" }
}

struct GridPos: Hashable, Codable {
    var row: Int
    var col: Int
    
    func isAdjacent(to other: GridPos) -> Bool {
        abs(row - other.row) + abs(col - other.col) == 1
    }
    
    var neighbors: [GridPos] {
        [
            GridPos(row: row - 1, col: col),
            GridPos(row: row + 1, col: col),
            GridPos(row: row, col: col - 1),
            GridPos(row: row, col: col + 1)
        ]
    }
    
    /// Side of `self` that opens toward an adjacent cell.
    func opening(toward other: GridPos) -> FlowDir? {
        guard isAdjacent(to: other) else { return nil }
        if other.row == row {
            return other.col < col ? .left : .right
        }
        return other.row < row ? .up : .down
    }
}

enum FlowDir: String, Hashable, CaseIterable {
    case left, right, up, down
}

struct FlowPair: Hashable, Codable {
    var color: FlowColor
    var start: GridPos
    var end: GridPos
    
    init(_ color: FlowColor, _ r1: Int, _ c1: Int, _ r2: Int, _ c2: Int) {
        self.color = color
        self.start = GridPos(row: r1, col: c1)
        self.end = GridPos(row: r2, col: c2)
    }
}

enum FlowDifficulty: String, CaseIterable, Identifiable {
    case easy
    case medium
    case hard
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .easy: "Easy"
        case .medium: "Medium"
        case .hard: "Hard"
        }
    }
    
    var gridLabel: String {
        switch self {
        case .easy: "5×5"
        case .medium: "6×6"
        case .hard: "7×7"
        }
    }
    
    var levels: [FlowLevel] {
        switch self {
        case .easy: FlowLevel.easy
        case .medium: FlowLevel.medium
        case .hard: FlowLevel.hard
        }
    }
    
    /// Bonus after completing main levels 5, 10, 15, 20, 25, …
    static func triggered(afterCompletingMainLevel level: Int) -> FlowDifficulty? {
        guard level >= 5, level % 5 == 0 else { return nil }
        switch level {
        case 5: return .easy
        case 10, 15: return .medium
        default: return .hard
        }
    }
}

struct BonusReward: Identifiable, Equatable, Hashable {
    var id: String
    var title: String
    var imageName: String?
    var systemImage: String?
    
    /// Icon count used on a given main-game level (`icon-1` … `icon-20`).
    static func iconCount(forMainLevel level: Int) -> Int {
        min(20, 5 + (max(1, level) - 1) / 5)
    }
    
    /// The paver icon that unlocks when starting the next main level.
    static func unlockedIconName(afterCompletingMainLevel level: Int) -> String? {
        let current = iconCount(forMainLevel: level)
        let next = iconCount(forMainLevel: level + 1)
        guard next > current else { return nil }
        return "icon-\(next)"
    }
    
    static func rewards(afterCompletingMainLevel level: Int) -> [BonusReward] {
        var items: [BonusReward] = []
        if let icon = unlockedIconName(afterCompletingMainLevel: level) {
            items.append(
                BonusReward(id: "icon", title: "New Paver Added", imageName: icon)
            )
        }
        if level % 10 == 0 {
            items.append(
                BonusReward(id: "shuffle", title: "Extra Shuffle Added", systemImage: "arrow.2.squarepath")
            )
            items.append(
                BonusReward(id: "life", title: "Banked Life +1", systemImage: "heart.fill")
            )
        } else {
            items.append(
                BonusReward(id: "undo", title: "Extra Undo Added", systemImage: "arrow.uturn.backward")
            )
        }
        return items
    }
}

struct FlowLevel: Identifiable, Hashable, Codable {
    var id: Int
    var size: Int
    var pairs: [FlowPair]
    
    static let easy: [FlowLevel] = [
        FlowLevel(
            id: 1,
            size: 5,
            pairs: [
                FlowPair(.red,    0, 1, 2, 0),
                FlowPair(.orange, 1, 1, 3, 2),
                FlowPair(.blue,   1, 3, 2, 2),
                FlowPair(.yellow, 2, 1, 4, 0),
                FlowPair(.green,  4, 1, 4, 4)
            ]
        ),
        FlowLevel(
            id: 2,
            size: 5,
            pairs: [
                FlowPair(.blue,   1, 0, 3, 1),
                FlowPair(.green,  1, 1, 1, 3),
                FlowPair(.red,    2, 0, 3, 3),
                FlowPair(.yellow, 3, 4, 4, 3)
            ]
        ),
        FlowLevel(
            id: 3,
            size: 5,
            pairs: [
                FlowPair(.blue,   0, 0, 2, 3),
                FlowPair(.yellow, 0, 3, 2, 0),
                FlowPair(.green,  1, 0, 2, 2),
                FlowPair(.red,    3, 1, 3, 3)
            ]
        )
    ]
    
    static let medium: [FlowLevel] = [
        FlowLevel(
            id: 4,
            size: 6,
            pairs: [
                FlowPair(.blue,   0, 2, 2, 3),
                FlowPair(.yellow, 0, 3, 1, 5),
                FlowPair(.orange, 1, 1, 3, 2),
                FlowPair(.green,  1, 2, 4, 4),
                FlowPair(.red,    2, 5, 4, 0)
            ]
        ),
        FlowLevel(
            id: 5,
            size: 6,
            pairs: [
                FlowPair(.green,  0, 0, 1, 2),
                FlowPair(.red,    0, 2, 4, 3),
                FlowPair(.cyan,   0, 5, 5, 5),
                FlowPair(.orange, 1, 0, 1, 3),
                FlowPair(.yellow, 3, 1, 4, 4),
                FlowPair(.blue,   3, 2, 4, 1)
            ]
        ),
        FlowLevel(
            id: 6,
            size: 6,
            pairs: [
                FlowPair(.blue,   1, 0, 3, 5),
                FlowPair(.red,    1, 1, 2, 0),
                FlowPair(.yellow, 1, 2, 4, 1),
                FlowPair(.orange, 1, 3, 4, 4),
                FlowPair(.green,  2, 3, 3, 0),
                FlowPair(.cyan,   4, 5, 5, 3)
            ]
        ),
        FlowLevel(
            id: 7,
            size: 6,
            pairs: [
                FlowPair(.blue,   0, 0, 1, 1),
                FlowPair(.red,    0, 1, 2, 1),
                FlowPair(.orange, 0, 3, 2, 3),
                FlowPair(.cyan,   0, 4, 5, 0),
                FlowPair(.green,  0, 5, 5, 1),
                FlowPair(.yellow, 2, 0, 3, 3)
            ]
        )
    ]
    
    static let hard: [FlowLevel] = [
        FlowLevel(
            id: 8,
            size: 7,
            pairs: [
                FlowPair(.yellow, 0, 3, 6, 0),
                FlowPair(.cyan,   1, 5, 4, 5),
                FlowPair(.green,  3, 5, 4, 3),
                FlowPair(.red,    3, 6, 6, 1),
                FlowPair(.blue,   4, 6, 6, 6),
                FlowPair(.orange, 5, 5, 6, 2)
            ]
        ),
        FlowLevel(
            id: 9,
            size: 7,
            pairs: [
                FlowPair(.cyan,   1, 0, 2, 3),
                FlowPair(.red,    1, 1, 1, 3),
                FlowPair(.green,  1, 5, 2, 4),
                FlowPair(.purple, 2, 2, 6, 4),
                FlowPair(.yellow, 3, 2, 5, 4),
                FlowPair(.orange, 4, 2, 6, 6),
                FlowPair(.blue,   3, 6, 5, 6)
            ]
        ),
        FlowLevel(
            id: 10,
            size: 7,
            pairs: [
                FlowPair(.red,    0, 0, 1, 3),
                FlowPair(.green,  1, 2, 2, 0),
                FlowPair(.blue,   1, 4, 3, 2),
                FlowPair(.purple, 1, 5, 5, 0),
                FlowPair(.cyan,   4, 5, 5, 1),
                FlowPair(.orange, 4, 6, 6, 0),
                FlowPair(.yellow, 5, 2, 5, 5)
            ]
        )
    ]
}

enum FlowCell: Equatable {
    case empty
    case endpoint(FlowColor)
    case pipe(FlowColor)
    
    var color: FlowColor? {
        switch self {
        case .empty: return nil
        case .endpoint(let color), .pipe(let color): return color
        }
    }
    
    var isEndpoint: Bool {
        if case .endpoint = self { return true }
        return false
    }
}

@Observable
class FlowGameState {
    var level: FlowLevel
    var grid: [[FlowCell]] = []
    var paths: [FlowColor: [GridPos]] = [:]
    var activeColor: FlowColor?
    var moves = 0
    var isComplete = false
    
    var size: Int { level.size }
    
    var connectedFlowCount: Int {
        level.pairs.filter { isPairConnected($0) }.count
    }
    
    init(level: FlowLevel = FlowLevel.easy[0]) {
        self.level = level
        load(level)
    }
    
    func load(_ level: FlowLevel) {
        self.level = level
        paths = [:]
        activeColor = nil
        moves = 0
        isComplete = false
        grid = Array(
            repeating: Array(repeating: FlowCell.empty, count: level.size),
            count: level.size
        )
        for pair in level.pairs {
            setCell(pair.start, to: .endpoint(pair.color))
            setCell(pair.end, to: .endpoint(pair.color))
        }
    }
    
    func reset() {
        load(level)
    }
    
    func inBounds(_ pos: GridPos) -> Bool {
        pos.row >= 0 && pos.row < size && pos.col >= 0 && pos.col < size
    }
    
    func cell(at pos: GridPos) -> FlowCell {
        guard inBounds(pos) else { return .empty }
        return grid[pos.row][pos.col]
    }
    
    func endpointColor(at pos: GridPos) -> FlowColor? {
        if case .endpoint(let color) = cell(at: pos) { return color }
        return nil
    }
    
    private func setCell(_ pos: GridPos, to cell: FlowCell) {
        guard inBounds(pos) else { return }
        grid[pos.row][pos.col] = cell
    }
    
    // MARK: - Drawing
    
    private var dragDidChange = false
    
    func beginDrag(at pos: GridPos) {
        dragDidChange = false
        guard inBounds(pos) else {
            activeColor = nil
            return
        }
        
        switch cell(at: pos) {
        case .endpoint(let color):
            activeColor = color
            paths[color] = [pos]
            dragDidChange = true
            rebuildGrid()
        case .pipe(let color):
            activeColor = color
            if let path = paths[color], let index = path.firstIndex(of: pos) {
                paths[color] = Array(path.prefix(index + 1))
                dragDidChange = true
                rebuildGrid()
            }
        case .empty:
            activeColor = nil
        }
    }
    
    func continueDrag(at pos: GridPos) {
        guard let color = activeColor,
              let path = paths[color],
              let last = path.last else { return }
        guard inBounds(pos), pos != last else { return }
        
        var current = last
        var guardSteps = size * size
        while current != pos, guardSteps > 0 {
            guardSteps -= 1
            let next: GridPos
            if current.row != pos.row {
                next = GridPos(row: current.row + (pos.row > current.row ? 1 : -1), col: current.col)
            } else {
                next = GridPos(row: current.row, col: current.col + (pos.col > current.col ? 1 : -1))
            }
            guard tryStep(to: next) else { return }
            current = paths[color]?.last ?? current
        }
    }
    
    func endDrag() {
        if dragDidChange {
            moves += 1
        }
        activeColor = nil
        dragDidChange = false
        rebuildGrid()
    }
    
    private func tryStep(to pos: GridPos) -> Bool {
        guard let color = activeColor,
              var path = paths[color],
              let last = path.last else { return false }
        guard inBounds(pos), pos.isAdjacent(to: last) else { return false }
        
        if let existing = path.firstIndex(of: pos) {
            path = Array(path.prefix(existing + 1))
            paths[color] = path
            dragDidChange = true
            rebuildGrid()
            return true
        }
        
        switch cell(at: pos) {
        case .endpoint(let other) where other != color:
            return false
        case .pipe(let other) where other != color:
            clearPath(other)
        case .endpoint(let same) where same == color:
            path.append(pos)
            paths[color] = path
            dragDidChange = true
            rebuildGrid()
            return false
        default:
            break
        }
        
        path.append(pos)
        paths[color] = path
        dragDidChange = true
        rebuildGrid()
        return true
    }
    
    private func clearPath(_ color: FlowColor) {
        paths[color] = nil
    }
    
    private func rebuildGrid() {
        grid = Array(
            repeating: Array(repeating: FlowCell.empty, count: size),
            count: size
        )
        for pair in level.pairs {
            setCell(pair.start, to: .endpoint(pair.color))
            setCell(pair.end, to: .endpoint(pair.color))
        }
        for (color, path) in paths {
            for pos in path {
                if case .endpoint = cell(at: pos) { continue }
                setCell(pos, to: .pipe(color))
            }
        }
        refreshCompleteness()
    }
    
    func isPairConnected(_ pair: FlowPair) -> Bool {
        let path = paths[pair.color] ?? []
        return path.contains(pair.start) && path.contains(pair.end) && path.count >= 2
    }
    
    var isBoardFilled: Bool {
        grid.allSatisfy { row in
            row.allSatisfy { $0 != .empty }
        }
    }
    
    private func refreshCompleteness() {
        isComplete = level.pairs.allSatisfy { isPairConnected($0) } && isBoardFilled
    }
}
