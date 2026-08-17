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
    let row: Int
    let col: Int
    let layer: Int          // higher number = more on top
    var isFree: Bool = true
}
