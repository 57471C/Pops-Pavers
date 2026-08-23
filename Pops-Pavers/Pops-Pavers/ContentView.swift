import SwiftUI

struct ContentView: View {
    @State private var showGame = false
    @State private var startingLevel = 1
    
    var body: some View {
        if showGame {
            GameView(startingLevel: startingLevel) {
                withAnimation {
                    showGame = false
                }
            }
        } else {
            TitleView(
                onPlay: {
                    startingLevel = 1
                    withAnimation {
                        showGame = true
                    }
                },
                onWarpToLevel21: {
                    startingLevel = 21
                    withAnimation {
                        showGame = true
                    }
                }
            )
        }
    }
}
#Preview {
    ContentView()
}
