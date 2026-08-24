import time
from collections import defaultdict
import uuid

class BoardTile:
    def __init__(self, icon_name, id=None):
        self.iconName = icon_name
        self.id = id or uuid.uuid4()

def test_baseline(tray, overflow_tray):
    all_tray_tiles = tray + overflow_tray
    counts = defaultdict(list)
    for tile in all_tray_tiles:
        counts[tile.iconName].append(tile)

    for icon_name, group in counts.items():
        if len(group) >= 3:
            ids = set(t.id for t in group[:3])
            tray[:] = [t for t in tray if t.id not in ids]
            overflow_tray[:] = [t for t in overflow_tray if t.id not in ids]
            return

def test_optimized(tray, overflow_tray):
    all_tiles = tray + overflow_tray
    matched_icon = None

    for i in range(len(all_tiles)):
        icon_name = all_tiles[i].iconName
        count = 1
        for j in range(i + 1, len(all_tiles)):
            if all_tiles[j].iconName == icon_name:
                count += 1
                if count == 3:
                    matched_icon = icon_name
                    break
        if matched_icon:
            break

    if matched_icon:
        removed_count = 0
        new_tray = []
        for t in tray:
            if removed_count < 3 and t.iconName == matched_icon:
                removed_count += 1
            else:
                new_tray.append(t)
        tray[:] = new_tray

        new_overflow = []
        for t in overflow_tray:
            if removed_count < 3 and t.iconName == matched_icon:
                removed_count += 1
            else:
                new_overflow.append(t)
        overflow_tray[:] = new_overflow

# Setup data once to avoid overhead in the loop
tiles = [
    BoardTile("icon-1", 1), BoardTile("icon-2", 2), BoardTile("icon-3", 3),
    BoardTile("icon-1", 4), BoardTile("icon-4", 5), BoardTile("icon-2", 6),
    BoardTile("icon-1", 7)
]

def run_benchmark(name, test_func):
    iterations = 500000

    start = time.time()
    for _ in range(iterations):
        tray = list(tiles)
        overflow_tray = []
        test_func(tray, overflow_tray)

    print(f"{name}: {time.time() - start:.4f} seconds")

run_benchmark("Baseline", test_baseline)
run_benchmark("Optimized", test_optimized)
