import SwiftUI

struct PlumbingBonusView: View {
    var difficulty: FlowDifficulty = .easy
    var rewards: [BonusReward] = []
    var onExit: () -> Void
    var onFinished: (() -> Void)? = nil
    
    @State private var started = false
    
    var body: some View {
        if started {
            playView
        } else {
            BonusTitleView(
                onPlay: { started = true },
                onBack: onExit
            )
        }
    }
    
    private var playView: some View {
        FlowGridView(
            level: difficulty.levels[0],
            packName: difficulty.displayName,
            levelNumber: 1,
            levelCount: 1,
            onBack: {
                started = false
            },
            onWin: {
                (onFinished ?? onExit)()
            },
            rewards: rewards
        )
        .id(difficulty.levels[0].id)
    }
}

#Preview {
    PlumbingBonusView(onExit: {})
}
