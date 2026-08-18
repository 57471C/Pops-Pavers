import SwiftUI

struct GameView: View {
    var onExitToTitle: () -> Void = {}
    
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
            BoardLayer(
                game: game,
                tileSize: tileSize,
                cellSpacing: cellSpacing,
                onTap: { tile in
                    selectTile(tile)
                },
                onBlockedTap: { _ in
                    audio.playPaverBad()
                }
            )
            
            
            // Tray + Lives + Shuffle
            VStack {
                Spacer()
                
                // Lives
                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { index in
                        Text(index < game.lives ? "❤️" : "🖤")
                            .font(.title2)
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 4)
                
                HStack(alignment: .center, spacing: 12) {
                    // Shuffle button
                    Button {
                        guard game.shufflesRemaining > 0 else { return }
                        audio.playButton()
                        withAnimation {
                            game.shuffleTray()
                        }
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: "arrow.2.squarepath")
                                .font(.title2.bold())
                            Text("\(game.shufflesRemaining)")
                                .font(.caption.bold())
                        }
                        .foregroundColor(.white)
                        .frame(width: 52, height: 52)
                        .background(
                            Circle()
                                .fill(game.shufflesRemaining > 0 ? Color.black.opacity(0.45) : Color.gray.opacity(0.4))
                        )
                    }
                    .disabled(game.shufflesRemaining == 0)
                    
                    // Tray
                    ZStack {
                        Image("tray")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 140)
                        
                        HStack(spacing: 9) {
                            ForEach(0..<7, id: \.self) { index in
                                if index < game.tray.count {
                                    TileView(tile: game.tray[index], size: 66)
                                } else {
                                    Color.clear.frame(width: 66, height: 66)
                                }
                            }
                        }
                        .offset(y: -6)
                    }
                }
                .padding(.bottom, 72)
            }
            
            // Win / Lose Overlay
            if game.isGameOver {
                ZStack {
                    Color.black.opacity(0.55)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 28) {
                        Image(overlayImageName)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 420)
                        
                        if game.isNewHighScore && (game.didWin || game.lives <= 0) {
                            Text("New High Score!")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.25))
                                .shadow(color: .black.opacity(0.5), radius: 3, y: 2)
                        }
                        
                        Button {
                            handleOverlayButton()
                        } label: {
                            Text(overlayButtonTitle)
                                .font(.title2.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 44)
                                .padding(.vertical, 14)
                                .background(
                                    Capsule()
                                        .fill(Color(red: 0.72, green: 0.38, blue: 0.18))
                                )
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(alignment: .bottom) {
                    HStack(alignment: .bottom) {
                        Image(overlayNanName)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 440)
                            .padding(.leading, -8)
                        
                        Spacer()
                        
                        Image(overlayPopName)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 440)
                            .padding(.trailing, -8)
                    }
                    .padding(.bottom, 88)
                    .allowsHitTesting(false)
                }
                .zIndex(200)
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .overlay(alignment: .top) {
            VStack(spacing: 6) {
                ZStack {
                    HStack {
                        Text("LEVEL \(game.level)")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                        
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
                    
                    Text("\(game.score)")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .monospacedDigit()
                }
                
                Text(game.statusMessage.isEmpty ? "Match 3 tiles!" : game.statusMessage)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, 10)
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.35))
            .padding(.top, 70)
        }
        .onChange(of: game.lives) { _, lives in
            if lives <= 0 && game.isGameOver && !game.didWin {
                audio.playGameOver()
            }
        }
    }
    
    private var overlayImageName: String {
        if game.didWin { return "level-complete" }
        if game.lives <= 0 { return "game-over" }
        return "level-failed"
    }
    
    private var overlayPopName: String {
        if game.didWin { return "pop-4" }
        if game.lives <= 0 { return "pop-5" }
        return "pop-2"
    }
    
    private var overlayNanName: String {
        if game.didWin { return "nan-1" }
        if game.lives <= 0 { return "nan-3" }
        return "nan-2"
    }
    
    private var overlayButtonTitle: String {
        if game.didWin { return "Next Level" }
        if game.lives <= 0 { return "Back to Title" }
        return "Try Again"
    }
    
    private func handleOverlayButton() {
        if game.didWin {
            audio.playButton()
            withAnimation {
                game.advanceToNextLevel()
            }
        } else if game.lives <= 0 {
            game.fullReset()
            withAnimation {
                onExitToTitle()
            }
        } else {
            audio.playButton()
            withAnimation {
                game.loseLifeAndRestart()
            }
        }
    }
    
    private func selectTile(_ tile: BoardTile) {
        audio.playPaverGood()
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            game.select(tile)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if game.justMatched {
                audio.playMatch()
                game.justMatched = false
            }
            
            if game.isGameOver {
                if game.didWin {
                    audio.playLevelWin()
                    audio.playApplause()
                } else if game.lives > 0 {
                    audio.playLevelLose()
                }
            }
        }
    }
}

// MARK: - Board
struct BoardLayer: View {
    let game: GameState
    let tileSize: CGFloat
    let cellSpacing: CGFloat
    let onTap: (BoardTile) -> Void
    let onBlockedTap: (BoardTile) -> Void
    
    var body: some View {
        ZStack {
            ForEach(game.board.sorted(by: { $0.layer < $1.layer })) { tile in
                TileCell(
                    tile: tile,
                    size: tileSize,
                    cellSpacing: cellSpacing,
                    onTap: onTap,
                    onBlockedTap: onBlockedTap
                )
            }
        }
        .frame(width: 5 * cellSpacing + tileSize, height: 4 * cellSpacing + tileSize)
    }
}

struct TileCell: View {
    let tile: BoardTile
    let size: CGFloat
    let cellSpacing: CGFloat
    let onTap: (BoardTile) -> Void
    let onBlockedTap: (BoardTile) -> Void
    
    @State private var shake: CGFloat = 0
    
    var body: some View {
        let x = CGFloat(tile.col - 2) * cellSpacing + CGFloat(tile.layer) * 5
        let y = CGFloat(tile.row - 1) * cellSpacing - CGFloat(tile.layer) * 7
        
        TileView(tile: tile, size: size)
            .offset(x: x + shake, y: y)
            .zIndex(Double(tile.layer))
            .onTapGesture {
                if tile.isFree {
                    onTap(tile)
                } else {
                    // Quiver animation
                    withAnimation(.default) {
                        shake = 10
                    }
                    withAnimation(.default.delay(0.08)) {
                        shake = -8
                    }
                    withAnimation(.default.delay(0.16)) {
                        shake = 5
                    }
                    withAnimation(.default.delay(0.24)) {
                        shake = 0
                    }
                    
                    onBlockedTap(tile)
                }
            }
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
