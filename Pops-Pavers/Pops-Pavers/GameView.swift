import SwiftUI

struct GameView: View {
    var onExitToTitle: () -> Void = {}
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @State private var game = GameState()
    @State private var audio = AudioManager.shared
    @State private var bonusDifficulty: FlowDifficulty?
    @State private var trayClearBurst = 0
    @State private var matchBurst: BoardScoreBurst?
    
    var body: some View {
        GeometryReader { geo in
            let layout = GameLayout(
                size: geo.size,
                isCompact: horizontalSizeClass == .compact
                    || min(geo.size.width, geo.size.height) < 700
            )
            
            ZStack {
                if let diff = bonusDifficulty {
                    PlumbingBonusView(
                        difficulty: diff,
                        rewards: BonusReward.rewards(
                            afterCompletingMainLevel: game.level
                        ),
                        onExit: {
                            clearScorePopups()
                            bonusDifficulty = nil
                            game.fullReset()
                            onExitToTitle()
                        },
                        onFinished: {
                            let completedLevel = game.level
                            clearScorePopups()
                            bonusDifficulty = nil
                            game.advanceToNextLevel()
                            game.applyBonusRewards(afterCompletingLevel: completedLevel)
                        }
                    )
                    .frame(width: geo.size.width, height: geo.size.height)
                } else {
                    Image(game.backgroundName)
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                        .id(game.backgroundName)
                    
                    VStack(spacing: 0) {
                        hudBar(layout: layout)
                        
                        Spacer(minLength: 8)
                        
                        BoardLayer(
                            game: game,
                            tileSize: layout.tileSize,
                            cellSpacing: layout.cellSpacing,
                            layerShift: layout.layerShift,
                            matchBurst: matchBurst,
                            matchPopupWidth: layout.trayTileSize * 2.15,
                            onTap: { tile in
                                selectTile(tile)
                            },
                            onBlockedTap: { _ in
                                audio.playPaverBad()
                            }
                        )
                        
                        Spacer(minLength: 8)
                        
                        traySection(layout: layout)
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                    
                    if game.isGameOver {
                        overlay(layout: layout)
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .onChange(of: game.lives) { _, lives in
            if lives <= 0 && game.isGameOver && !game.didWin {
                audio.playGameOver()
            }
        }
        .onChange(of: game.level) { _, level in
            audio.playPlaylistTrack(forLevel: level)
        }
    }
    
    // MARK: - HUD
    
    private func hudBar(layout: GameLayout) -> some View {
        VStack(spacing: layout.isCompact ? 4 : 6) {
            ZStack {
                HStack {
                    Text("LEVEL \(game.level)")
                        .font(layout.levelFont)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button {
                        audio.isMusicMuted.toggle()
                        audio.playButton()
                    } label: {
                        Image(audio.isMusicMuted ? "unmute" : "mute")
                            .resizable()
                            .scaledToFit()
                            .frame(width: layout.muteSize, height: layout.muteSize)
                            .padding(layout.isCompact ? 4 : 6)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.4))
                            )
                    }
                }
                
                Text("\(game.score)")
                    .font(layout.scoreFont)
                    .foregroundColor(.white)
                    .monospacedDigit()
            }
            
            Text(game.statusMessage.isEmpty ? "Match 3 tiles!" : game.statusMessage)
                .font(layout.statusFont)
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, layout.isCompact ? 14 : 18)
        .padding(.top, 10)
        .padding(.bottom, layout.isCompact ? 8 : 10)
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.35))
    }
    
    // MARK: - Tray
    
    private func traySection(layout: GameLayout) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { index in
                    Text(index < game.lives ? "❤️" : "🖤")
                        .font(layout.heartFont)
                }
                
                Spacer()
                
