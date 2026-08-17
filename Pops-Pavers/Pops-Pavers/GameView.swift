import SwiftUI

struct GameView: View {
    @State private var game = GameState()
    
    private let tileSize: CGFloat = 72
    
    var body: some View {
        VStack(spacing: 20) {
            Text(game.statusMessage)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Board with layers
            ZStack {
                ForEach(game.board.sorted(by: { $0.layer < $1.layer })) { tile in
                    TileView(tile: tile, size: tileSize)
                        .opacity(tile.isFree ? 1.0 : 0.35)
                        .offset(
                            x: CGFloat(tile.col - 1) * (tileSize + 12) + CGFloat(tile.layer) * 6,
                            y: CGFloat(tile.row - 1) * (tileSize + 12) - CGFloat(tile.layer) * 8
                        )
                        .zIndex(Double(tile.layer))
                        
                        .onTapGesture {
                            guard tile.isFree else { return }
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                game.select(tile)
                            }
                        }
                }
            }
            .frame(height: 280)
            .padding(.vertical)
            
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
    let size: CGFloat
    
    var body: some View {
        Text(tile.type.symbol)
            .font(.system(size: size * 0.55))
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.18), radius: 3, y: 2)
            )
    }
}
