import SwiftUI

struct BonusTitleView: View {
    var onPlay: () -> Void
    var onBack: () -> Void
    
    @State private var audio = AudioManager.shared
    
    var body: some View {
        GeometryReader { geo in
            let isCompact = geo.size.width < 700
                || min(geo.size.width, geo.size.height) < 700
            let topInset = max(geo.safeAreaInsets.top, 12)
            let sideInset: CGFloat = isCompact ? 28 : 48
            
            ZStack {
                Image("game-background")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                
                Color.black.opacity(0.32)
                    .frame(width: geo.size.width, height: geo.size.height)
                
                Image("lilly-3")
                    .resizable()
                    .scaledToFit()
                    .frame(height: isCompact ? 230 : 440)
                    .frame(
                        width: geo.size.width,
                        height: geo.size.height,
                        alignment: .bottomTrailing
                    )
                    .padding(.trailing, isCompact ? -16 : 8)
                    .padding(.bottom, isCompact ? 4 : 12)
                    .allowsHitTesting(false)
                
                VStack(spacing: 0) {
                    HStack {
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
                        Spacer()
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
                    .padding(.top, topInset)
                    .padding(.horizontal, sideInset)
                    
                    Spacer()
                    
                    Image("title-bonus")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: isCompact ? min(340, geo.size.width * 0.88) : 520)
                    
                    Image("title-3stars")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: isCompact ? 200 : 300)
                        .padding(.top, 10)
                    
                    Button {
                        audio.playPlayButton()
                        onPlay()
                    } label: {
                        Text("PLAY")
                            .font(.system(size: isCompact ? 30 : 34, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(width: isCompact ? 220 : 260, height: isCompact ? 64 : 74)
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
                    .padding(.top, isCompact ? 22 : 28)
                    
                    Spacer()
                    Spacer()
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .zIndex(10)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
        .ignoresSafeArea()
        .onAppear {
            audio.stopMusic()
            audio.playBonusStart()
        }
    }
}

#Preview {
    BonusTitleView(onPlay: {}, onBack: {})
}
