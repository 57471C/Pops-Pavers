import SwiftUI

struct GameView: View {
    @State private var game = GameState()
    
    private let tileSize: CGFloat = 74
    private let cellSpacing: CGFloat = 56     // ~75% of tile size → nice partial overlap
    
    private func selectTile(_ tile: BoardTile) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            game.select(tile)
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text(game.statusMessage)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            ZStack {
                ForEach(game.board.sorted(by: { $0.layer < $1.layer })) { tile in
                    let xOffset = CGFloat(tile.col) * cellSpacing + CGFloat(tile.layer) * 6
                    let yOffset = CGFloat(tile.row) * cellSpacing - CGFloat(tile.layer) * 8
                    
                    TileView(tile: tile, size: tileSize)
                        .offset(x: xOffset, y: yOffset)
                        .zIndex(Double(tile.layer))
                        .onTapGesture {
                            guard tile.isFree else { return }
                            selectTile(tile)
                        }
                }
            }
            .frame(width: 8 * cellSpacing + 40, height: 7 * cellSpacing + 40)
            
            Spacer()
            
            // Tray
            VStack(spacing: 8) {
                Text("Tray (\(game.tray.count)/7)")
                    .font(.headline)
                
                HStack(spacing: 10) {
                    ForEach(0..<7, id: \.self) { index in
                        if index < game.tray.count {
                            TileView(tile: game.tray[index], size: 60)
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.secondary.opacity(0.4), style: StrokeStyle(lineWidth: 2, dash: [6]))
                                .frame(width: 60, height: 60)
                        }
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal)
            
            if game.isGameOver {
                Button("Play Again") {
                    withAnimation { game.restart() }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            
            Spacer().frame(height: 16)
        }
        .padding(.top)
    }
}

struct TileView: View {
    let tile: BoardTile
    let size: CGFloat          // we'll treat this as the short side
    
    // Make pavers more rectangular (wider than tall)
    private var width: CGFloat { size * 1.35 }
    private var height: CGFloat { size }
    private var corner: CGFloat { 10 }
    
    var body: some View {
        ZStack {
            // Bottom / side thickness (the dark edge in your sketch)
            RoundedRectangle(cornerRadius: corner)
                .fill(Color(white: 0.25))
                .frame(width: width, height: height)
                .offset(x: 3, y: 4)
            
            // Main face
            RoundedRectangle(cornerRadius: corner)
                .fill(
                    tile.isFree
                    ? Color(red: 0.92, green: 0.90, blue: 0.86)   // warm light stone
                    : Color(white: 0.62)                          // darker when covered
                )
                .frame(width: width, height: height)
                .overlay(
                    RoundedRectangle(cornerRadius: corner)
                        .stroke(Color(white: 0.15), lineWidth: 2.2)
                )
            
            // Emoji
            Text(tile.type.symbol)
                .font(.system(size: size * 0.48))
                .opacity(tile.isFree ? 1.0 : 0.5)
        }
        .frame(width: width, height: height)
    }
}
