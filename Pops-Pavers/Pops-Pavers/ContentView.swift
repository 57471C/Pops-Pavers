import SwiftUI

struct ContentView: View {
    @State private var showGame = false
    
    var body: some View {
        if showGame {
            GameView()
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
