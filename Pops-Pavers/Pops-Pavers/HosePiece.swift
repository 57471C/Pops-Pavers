import SwiftUI

typealias Direction = FlowDir

struct HosePiece: Equatable, Hashable {
    var asset: String
    var rotation: Double
    var mirrored: Bool
    
    var imageName: String { asset }
}

/// Lighting: highlight on top for horizontals, left for verticals.
/// Corner rotations/mirrors match the yellow set that was already working.
func hoseStyle(
    color: FlowColor,
    entry: Direction,
    exit: Direction
) -> (asset: String, rotation: Double, mirrored: Bool) {
    switch (entry, exit) {
    case (.left, .right), (.right, .left):
        return (color.hoseStraightAsset, 0, false)
    case (.up, .down):
        return (color.hoseStraightAsset, 270, true)
    case (.down, .up):
        return (color.hoseStraightAsset, 270, false)
        
    case (.left, .up), (.up, .left):
        return (color.hoseInsideAsset, 0, false)
    case (.right, .up), (.up, .right):
        return (color.hoseInsideAsset, 0, true)
    case (.right, .down), (.down, .right):
        return (color.hoseOutsideAsset, 0, false)
    case (.left, .down), (.down, .left):
        return (color.hoseOutsideAsset, 0, true)
        
    default:
        return (color.hoseStraightAsset, 0, false)
    }
}

func hoseLayout(color: FlowColor, enter: FlowDir?, leave: FlowDir?) -> HosePiece? {
    switch (enter, leave) {
    case (nil, nil):
        return nil
    case (let entry?, let exit?):
        let style = hoseStyle(color: color, entry: entry, exit: exit)
        return HosePiece(asset: style.asset, rotation: style.rotation, mirrored: style.mirrored)
    case (let entry?, nil):
        let style = hoseStyle(color: color, entry: entry, exit: entry.opposite)
        return HosePiece(asset: style.asset, rotation: style.rotation, mirrored: style.mirrored)
    case (nil, let exit?):
        let style = hoseStyle(color: color, entry: exit.opposite, exit: exit)
        return HosePiece(asset: style.asset, rotation: style.rotation, mirrored: style.mirrored)
    }
}

func pathPorts(at pos: GridPos, in path: [GridPos]) -> (enter: FlowDir?, leave: FlowDir?) {
    guard let index = path.firstIndex(of: pos) else { return (nil, nil) }
    let enter = index > 0 ? pos.opening(toward: path[index - 1]) : nil
    let leave = index + 1 < path.count ? pos.opening(toward: path[index + 1]) : nil
    return (enter, leave)
}

private extension FlowDir {
    var opposite: FlowDir {
        switch self {
        case .left: return .right
        case .right: return .left
        case .up: return .down
        case .down: return .up
        }
    }
}

struct HoseTile: View {
    var color: FlowColor
    var enter: FlowDir?
    var leave: FlowDir?
    var side: CGFloat
    var stub: Bool = false
    
    var body: some View {
        Group {
            if let piece = hoseLayout(color: color, enter: enter, leave: leave) {
                Image(piece.imageName)
                    .resizable()
                    .frame(width: side, height: side)
                    .rotationEffect(.degrees(piece.rotation), anchor: .center)
                    .scaleEffect(x: piece.mirrored ? -1 : 1, y: 1, anchor: .center)
                    .mask(stubMask)
            }
        }
        .frame(width: side, height: side)
        .clipped()
    }
    
    @ViewBuilder
    private var stubMask: some View {
        if stub, let facing = enter ?? leave {
            stubHalf(facing)
        } else {
            Rectangle()
        }
    }
    
    private func stubHalf(_ facing: FlowDir) -> some View {
        let isHorizontal = facing == .left || facing == .right
        return Rectangle()
            .frame(
                width: isHorizontal ? side / 2 : side,
                height: isHorizontal ? side : side / 2
            )
            .frame(width: side, height: side, alignment: stubAlignment(facing))
    }
    
    private func stubAlignment(_ facing: FlowDir) -> Alignment {
        switch facing {
        case .left: return .leading
        case .right: return .trailing
        case .up: return .top
        case .down: return .bottom
        }
    }
}

struct TapTile: View {
    var color: FlowColor
    var side: CGFloat
    
    var body: some View {
        Image(color.tapAsset)
            .resizable()
            .scaledToFit()
            .frame(width: side * 0.78, height: side * 0.78)
    }
}
