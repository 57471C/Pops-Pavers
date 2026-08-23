import SwiftUI

struct PlumbingBonusView: View {
    var difficulty: FlowDifficulty = .easy
    var rewards: [BonusReward] = []
    var onExit: () -> Void
    var onFinished: (() -> Void)? = nil
    
    @State private var started = false
    @State private var pickedLevel: FlowLevel?
    
    var body: some View {
        if started, let level = pickedLevel {
            playView(level)
        } else {
            BonusTitleView(
                onPlay: {
                    if pickedLevel == nil {
                        pickedLevel = difficulty.pickRandomLevel()
                    }
                    started = true
                },
                onBack: onExit
            )
        }
    }
    
    private func playView(_ level: FlowLevel) -> some View {
        let pack = difficulty.levels
        let number = (pack.firstIndex(where: { $0.id == level.id }) ?? 0) + 1
        return FlowGridView(
            level: level,
            packName: difficulty.displayName,
            levelNumber: number,
            levelCount: pack.count,
            onBack: {
                started = false
            },
            onWin: {
                (onFinished ?? onExit)()
            },
            rewards: rewards
        )
        .id(level.id)
    }
}

#Preview {
    PlumbingBonusView(onExit: {})
}
