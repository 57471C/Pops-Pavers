import SwiftUI

/// 6-frame sheet, each cell 333×348.
struct ChestFrameView: View {
    var frameIndex: Int
    var height: CGFloat
    
    private let frameWidth: CGFloat = 333
    private let frameHeight: CGFloat = 348
    private let frameCount = 6
    
    var body: some View {
        let scale = height / frameHeight
        let index = min(max(frameIndex, 0), frameCount - 1)
        Image("chest")
            .interpolation(.none)
            .resizable()
            .frame(
                width: frameWidth * CGFloat(frameCount),
                height: frameHeight
            )
            .offset(x: -CGFloat(index) * frameWidth)
            .frame(width: frameWidth, height: frameHeight, alignment: .leading)
            .clipped()
            .drawingGroup()
            .scaleEffect(scale)
            .frame(width: frameWidth * scale, height: frameHeight * scale)
    }
}

struct BonusChestRevealView: View {
    var isCompact: Bool
    var rewards: [BonusReward]
    var onContinue: () -> Void
    
    @State private var audio = AudioManager.shared
    @State private var lillyOffset: CGFloat = 0
    @State private var lillyOpacity: Double = 1
    @State private var chestScale: CGFloat = 0.12
    @State private var chestOpacity: Double = 0
    @State private var chestFrame = 0
    @State private var displayedReward: BonusReward?
    @State private var showCurrentReward = false
    @State private var awaitingTap = false
    @State private var showContinue = false
    @State private var tapContinuation: CheckedContinuation<Void, Never>?
    
    private var chestHeight: CGFloat { isCompact ? 320 : 460 }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.50)
                .ignoresSafeArea()
            
            VStack(spacing: isCompact ? 14 : 20) {
                Image("level-complete")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: isCompact ? 240 : 300)
                    .padding(.horizontal, 28)
                
                ZStack {
                    ChestFrameView(frameIndex: chestFrame, height: chestHeight)
                        .scaleEffect(chestScale)
                        .opacity(chestOpacity)
                    
                    if let reward = displayedReward, showCurrentReward {
                        rewardGraphic(reward)
                            .offset(y: isCompact ? -28 : -40)
                            .zIndex(2)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(height: chestHeight)
                .contentShape(Rectangle())
                .onTapGesture {
                    if awaitingTap {
                        resumeTap()
                    }
                }
                
                if let reward = displayedReward, showCurrentReward {
                    Text(reward.title)
                        .font(.system(size: isCompact ? 26 : 34, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .shadow(color: .black.opacity(0.6), radius: 3, y: 2)
                        .padding(.horizontal, 20)
                        .transition(.opacity)
                    
                    Button {
                        resumeTap()
                    } label: {
                        Text("Next")
                            .font(isCompact ? .title3.bold() : .title2.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, isCompact ? 36 : 48)
                            .padding(.vertical, isCompact ? 12 : 14)
                            .background(
                                Capsule()
                                    .fill(Color(red: 0.72, green: 0.38, blue: 0.18))
                            )
                    }
                    .padding(.top, 4)
                } else if showContinue {
                    Button {
                        audio.playButton()
                        onContinue()
                    } label: {
                        Text("Continue")
                            .font(isCompact ? .title3.bold() : .title2.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, isCompact ? 36 : 48)
                            .padding(.vertical, isCompact ? 12 : 14)
                            .background(
                                Capsule()
                                    .fill(Color(red: 0.72, green: 0.38, blue: 0.18))
                            )
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                } else {
                    Color.clear.frame(height: isCompact ? 70 : 84)
                }
            }
            
            Image("lilly-4")
                .resizable()
                .scaledToFit()
                .frame(height: isCompact ? 160 : 280)
                .offset(y: lillyOffset)
                .opacity(lillyOpacity)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, isCompact ? 8 : 24)
                .allowsHitTesting(false)
        }
        .task {
            await runSequence()
        }
    }
    
    private func rewardGraphic(_ reward: BonusReward) -> some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .shadow(color: .black.opacity(0.3), radius: 8, y: 3)
            if let name = reward.imageName {
                Image(name)
                    .resizable()
                    .scaledToFit()
                    .padding(isCompact ? 14 : 18)
            } else if let system = reward.systemImage {
                Image(systemName: system)
                    .font(.system(size: isCompact ? 40 : 52, weight: .bold))
                    .foregroundColor(Color(red: 0.72, green: 0.38, blue: 0.18))
            }
        }
        .frame(width: isCompact ? 96 : 120, height: isCompact ? 96 : 120)
    }
    
    @MainActor
    private func runSequence() async {
        defer {
            tapContinuation?.resume()
            tapContinuation = nil
        }
        try? await Task.sleep(for: .seconds(0.45))
        withAnimation(.easeIn(duration: 0.7)) {
            lillyOffset = 420
            lillyOpacity = 0
        }
        
        try? await Task.sleep(for: .seconds(2.75))
        
        withAnimation(.spring(response: 0.7, dampingFraction: 0.72)) {
            chestScale = 1
            chestOpacity = 1
        }
        try? await Task.sleep(for: .seconds(0.75))
        
        for reward in rewards {
            guard !Task.isCancelled else { return }
            await revealReward(reward)
        }
        
        withAnimation(.easeOut(duration: 0.35)) {
            showContinue = true
        }
    }
    
    @MainActor
    private func revealReward(_ reward: BonusReward) async {
        audio.playChestOpen()
        await playFrames([0, 1, 2, 3, 4, 5], frameDuration: 0.05)
        
        displayedReward = reward
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            showCurrentReward = true
        }
        audio.playRewardBling()
        
        await waitForTap()
        guard !Task.isCancelled else { return }
        
        audio.playButton()
        withAnimation(.easeOut(duration: 0.15)) {
            showCurrentReward = false
        }
        audio.playChestClose()
        await playFrames([5, 4, 3, 2, 1, 0], frameDuration: 0.07)
        displayedReward = nil
        try? await Task.sleep(for: .milliseconds(250))
    }
    
    @MainActor
    private func waitForTap() async {
        awaitingTap = true
        await withCheckedContinuation { continuation in
            tapContinuation = continuation
        }
        awaitingTap = false
    }
    
    private func resumeTap() {
        guard awaitingTap else { return }
        tapContinuation?.resume()
        tapContinuation = nil
    }
    
    @MainActor
    private func playFrames(_ frames: [Int], frameDuration: Double) async {
        for frame in frames {
            guard !Task.isCancelled else { return }
            chestFrame = frame
            try? await Task.sleep(for: .seconds(frameDuration))
        }
    }
}

#Preview {
    BonusChestRevealView(
        isCompact: true,
        rewards: BonusReward.rewards(afterCompletingMainLevel: 10),
        onContinue: {}
    )
}
