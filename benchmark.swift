import Foundation

struct BoardTile: Identifiable, Equatable {
    let id = UUID()
    let iconName: String
}

func generateTiles() -> [BoardTile] {
    return [
        BoardTile(iconName: "icon-1"),
        BoardTile(iconName: "icon-2"),
        BoardTile(iconName: "icon-3"),
        BoardTile(iconName: "icon-1"),
        BoardTile(iconName: "icon-4"),
        BoardTile(iconName: "icon-2"),
        BoardTile(iconName: "icon-1") // The 3rd one
    ]
}

func testBaseline(tray: inout [BoardTile], overflowTray: inout [BoardTile]) {
    let allTrayTiles = tray + overflowTray
    let counts = Dictionary(grouping: allTrayTiles, by: { $0.iconName })

    for (iconName, group) in counts {
        if group.count >= 3 {
            let ids = Set(group.prefix(3).map(\.id))
            tray.removeAll { ids.contains($0.id) }
            overflowTray.removeAll { ids.contains($0.id) }
            return
        }
    }
}

func testOptimized(tray: inout [BoardTile], overflowTray: inout [BoardTile]) {
    let allTiles = tray + overflowTray
    var matchedIcon: String?

    for i in 0..<allTiles.count {
        let iconName = allTiles[i].iconName
        var count = 1
        for j in (i + 1)..<allTiles.count {
            if allTiles[j].iconName == iconName {
                count += 1
                if count == 3 {
                    matchedIcon = iconName
                    break
                }
            }
        }
        if matchedIcon != nil { break }
    }

    if let icon = matchedIcon {
        var removedCount = 0
        tray.removeAll {
            guard removedCount < 3, $0.iconName == icon else { return false }
            removedCount += 1
            return true
        }
        overflowTray.removeAll {
            guard removedCount < 3, $0.iconName == icon else { return false }
            removedCount += 1
            return true
        }
    }
}

func runBenchmark(name: String, test: (inout [BoardTile], inout [BoardTile]) -> Void) {
    let iterations = 100_000
    var totalTime = 0.0

    for _ in 0..<10 {
        var trayTiles = [
            BoardTile(iconName: "icon-1"),
            BoardTile(iconName: "icon-2"),
            BoardTile(iconName: "icon-3"),
            BoardTile(iconName: "icon-1"),
            BoardTile(iconName: "icon-4"),
            BoardTile(iconName: "icon-2"),
            BoardTile(iconName: "icon-1")
        ]
        var overflowTiles = [BoardTile]()

        let start = CFAbsoluteTimeGetCurrent()
        for _ in 0..<iterations {
            var t = trayTiles
            var o = overflowTiles
            test(&t, &o)
        }
        totalTime += (CFAbsoluteTimeGetCurrent() - start)
    }

    print("\(name): \(totalTime / 10) seconds per 100,000 iterations")
}

runBenchmark(name: "Baseline", test: testBaseline)
runBenchmark(name: "Optimized", test: testOptimized)
