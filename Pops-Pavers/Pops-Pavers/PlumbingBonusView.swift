import SwiftUI

struct PlumbingBonusView: View {
    var difficulty: FlowDifficulty = .easy
    var rewards: [BonusReward] = []
    var onExit: () -> Void
    var onFinished: (() -> Void)? = nil
    var onScored: (Int) -> Void = { _ in }
    
    @State private var started = false
    @State private var pickedLevel: FlowLevel?
    
    var body: some View {
        Group {
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
        .onAppear {
            if pickedLevel == nil {
                pickedLevel = difficulty.pickRandomLevel()
            }
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
            onScored: onScored,
            rewards: rewards
        )
        .id(level.id)
    }
}

#Preview {
    PlumbingBonusView(onExit: {})
}
