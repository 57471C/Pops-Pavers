import SwiftUI

struct TitleView: View {
    let onPlay: () -> Void
    
    @State private var titleOffset: CGFloat = -450
    @State private var titleScale: CGFloat = 0.85
    @State private var popOffset: CGFloat = -600
    @State private var buttonOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // Background
            Image("title-background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            VStack {
                Spacer().frame(height: 80)
                
                // Title
                Image("title-text")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 480)
                    .offset(y: titleOffset)
                    .scaleEffect(titleScale)
                
                Spacer()
                
                // PLAY button (higher)
                Button(action: onPlay) {
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
                .padding(.bottom, 60)
            }
            
            // Pop character – slides in from left, stays in foreground
            VStack {
                Spacer()
                HStack {
                    Image("pop")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 280)
                        .offset(x: popOffset)
                        .padding(.leading, 10)
                    Spacer()
                }
                .padding(.bottom, 160)
            }
        }
        .onAppear {
            // Title drop + bounce
            withAnimation(.spring(response: 0.75, dampingFraction: 0.55)) {
                titleOffset = -20          // slightly higher than centre
                titleScale = 1.0
            }
            
            // Pop slides in from left
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) {
                    popOffset = 0
                }
            }
            
            // Button fades in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                withAnimation(.easeOut(duration: 0.5)) {
                    buttonOpacity = 1.0
                }
            }
            
            // Occasional gentle bounce on title
            Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.4)) {
                    titleScale = 1.05
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) {
                        titleScale = 1.0
                    }
                }
            }
        }
    }
}
