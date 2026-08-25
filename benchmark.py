import time
import random

class BoardTile:
    def __init__(self, id, row, col, layer):
        self.id = id
        self.row = row
        self.col = col
        self.layer = layer
        self.isFree = True

class GameState:
    def __init__(self):
        self.board = []

    def updateFreeTilesOriginal(self):
        for i in range(len(self.board)):
            tile = self.board[i]
            isCovered = False
            for other in self.board:
                if other.id != tile.id and other.layer > tile.layer:
                    rowDiff = abs(other.row - tile.row)
                    colDiff = abs(other.col - tile.col)
                    if rowDiff <= 1 and colDiff <= 1:
                        isCovered = True
                        break
            self.board[i].isFree = not isCovered

    def updateFreeTilesOptimized(self):
        maxLayerAt = {}
        for tile in self.board:
            pos = (tile.row, tile.col)
            if pos in maxLayerAt:
                if tile.layer > maxLayerAt[pos]:
                    maxLayerAt[pos] = tile.layer
            else:
                maxLayerAt[pos] = tile.layer

        for i in range(len(self.board)):
            tile = self.board[i]
            isCovered = False
            for dr in [-1, 0, 1]:
                for dc in [-1, 0, 1]:
                    pos = (tile.row + dr, tile.col + dc)
                    if pos in maxLayerAt and maxLayerAt[pos] > tile.layer:
                        isCovered = True
                        break
                if isCovered:
                    break
            self.board[i].isFree = not isCovered

gs = GameState()
id_counter = 0
for layer in range(5):
    for row in range(10):
        for col in range(10):
            if random.random() < 0.3:
                gs.board.append(BoardTile(id_counter, row, col, layer))
                id_counter += 1

print(f"Board size: {len(gs.board)}")

# Benchmark Original
start = time.time()
for _ in range(1000):
    gs.updateFreeTilesOriginal()
durationOriginal = time.time() - start
print(f"Original duration: {durationOriginal:.4f} seconds")

gs.updateFreeTilesOriginal()
originalResult = [t.isFree for t in gs.board]

# Benchmark Optimized
start = time.time()
for _ in range(1000):
    gs.updateFreeTilesOptimized()
durationOptimized = time.time() - start
print(f"Optimized duration: {durationOptimized:.4f} seconds")

gs.updateFreeTilesOptimized()
optimizedResult = [t.isFree for t in gs.board]

print(f"Results match: {originalResult == optimizedResult}")
