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
            PlumbingBonusView {
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
                    withAnimation {
                        showPlumbing = true
                    }
                }
            )
        }
    }
}
#Preview {
    ContentView()
}
