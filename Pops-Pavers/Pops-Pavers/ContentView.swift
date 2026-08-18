import SwiftUI

struct ContentView: View {
    @State private var showGame = false
    
    var body: some View {
        if showGame {
            GameView {
                withAnimation {
                    showGame = false
                }
            }
        } else {
            TitleView {
                withAnimation {
                    showGame = true
                }
            }
        }
    }
}
#Preview {
    ContentView()
}