                Text("Bank \(game.lifeBank)")
                    .font(layout.isCompact ? .caption.bold() : .subheadline.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.black.opacity(0.4)))
            }
            .padding(.horizontal, layout.isCompact ? 16 : 24)
            .padding(.bottom, 4)
            
            HStack(alignment: .center, spacing: layout.trayButtonSpacing) {
                circleActionButton(
                    icon: "arrow.2.squarepath",
                    count: game.shufflesRemaining,
                    enabled: game.shufflesRemaining > 0 && !game.board.isEmpty,
                    size: layout.shuffleSize,
                    compact: layout.isCompact
                ) {
                    audio.playButton()
                    withAnimation {
                        game.shuffleBoard()
                    }
                }
                
                trayGraphic(layout: layout)
                    .frame(maxWidth: .infinity)
                
                circleActionButton(
                    icon: "arrow.uturn.backward",
                    count: game.undosRemaining,
                    enabled: game.canUndo,
                    size: layout.shuffleSize,
                    compact: layout.isCompact
                ) {
                    audio.playButton()
                    withAnimation {
                        game.undoLastMove()
                    }
                }
            }
            .padding(.horizontal, layout.isCompact ? 8 : 16)
            .padding(.bottom, layout.trayBottom)
        }
    }
    
    @ViewBuilder
    private func traySlot(_ index: Int, layout: GameLayout) -> some View {
        if index < game.tray.count {
            TileView(tile: game.tray[index], size: layout.trayTileSize)
        } else {
            Color.clear.frame(width: layout.trayTileSize, height: layout.trayTileSize)
        }
    }
    
    private func trayGraphic(layout: GameLayout) -> some View {
        let trayWidth = layout.trayDrawnWidth
        let trayHeight = layout.trayHeight
        return Image("tray")
            .resizable()
            .scaledToFit()
            .frame(width: trayWidth, height: trayHeight)
            .overlay {
                if layout.isCompact {
                    HStack(spacing: layout.trayTileSpacing) {
                        ForEach(0..<7, id: \.self) { index in
                            traySlot(index, layout: layout)
                        }
                    }
                    .offset(y: layout.trayTileOffsetY)
                    .overlay(alignment: .leading) {
                        if trayClearBurst > 0 {
                            ScorePopup(imageName: "score-5", width: layout.trayTileSize * 1.15)
                                .id(trayClearBurst)
                        }
                    }
                } else {
                    HStack(spacing: 0) {
                        ForEach(0..<7, id: \.self) { index in
                            ZStack {
                                traySlot(index, layout: layout)
                                if index == 0, trayClearBurst > 0 {
                                    ScorePopup(imageName: "score-5", width: layout.trayTileSize * 1.15)
                                        .id(trayClearBurst)
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                    .padding(.leading, trayWidth * layout.trayInnerLeft)
                    .padding(.trailing, trayWidth * layout.trayInnerRight)
                    .padding(.top, trayHeight * layout.trayInnerTop)
                    .padding(.bottom, trayHeight * layout.trayInnerBottom)
                }
            }
    }
    
    private func circleActionButton(
        icon: String,
        count: Int,
        enabled: Bool,
        size: CGFloat,
        compact: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(compact ? .title3.bold() : .title2.bold())
                Text("\(count)")
                    .font(.caption.bold())
            }
            .foregroundColor(.white)
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(enabled ? Color.black.opacity(0.45) : Color.gray.opacity(0.4))
            )
        }
        .disabled(!enabled)
    }
    
    // MARK: - Overlay
    
    private func overlay(layout: GameLayout) -> some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
            
            VStack(spacing: layout.isCompact ? 18 : 28) {
                Image(overlayImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: layout.overlayTitleMax)
                
                if game.isNewHighScore && (game.didWin || game.lives <= 0) {
                    Text("New High Score!")
                        .font(.system(size: layout.overlayHighScoreFont, weight: .bold, design: .rounded))
                        .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.25))
                        .shadow(color: .black.opacity(0.5), radius: 3, y: 2)
                }
                
                if game.didWin && game.justEarnedBankLife {
                    Text("Life Bank +1!")
                        .font(.system(size: layout.isCompact ? 22 : 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 3, y: 2)
                }
                
                if game.lives <= 0 && !game.didWin {
                    Text("Life Bank: \(game.lifeBank)")
                        .font(.system(size: layout.isCompact ? 20 : 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 2, y: 1)
                    
                    if game.lifeBank > 0 {
                        overlayCapsuleButton("Use Banked Life", compact: layout.isCompact) {
                            audio.playButton()
                            withAnimation {
                                _ = game.useBankedLife()
                            }
                        }
                    }
                    
                    overlayCapsuleButton("Back to Title", compact: layout.isCompact) {
                        handleOverlayButton()
                    }
                } else {
                    overlayCapsuleButton(overlayButtonTitle, compact: layout.isCompact) {
                        handleOverlayButton()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            HStack(alignment: .bottom) {
                Image(overlayNanName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: layout.overlayCharacterHeight)
                    .padding(.leading, overlayNanLeading(isCompact: layout.isCompact))
                
                Spacer()
                
                Image(overlayPopName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: layout.overlayCharacterHeight)
                    .padding(.trailing, overlayPopTrailing(isCompact: layout.isCompact))
            }
            .padding(.bottom, layout.overlayCharacterBottom)
            .allowsHitTesting(false)
        }
        .zIndex(200)
        .transition(.opacity.combined(with: .scale(scale: 0.96)))
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
    
    private func overlayNanLeading(isCompact: Bool) -> CGFloat {
        guard isCompact else { return -8 }
        if game.didWin { return 16 }
        // Fail and game-over poses sit further off the left edge.
        return 40
    }
    
    private func overlayPopTrailing(isCompact: Bool) -> CGFloat {
        guard isCompact else { return -8 }
        // Game-over pose is cropped further right than win/fail.
        if game.lives <= 0 && !game.didWin { return 24 }
        return 0
    }
    
    private func overlayCapsuleButton(_ title: String, compact: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(compact ? .headline.bold() : .title2.bold())
                .foregroundColor(.white)
                .padding(.horizontal, compact ? 32 : 44)
                .padding(.vertical, compact ? 12 : 14)
                .background(
                    Capsule()
                        .fill(Color(red: 0.72, green: 0.38, blue: 0.18))
                )
        }
    }
    
    private var overlayButtonTitle: String {
        if game.didWin {
            if FlowDifficulty.triggered(afterCompletingMainLevel: game.level) != nil {
                return "Bonus Level"
            }
            return "Next Level"
        }
        if game.lives <= 0 { return "Back to Title" }
        return "Try Again"
    }
    
    private func handleOverlayButton() {
        if game.didWin {
            audio.playButton()
            if let diff = FlowDifficulty.triggered(afterCompletingMainLevel: game.level) {
                clearScorePopups()
                bonusDifficulty = diff
            } else {
                clearScorePopups()
                withAnimation {
                    game.advanceToNextLevel()
                }
            }
        } else if game.lives <= 0 {
            clearScorePopups()
            game.fullReset()
            withAnimation {
                onExitToTitle()
            }
        } else {
            audio.playButton()
            clearScorePopups()
            withAnimation {
                game.loseLifeAndRestart()
            }
        }
    }
    
    private func clearScorePopups() {
        matchBurst = nil
        trayClearBurst = 0
    }
    
    private func selectTile(_ tile: BoardTile) {
        audio.playPaverGood()
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            game.select(tile)
        }
        
        let levelAtSelect = game.level
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            guard game.level == levelAtSelect, bonusDifficulty == nil else { return }
            if game.justMatched {
                audio.playMatch()
                matchBurst = BoardScoreBurst(
                    token: (matchBurst?.token ?? 0) + 1,
                    row: tile.row,
                    col: tile.col,
                    layer: tile.layer
                )
                game.justMatched = false
            }
            if game.justClearedTray {
                game.justClearedTray = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
                    guard game.level == levelAtSelect, bonusDifficulty == nil else { return }
                    audio.playTrayCleared()
                    trayClearBurst += 1
                }
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

struct BoardScoreBurst: Equatable {
    var token: Int
    var row: Int
    var col: Int
    var layer: Int
}

private struct ScorePopup: View {
    var imageName: String
    var width: CGFloat
    
    @State private var rise: CGFloat = 0
    @State private var opacity: Double = 0
    
    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(width: width)
            .offset(y: rise)
            .opacity(opacity)
            .allowsHitTesting(false)
            .onAppear {
                opacity = 1
                withAnimation(.easeOut(duration: 0.7).delay(0.08)) {
                    rise = -58
                    opacity = 0
                }
            }
    }
}

// MARK: - Layout

private struct GameLayout {
    let size: CGSize
    let isCompact: Bool
    
    var tileSize: CGFloat {
        if !isCompact { return 108 }
        let fromWidth = (size.width - 20) / 4.7
        let reserved: CGFloat = 250
        let fromHeight = max(52, size.height - reserved) / 4.1
        return min(76, max(56, min(fromWidth, fromHeight)))
    }
    
    var cellSpacing: CGFloat { isCompact ? tileSize * 0.72 : 78 }
    var layerShift: CGSize {
        CGSize(width: tileSize * 5 / 108, height: tileSize * 7 / 108)
    }
    
    var trayHeight: CGFloat { isCompact ? 84 : 140 }
    var trayDrawnWidth: CGFloat { trayHeight * (1334.0 / 281.0) }
    /// Pocket grid of tray.png (1334×281): 7 recesses, ~3.95% side rims.
    var trayInnerLeft: CGFloat { 0.0395 }
    var trayInnerRight: CGFloat { 0.0395 }
    var trayInnerTop: CGFloat { 0.199 }
    var trayInnerBottom: CGFloat { 0.263 }
    var trayTileSpacing: CGFloat { isCompact ? 3 : 9 }
    var trayTileOffsetY: CGFloat { isCompact ? -4 : 0 }
    var shuffleSize: CGFloat { isCompact ? 42 : 52 }
    var trayButtonSpacing: CGFloat { isCompact ? 6 : 12 }
    var trayTileSize: CGFloat {
        if !isCompact { return 66 }
        let sideButtons = shuffleSize * 2
        let gaps = trayButtonSpacing * 2 + 16
        let available = size.width - sideButtons - gaps
        return min(40, max(30, (available - trayTileSpacing * 6) / 7))
    }
    var heartFont: Font { isCompact ? .title3 : .title2 }
    var trayBottom: CGFloat { isCompact ? 10 : 40 }
    
    var levelFont: Font { isCompact ? .subheadline.bold() : .headline.bold() }
    var scoreFont: Font { isCompact ? .title3.bold() : .title2.bold() }
    var statusFont: Font { isCompact ? .caption.bold() : .subheadline.bold() }
    var muteSize: CGFloat { isCompact ? 38 : 46 }
    
    var overlayTitleMax: CGFloat { isCompact ? min(300, size.width - 36) : 420 }
    var overlayCharacterHeight: CGFloat { isCompact ? 210 : 440 }
    var overlayCharacterBottom: CGFloat { isCompact ? -44 : 88 }
    var overlayHighScoreFont: CGFloat { isCompact ? 22 : 32 }
}

// MARK: - Board

struct BoardLayer: View {
    let game: GameState
    let tileSize: CGFloat
    let cellSpacing: CGFloat
    let layerShift: CGSize
    var matchBurst: BoardScoreBurst? = nil
    var matchPopupWidth: CGFloat = 80
    let onTap: (BoardTile) -> Void
    let onBlockedTap: (BoardTile) -> Void
    
    var body: some View {
        ZStack {
            ForEach(game.board.sorted(by: { $0.layer < $1.layer })) { tile in
                TileCell(
                    tile: tile,
                    size: tileSize,
                    cellSpacing: cellSpacing,
                    layerShift: layerShift,
                    onTap: onTap,
                    onBlockedTap: onBlockedTap
                )
            }
            
            if let burst = matchBurst {
                let x = CGFloat(burst.col - 2) * cellSpacing + CGFloat(burst.layer) * layerShift.width
                let y = CGFloat(burst.row - 1) * cellSpacing - CGFloat(burst.layer) * layerShift.height
                ScorePopup(imageName: "score-10", width: matchPopupWidth)
                    .id(burst.token)
                    .offset(x: x, y: y)
                    .zIndex(1000)
            }
        }
        .frame(width: 5 * cellSpacing + tileSize, height: 4 * cellSpacing + tileSize)
        .offset(x: -tileSize)
    }
}

struct TileCell: View {
    let tile: BoardTile
    let size: CGFloat
    let cellSpacing: CGFloat
    let layerShift: CGSize
    let onTap: (BoardTile) -> Void
    let onBlockedTap: (BoardTile) -> Void
    
    @State private var shake: CGFloat = 0
    
    var body: some View {
        let x = CGFloat(tile.col - 2) * cellSpacing + CGFloat(tile.layer) * layerShift.width
        let y = CGFloat(tile.row - 1) * cellSpacing - CGFloat(tile.layer) * layerShift.height
        let shakeAmount = max(6, size * 0.09)
        
        TileView(tile: tile, size: size)
            .offset(x: x + shake, y: y)
            .zIndex(Double(tile.layer))
            .onTapGesture {
                if tile.isFree {
                    onTap(tile)
                } else {
                    withAnimation(.default) {
                        shake = shakeAmount
                    }
                    withAnimation(.default.delay(0.08)) {
                        shake = -shakeAmount * 0.8
                    }
                    withAnimation(.default.delay(0.16)) {
                        shake = shakeAmount * 0.5
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
