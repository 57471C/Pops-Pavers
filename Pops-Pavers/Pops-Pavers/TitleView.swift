import SwiftUI

struct TitleView: View {
    let onPlay: () -> Void
    
    @State private var audio = AudioManager.shared
    @State private var titleOffset: CGFloat = -450
    @State private var titleScale: CGFloat = 0.85
    @State private var popOffset: CGFloat = 450
    @State private var buttonOpacity: Double = 0
    @State private var highScore: Int = UserDefaults.standard.integer(forKey: "highScore")
    
    var body: some View {
        ZStack {
            // Background
            Image("title-background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            // Nan + Lilly group (static, on the path)
            
            ZStack(alignment: .bottomLeading) {
                // Nan (behind)
                Image("nan-4")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 310)
                
                // Lilly (in front, slightly to the right so her tail overlaps Nan’s leg)
                Image("lilly-1")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 155)
                    .offset(x: 60, y: 15)
            }
            .padding(.leading, 320)   // ← this slides them L/R
            .padding(.bottom, 430)   // ← this lifts them up into the red circle zone
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            
            // Main content
            VStack {
                Spacer().frame(height: 50)
                
                Image("title-text")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 480)
                    .offset(y: titleOffset)
                    .scaleEffect(titleScale)
                
                Spacer()
                
                Text("High Score: \(highScore)")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.6), radius: 2, y: 1)
                    .opacity(buttonOpacity)
                
                Button(action: {
                    audio.playPlayButton()
                    audio.playGameplayMusic()
                    onPlay()
                }) {
                    Text("PLAY")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(width: 260, height: 74)
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
                .padding(.bottom, 40)
            }
            
            // Pop – slides in from right
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image("pop-1")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 600)  // 400
                        .offset(x: popOffset)
                        .padding(.trailing, 5)
                }
                .padding(.bottom, 5)
            }
        }
        .onAppear {
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
}
