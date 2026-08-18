import SwiftUI

struct GameView: View {
    @State private var game = GameState()
    @State private var audio = AudioManager.shared
    
    private let tileSize: CGFloat = 74
    private let cellSpacing: CGFloat = 56
    
    var body: some View {
        ZStack {
            // Background
            Image("game-background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Status
                Text(game.statusMessage)
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.6), radius: 2, y: 1)
                    .padding(.top, 20)
                
                Spacer()
                
                // Board (centred)
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
                .frame(width: 6 * cellSpacing + tileSize, height: 5 * cellSpacing + tileSize)
                
                Spacer()
                
                // Tray
                VStack(spacing: 8) {
                    Text("Tray (\(game.tray.count)/7)")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 10) {
                        ForEach(0..<7, id: \.self) { index in
                            if index < game.tray.count {
                                TileView(tile: game.tray[index], size: 58)
                            } else {
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [6]))
                                    .frame(width: 58, height: 58)
                            }
                        }
                    }
                }
                .padding()
                .background(.ultraThinMaterial.opacity(0.7), in: RoundedRectangle(cornerRadius: 20))
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
                
                if game.isGameOver {
                    Button("Play Again") {
                        audio.playButton()
                        withAnimation {
                            game.restart()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.bottom, 20)
                }
            }
        }
    }
    
    private func selectTile(_ tile: BoardTile) {
        audio.playPaverGood()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            game.select(tile)
        }
        
        // Play match sound if a match just happened
        // (simple check - you can improve this later)
        if game.tray.count % 3 == 0 && game.tray.count > 0 {
            audio.playMatch()
        }
    }
}
