import SwiftUI

struct PlumbingBonusView: View {
    var onExit: () -> Void
    
    @State private var audio = AudioManager.shared
    
    var body: some View {
        ZStack {
            Image("game-background")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            
            Color.black.opacity(0.35)
                .ignoresSafeArea()
            
            VStack(spacing: 28) {
                Image("tap")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 140)
                
                Text("Plumbing Bonus Level")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.5), radius: 3, y: 2)
                
                Text("Coming soon")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.45), radius: 2, y: 1)
                
                Button {
                    audio.playButton()
                    onExit()
                } label: {
                    Text("Back to Title")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(Color(red: 0.72, green: 0.38, blue: 0.18))
                        )
                }
                .padding(.top, 8)
            }
            .padding(24)
        }
        .onAppear {
            audio.stopMusic()
            print("Plumbing Bonus Level – coming soon")
        }
    }
}
