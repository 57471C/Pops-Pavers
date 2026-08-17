import Foundation

enum TileType: String, CaseIterable, Identifiable {
    case apple, orange, lemon, peach, melon, watermelon
    
    var id: String { rawValue }
    
    var symbol: String {
        switch self {
        case .apple: return "🍎"
        case .orange: return "🍊"
        case .lemon: return "🍋"
        case .peach: return "🍑"
        case .melon: return "🍈"
        case .watermelon: return "🍉"
        }
    }
}

struct BoardTile: Identifiable, Equatable {
    let id = UUID()
    let type: TileType
    let row: Int          // top-left cell of the 2x2 paver
    let col: Int
    let layer: Int
    var isFree: Bool = true
    
    // Every paver is 2x2
    let size = 2
}
