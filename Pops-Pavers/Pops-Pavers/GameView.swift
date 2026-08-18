import SwiftUI

struct GameView: View {
    @State private var game = GameState()
    @State private var audio = AudioManager.shared
    
    private let tileSize: CGFloat = 108
    private let cellSpacing: CGFloat = 78
    
    var body: some View {
        ZStack {
            // Background
            Image("game-background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            // Board
            BoardLayer(game: game, tileSize: tileSize, cellSpacing: cellSpacing) { tile in
                selectTile(tile)
            }
            
            // Tray
            VStack {
                Spacer()
                
                ZStack {
                    Image("tray")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 140)
                    
                    HStack(spacing: 9) {               // slightly tighter spacing
                        ForEach(0..<7, id: \.self) { index in
                            if index < game.tray.count {
                                TileView(tile: game.tray[index], size: 66)
                            } else {
                                Color.clear
                                    .frame(width: 66, height: 66)
                            }
                        }
                    }
                    .offset(y: -6)                     // vertical alignment tweak
                }
                .padding(.bottom, 72)                  // moved up a few px from 80
            }
        }
        .overlay(alignment: .top) {
            HStack {
                Text(game.statusMessage.isEmpty ? "Match 3 tiles!" : game.statusMessage)
                    .font(.title3.bold())
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Spacer()
                
                Button {
                    audio.isMusicMuted.toggle()
                    audio.playButton()
                } label: {
                    Image(audio.isMusicMuted ? "unmute" : "mute")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 46, height: 46)
                        .padding(6)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.4))
                        )
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 10)
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.35))
            .padding(.top, 70)   // ← increased
        }
    }
    
    private func selectTile(_ tile: BoardTile) {
        audio.playPaverGood()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            game.select(tile)
        }
    }
}

// MARK: - Board
struct BoardLayer: View {
    let game: GameState
    let tileSize: CGFloat
    let cellSpacing: CGFloat
    let onTap: (BoardTile) -> Void
    
    var body: some View {
        ZStack {
            ForEach(game.board.sorted(by: { $0.layer < $1.layer })) { tile in
                let x = CGFloat(tile.col - 2) * cellSpacing + CGFloat(tile.layer) * 5
                let y = CGFloat(tile.row - 1) * cellSpacing - CGFloat(tile.layer) * 7
                
                TileView(tile: tile, size: tileSize)
                    .offset(x: x, y: y)
                    .zIndex(Double(tile.layer))
                    .onTapGesture {
                        if tile.isFree {
                            onTap(tile)
                        }
                    }
            }
        }
        .frame(width: 5 * cellSpacing + tileSize, height: 4 * cellSpacing + tileSize)
    }
}

// MARK: - Tile
struct TileView: View {
    let tile: BoardTile
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Image(tile.paverName)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
            
            Image(tile.iconName)
                .resizable()
                .scaledToFit()
                .frame(width: size * 0.58, height: size * 0.58)
                .opacity(tile.isFree ? 1.0 : 0.65)
        }
        .shadow(color: .black.opacity(tile.isFree ? 0.35 : 0.18), radius: 3, y: 2)
        .opacity(tile.isFree ? 1.0 : 0.82)
    }
}
