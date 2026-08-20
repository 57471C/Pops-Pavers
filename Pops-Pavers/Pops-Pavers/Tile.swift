import Foundation

struct BoardTile: Identifiable, Equatable {
    let id = UUID()
    let iconName: String      // "icon-1" ... "icon-20"
    let paverName: String     // "paver-1" ... "paver-6"
    var row: Int
    var col: Int
    var layer: Int
    var isFree: Bool = true
}
