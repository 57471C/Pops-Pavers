import SwiftUI

struct FlowGridView: View {
    var level: FlowLevel
    var packName: String = ""
    var levelNumber: Int = 1
    var levelCount: Int = 1
    var onBack: () -> Void = {}
    var onWin: () -> Void = {}
    var rewards: [BonusReward] = []
    
    @State private var game: FlowGameState
    @State private var audio = AudioManager.shared
    @State private var isDragging = false
    @State private var didHandleWin = false
    
    init(
        level: FlowLevel,
        packName: String = "",
        levelNumber: Int = 1,
        levelCount: Int = 1,
        onBack: @escaping () -> Void = {},
        onWin: @escaping () -> Void = {},
        rewards: [BonusReward] = []
    ) {
        self.level = level
        self.packName = packName
        self.levelNumber = levelNumber
        self.levelCount = levelCount
        self.onBack = onBack
        self.onWin = onWin
        self.rewards = rewards
        _game = State(initialValue: FlowGameState(level: level))
    }
    
    var body: some View {
        GeometryReader { geo in
            let isCompact = geo.size.width < 700
            let topInset = max(geo.safeAreaInsets.top, 12)
            let bottomInset = max(geo.safeAreaInsets.bottom, 12)
            let sideInset: CGFloat = isCompact ? 28 : 48
            
            ZStack {
                Image("game-background")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                
                Color.black.opacity(0.40)
                    .frame(width: geo.size.width, height: geo.size.height)
                
                VStack(spacing: 0) {
                    topBar(isCompact: isCompact)
                        .padding(.top, topInset)
                        .padding(.horizontal, sideInset)
                    
                    board(isCompact: isCompact, bottomInset: bottomInset)
                }
                .frame(width: geo.size.width, height: geo.size.height)
                
                if game.isComplete {
                    successOverlay(isCompact: isCompact)
                        .onAppear {
                            handleWinIfNeeded(true)
                        }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
        .ignoresSafeArea()
        .onAppear {
            audio.playBonusBackground()
        }
        .onChange(of: game.connectedFlowCount) { oldCount, newCount in
            if newCount > oldCount, !game.isComplete {
                audio.playFlowConnect()
            }
            handleWinIfNeeded(game.isComplete)
        }
    }
    
    private func successOverlay(isCompact: Bool) -> some View {
        BonusChestRevealView(
            isCompact: isCompact,
            rewards: rewards.isEmpty
                ? BonusReward.rewards(afterCompletingMainLevel: 5)
                : rewards,
            onContinue: onWin
        )
        .transition(.opacity)
        .zIndex(50)
    }
    
    private func board(isCompact: Bool, bottomInset: CGFloat) -> some View {
        GeometryReader { geo in
            let gridSize = game.size
            let hPad: CGFloat = isCompact ? 36 : 64
            let availableWidth = max(120, geo.size.width - hPad * 2)
            let availableHeight = max(120, geo.size.height - bottomInset - 16)
            let boardSide = min(availableWidth, availableHeight, isCompact ? 320 : 560)
            let innerSide = boardSide - 16
            let cellSide = innerSide / CGFloat(gridSize)
            
            VStack(spacing: 0) {
                ForEach(0..<gridSize, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<gridSize, id: \.self) { col in
                            flowCell(
                                at: GridPos(row: row, col: col),
                                side: cellSide
                            )
                        }
                    }
                }
            }
            .coordinateSpace(name: "flowGrid")
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .named("flowGrid"))
                    .onChanged { value in
                        guard !game.isComplete else { return }
                        guard let pos = gridPos(
                            at: value.location,
                            cellSide: cellSide
                        ) else { return }
                        if !isDragging {
                            isDragging = true
                            game.beginDrag(at: pos)
                        } else {
                            let before = activePathLength
                            game.continueDrag(at: pos)
                            if activePathLength > before {
                                audio.playHose()
                            }
                        }
                    }
                    .onEnded { _ in
                        game.endDrag()
                        isDragging = false
                    }
            )
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.black.opacity(0.35))
            )
            .frame(width: boardSide, height: boardSide)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
    
    private func gridPos(at point: CGPoint, cellSide: CGFloat) -> GridPos? {
        guard cellSide > 0 else { return nil }
        let col = Int(floor(point.x / cellSide))
        let row = Int(floor(point.y / cellSide))
        let pos = GridPos(row: row, col: col)
        return game.inBounds(pos) ? pos : nil
    }
    
    private func topBar(isCompact: Bool) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                backButton
                Spacer()
                if !isCompact {
                    statusPills
                }
                muteButton
            }
            
            if isCompact {
                statusPills
            }
        }
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity)
    }
    
    private var backButton: some View {
        Button {
            audio.playButton()
            onBack()
        } label: {
            Text("Back")
                .font(.headline.bold())
                .foregroundColor(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color(red: 0.72, green: 0.38, blue: 0.18))
                )
        }
    }
    
    private var muteButton: some View {
        Button {
            audio.isMusicMuted.toggle()
            audio.playButton()
        } label: {
            Image(audio.isMusicMuted ? "unmute" : "mute")
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
                .padding(4)
                .background(
                    Circle()
                        .fill(Color.black.opacity(0.4))
                )
        }
    }
    
    private var statusPills: some View {
        HStack(spacing: 10) {
            Text(progressLabel)
                .font(.headline.bold())
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.40))
                )
            
            Text("Flows: \(game.connectedFlowCount)/\(game.level.pairs.count)")
                .font(.headline.bold())
                .foregroundColor(.white)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.40))
                )
        }
    }
    
    private func hoseAt(_ pos: GridPos, color: FlowColor, side: CGFloat, stub: Bool = false) -> HoseTile {
        let ports = pathPorts(at: pos, in: game.paths[color] ?? [])
        return HoseTile(
            color: color,
            enter: ports.enter,
            leave: ports.leave,
            side: side,
            stub: stub
        )
    }
    
    @ViewBuilder
    private func flowCell(at pos: GridPos, side: CGFloat) -> some View {
        let cell = game.cell(at: pos)
        let tileInset = max(2, side * 0.05)
        ZStack {
            RoundedRectangle(cornerRadius: max(8, side * 0.16), style: .continuous)
                .fill(Color.white.opacity(0.14))
                .overlay(
                    RoundedRectangle(cornerRadius: max(8, side * 0.16), style: .continuous)
                        .stroke(Color.white.opacity(0.28), lineWidth: 1)
                )
                .padding(tileInset)
            
            switch cell {
            case .endpoint(let color):
                hoseAt(pos, color: color, side: side, stub: true)
                TapTile(color: color, side: side)
            case .pipe(let color):
                hoseAt(pos, color: color, side: side)
            case .empty:
                EmptyView()
            }
        }
        .frame(width: side, height: side)
        .clipped()
        .contentShape(Rectangle())
    }
    
    private func handleWinIfNeeded(_ complete: Bool) {
        guard complete, !didHandleWin else { return }
        didHandleWin = true
        audio.stopMusic()
        audio.playBonusSuccess()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            audio.playApplause()
        }
    }
    
    private var activePathLength: Int {
        guard let color = game.activeColor else { return 0 }
        return game.paths[color]?.count ?? 0
    }
    
    private var progressLabel: String {
        if packName.isEmpty {
            return "Level \(levelNumber)"
        }
        return "\(packName) \(levelNumber)/\(levelCount)"
    }
}

#Preview {
    FlowGridView(level: FlowLevel.easy[0], packName: "Easy", levelNumber: 1, levelCount: 3)
}
