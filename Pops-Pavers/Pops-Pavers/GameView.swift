import SwiftUI

struct GameView: View {
    @State private var game = GameState()
    @State private var audio = AudioManager.shared
    
    private let tileSize: CGFloat = 118
    private let cellSpacing: CGFloat = 86
    
    var body: some View {
        ZStack {
            // Background
            Image("game-background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            // Top bar + Board only
            VStack {
                HStack {
                    Text(game.statusMessage)
                        .font(.title3.bold())
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.7), radius: 2, y: 1)
                    
                    Spacer()
                    
                    Button {
                        audio.isMusicMuted.toggle()
                        audio.playButton()
                    } label: {
                        Image(audio.isMusicMuted ? "unmute" : "mute")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                Spacer()
                
                BoardLayer(game: game, tileSize: 108, cellSpacing: 78) { tile in
                    selectTile(tile)
                }
                
                Spacer()
            }
            
            // ===== TRAY OVERLAY – pinned to bottom =====
            VStack {
                Spacer()
                
                ZStack {
                    Image("tray")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 135)
                    
                    HStack(spacing: 10) {
                        ForEach(0..<7, id: \.self) { index in
                            if index < game.tray.count {
                                TileView(tile: game.tray[index], size: 70)
                            } else {
                                Color.clear.frame(width: 70, height: 70)
                            }
                        }
                    }
                    .offset(y: -8)
                }
                .padding(.bottom, 25)
            }
            .ignoresSafeArea(edges: .bottom) // important
        }
    }
    
    // MARK: - Tray
    private var trayView: some View {
        VStack(spacing: 10) {
            Text("Tray  \(game.tray.count)/7")
                .font(.title2.bold())
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 1)
            
            HStack(spacing: 12) {
                ForEach(0..<7, id: \.self) { index in
                    if index < game.tray.count {
                        TileView(tile: game.tray[index], size: 82)
                    } else {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.55), style: StrokeStyle(lineWidth: 2.5, dash: [7]))
                            )
                            .frame(width: 82, height: 82)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.4), radius: 10, y: 5)
        )
        .padding(.horizontal, 14)
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
                        if tile.isFree { onTap(tile) }
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
