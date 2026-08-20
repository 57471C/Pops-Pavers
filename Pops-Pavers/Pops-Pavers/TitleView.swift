import SwiftUI

struct TitleView: View {
    let onPlay: () -> Void
    var onSecretCottage: () -> Void = {}
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @State private var audio = AudioManager.shared
    @State private var titleOffset: CGFloat = -450
    @State private var titleScale: CGFloat = 0.85
    @State private var popOffset: CGFloat = 450
    @State private var buttonOpacity: Double = 0
    @State private var highScore: Int = UserDefaults.standard.integer(forKey: "highScore")
    @State private var lifeBank: Int = UserDefaults.standard.integer(forKey: "lifeBank")
    @State private var bankPulse = false
    
    var body: some View {
        GeometryReader { geo in
            let layout = TitleLayout(
                size: geo.size,
                isCompact: horizontalSizeClass == .compact
                    || min(geo.size.width, geo.size.height) < 700
            )
            
            ZStack {
                Image("title-background")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                
                // Nan – bottom left / path
                Image("nan-4")
                    .resizable()
                    .scaledToFit()
                    .frame(height: layout.nanHeight)
                    .padding(.leading, layout.nanLeading)
                    .padding(.bottom, layout.nanBottom)
                    .frame(width: geo.size.width, height: geo.size.height, alignment: .bottomLeading)
                    .allowsHitTesting(false)
                
                // Lilly – secret bonus entry
                Button {
                    audio.playButton()
                    audio.stopMusic()
                    onSecretCottage()
                } label: {
                    Image("lilly-1")
                        .resizable()
                        .scaledToFit()
                        .frame(height: layout.lillyHeight)
                }
                .buttonStyle(.plain)
                .padding(.leading, layout.nanLeading + layout.lillyOffset.width)
                .padding(.bottom, max(0, layout.nanBottom - layout.lillyOffset.height))
                .frame(width: geo.size.width, height: geo.size.height, alignment: .bottomLeading)
                .zIndex(20)
                
                // Pop – slides in from the right
                Image("pop-1")
                    .resizable()
                    .scaledToFit()
                    .frame(height: layout.popHeight)
                    .offset(x: popOffset)
                    .padding(.trailing, layout.popTrailing)
                    .padding(.bottom, layout.popBottom)
                    .frame(width: geo.size.width, height: geo.size.height, alignment: .bottomTrailing)
                    .allowsHitTesting(false)
                
                // Title + High Score + PLAY
                VStack {
                    Spacer().frame(height: layout.titleTop)
                    
                    Image("title-text")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: layout.titleMaxWidth)
                        .offset(y: titleOffset)
                        .scaleEffect(titleScale)
                    
                    Spacer()
                    
                    Text("High Score: \(highScore)")
                        .font(.system(size: layout.highScoreFont, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.6), radius: 2, y: 1)
                        .opacity(buttonOpacity)
                    
                    Text("❤️  Banked Lives: \(lifeBank)")
                        .font(.system(size: layout.highScoreFont, weight: .bold, design: .rounded))
                        .foregroundColor(bankPulse
                                         ? Color(red: 1.0, green: 0.85, blue: 0.25)
                                         : .white)
                        .shadow(color: .black.opacity(0.6), radius: 2, y: 1)
                        .scaleEffect(bankPulse ? 1.12 : 1.0)
                        .opacity(buttonOpacity)
                        .padding(.bottom, 6)
                    
                    Button(action: {
                        audio.playPlayButton()
                        audio.startRunPlaylist()
                        onPlay()
                    }) {
                        Text("PLAY")
                            .font(.system(size: layout.playFont, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(width: layout.playWidth, height: layout.playHeight)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.72, green: 0.38, blue: 0.18),
                                                Color(red: 0.52, green: 0.26, blue: 0.11)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .overlay(
                                        Capsule()
                                            .stroke(Color(red: 0.38, green: 0.18, blue: 0.07), lineWidth: 3)
                                    )
                                    .shadow(color: .black.opacity(0.3), radius: 5, y: 4)
                            )
                    }
                    .opacity(buttonOpacity)
                    .padding(.bottom, layout.playBottom)
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .zIndex(10)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
        .ignoresSafeArea()
        .onAppear {
            highScore = UserDefaults.standard.integer(forKey: "highScore")
            lifeBank = UserDefaults.standard.integer(forKey: "lifeBank")
            audio.playTitleMusic()
            
            withAnimation(.spring(response: 0.75, dampingFraction: 0.55)) {
                titleOffset = -20
                titleScale = 1.0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(.spring(response: 0.75, dampingFraction: 0.68)) {
                    popOffset = 0
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeOut(duration: 0.5)) {
                    buttonOpacity = 1.0
                }
                
                let shouldHighlight = UserDefaults.standard.bool(forKey: GameState.pendingBankHighlightKey)
                if shouldHighlight {
                    UserDefaults.standard.set(false, forKey: GameState.pendingBankHighlightKey)
                    pulseBankedLives()
                }
            }
            
            Timer.scheduledTimer(withTimeInterval: 4.2, repeats: true) { _ in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                    titleScale = 1.05
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) {
                        titleScale = 1.0
                    }
                }
            }
        }
    }
    
    private func pulseBankedLives() {
        for i in 0..<3 {
            let start = 0.15 + Double(i) * 0.7
            DispatchQueue.main.asyncAfter(deadline: .now() + start) {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.45)) {
                    bankPulse = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + start + 0.35) {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.7)) {
                    bankPulse = false
                }
            }
        }
    }
}

private struct TitleLayout {
    let size: CGSize
    let isCompact: Bool
    
    var popHeight: CGFloat { isCompact ? 250 : 600 }
    var popBottom: CGFloat { isCompact ? -80 : -45 }
    var popTrailing: CGFloat { isCompact ? 0 : 5 }
    
    var nanHeight: CGFloat { isCompact ? 210 : 310 }
    var lillyHeight: CGFloat { isCompact ? 120 : 155 }
    var nanLeading: CGFloat { isCompact ? 6 : 320 }
    var nanBottom: CGFloat { isCompact ? 10 : 430 }
    var lillyOffset: CGSize {
        isCompact ? CGSize(width: 40, height: 10) : CGSize(width: 60, height: 15)
    }
    
    var titleMaxWidth: CGFloat { isCompact ? min(340, size.width * 0.88) : 480 }
    var titleTop: CGFloat { isCompact ? 28 : 50 }
    var highScoreFont: CGFloat { isCompact ? 26 : 28 }
    var playFont: CGFloat { isCompact ? 30 : 34 }
    var playWidth: CGFloat { isCompact ? 220 : 260 }
    var playHeight: CGFloat { isCompact ? 64 : 74 }
    /// Lift PLAY above the iPhone character row so it stays clear and tappable.
    var playBottom: CGFloat { isCompact ? 200 : 40 }
}
