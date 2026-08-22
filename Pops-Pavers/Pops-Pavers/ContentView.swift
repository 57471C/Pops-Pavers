import SwiftUI

struct ContentView: View {
    @State private var showGame = false
    @State private var showPlumbing = false
    
    var body: some View {
        if showGame {
            GameView {
                withAnimation {
                    showGame = false
                }
            }
        } else if showPlumbing {
            PlumbingBonusView(difficulty: .easy) {
                withAnimation {
                    showPlumbing = false
                }
            }
        } else {
            TitleView(
                onPlay: {
                    withAnimation {
                        showGame = true
                    }
                },
                onSecretCottage: {
                    showPlumbing = true
                }
            )
        }
    }
}
#Preview {
    ContentView()
}
