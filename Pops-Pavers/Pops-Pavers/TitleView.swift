import SwiftUI

struct TitleView: View {
    let onPlay: () -> Void
    
    @State private var titleOffset: CGFloat = -450
    @State private var titleScale: CGFloat = 0.85
    @State private var lillyOffset: CGFloat = -500
    @State private var popOffset: CGFloat = 600
    @State private var buttonOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // Background
            Image("title-background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            VStack {
                Spacer().frame(height: 50)
                
                // Title
                Image("title-text")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 480)
                    .offset(y: titleOffset)
                    .scaleEffect(titleScale)
                
                Spacer()
                
                // PLAY button
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
                .padding(.bottom, 40)
            }
            
            // Lilly-1 (pink zone - bottom left)
            VStack {
                Spacer()
                HStack {
                    Image("lilly-1")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 310)
                        .offset(x: lillyOffset)
                        .padding(.leading, 10)
                    Spacer()
                }
                .padding(.bottom, 30)
            }
            
            // Pop (red zone - bottom right) - 2x larger
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image("pop-1")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 680)
                        .offset(x: popOffset + 12)      // a few px to the right
                        .padding(.trailing, 10)
                }
                .padding(.bottom, -10)                 // drop him ~10px lower
            }
        }
        .onAppear {
            // Title drop
            withAnimation(.spring(response: 0.75, dampingFraction: 0.55)) {
                titleOffset = -20
                titleScale = 1.0
            }
            
            // Lilly slides in from left
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.75, dampingFraction: 0.7)) {
                    lillyOffset = 0
                }
            }
            
            // Pop slides in from right
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(.spring(response: 0.75, dampingFraction: 0.68)) {
                    popOffset = 0
                }
            }
            
            // Button
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                withAnimation(.easeOut(duration: 0.5)) {
                    buttonOpacity = 1.0
                }
            }
            
            // Occasional title bounce
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
