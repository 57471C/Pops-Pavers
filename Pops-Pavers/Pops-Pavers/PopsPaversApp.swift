import SwiftUI
import UIKit

@main
struct PopsPaversApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                    AudioManager.shared.stopAll()
                }
        }
    }
}
