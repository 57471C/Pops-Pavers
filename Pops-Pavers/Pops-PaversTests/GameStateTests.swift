import XCTest
@testable import Pops_Pavers

final class GameStateTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Clear UserDefaults for isolation
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
    }

    override func tearDown() {
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
        super.tearDown()
    }

    func testInitialization() {
        let gameState = GameState()

        XCTAssertEqual(gameState.lives, 3, "New game should start with 3 lives")
        XCTAssertEqual(gameState.level, 1, "New game should start at level 1")
        XCTAssertEqual(gameState.score, 0, "New game should start with 0 score")
        XCTAssertFalse(gameState.isGameOver, "Game should not be over initially")
        XCTAssertFalse(gameState.board.isEmpty, "Board should be generated and not empty")
        XCTAssertTrue(gameState.tray.isEmpty, "Tray should start empty")
        XCTAssertTrue(gameState.overflowTray.isEmpty, "Overflow tray should start empty")
    }

    func testSelectTile() {
        let gameState = GameState()

        // Find a free tile to select
        guard let freeTile = gameState.board.first(where: { $0.isFree }) else {
            XCTFail("Could not find a free tile on the generated board")
            return
        }

        let initialBoardCount = gameState.board.count

        gameState.select(freeTile)

        XCTAssertEqual(gameState.board.count, initialBoardCount - 1, "Board should have 1 less tile after selection")
        XCTAssertEqual(gameState.tray.count, 1, "Tray should have 1 tile after selection")
        XCTAssertEqual(gameState.tray.first?.id, freeTile.id, "The selected tile should be in the tray")
        XCTAssertEqual(gameState.lastUndoableTileID, freeTile.id, "lastUndoableTileID should be updated to the selected tile")
    }

    func testUndoLastMove() {
        let gameState = GameState()

        guard let freeTile = gameState.board.first(where: { $0.isFree }) else {
            XCTFail("Could not find a free tile on the generated board")
            return
        }

        let initialBoardCount = gameState.board.count
        let initialUndos = gameState.undosRemaining

        gameState.select(freeTile)
        gameState.undoLastMove()

        XCTAssertEqual(gameState.board.count, initialBoardCount, "Board count should be restored after undo")
        XCTAssertTrue(gameState.tray.isEmpty, "Tray should be empty after undo")
        XCTAssertEqual(gameState.undosRemaining, initialUndos - 1, "Undos remaining should decrease by 1")
        XCTAssertNil(gameState.lastUndoableTileID, "lastUndoableTileID should be cleared after undo")
        XCTAssertTrue(gameState.board.contains(where: { $0.id == freeTile.id }), "The undone tile should be back on the board")
    }

    func testSelectTile_whenNotFree_doesNothing() {
        let gameState = GameState()

        // Find a covered (not free) tile
        guard let coveredTile = gameState.board.first(where: { !$0.isFree }) else {
            // If random generation didn't produce a covered tile, we skip the test or fail it
            return
        }

        let initialBoardCount = gameState.board.count

        gameState.select(coveredTile)

        XCTAssertEqual(gameState.board.count, initialBoardCount, "Board count should not change when selecting a covered tile")
        XCTAssertTrue(gameState.tray.isEmpty, "Tray should remain empty")
    }

    func testSelectTile_whenGameOver_doesNothing() {
        let gameState = GameState()
        gameState.isGameOver = true

        guard let freeTile = gameState.board.first(where: { $0.isFree }) else { return }

        let initialBoardCount = gameState.board.count
        gameState.select(freeTile)

        XCTAssertEqual(gameState.board.count, initialBoardCount, "Board count should not change when game is over")
        XCTAssertTrue(gameState.tray.isEmpty, "Tray should remain empty")
    }

    func testStartNewLevel() {
        let gameState = GameState()

        // Mutate some properties to simulate gameplay
        gameState.isGameOver = true
        gameState.didWin = true
        gameState.justMatched = true
        gameState.justClearedTray = true
        gameState.lastUndoableTileID = UUID()
        gameState.tray = [BoardTile(iconName: "icon-1", paverName: "paver-1", row: 0, col: 0, layer: 0)]
        gameState.overflowTray = [BoardTile(iconName: "icon-2", paverName: "paver-2", row: 0, col: 0, layer: 0)]

        // Ensure starting level resets properties appropriately
        gameState.startNewLevel()

        XCTAssertFalse(gameState.isGameOver, "isGameOver should be false after starting a new level")
        XCTAssertFalse(gameState.didWin, "didWin should be false after starting a new level")
        XCTAssertFalse(gameState.justMatched, "justMatched should be false after starting a new level")
        XCTAssertFalse(gameState.justClearedTray, "justClearedTray should be false after starting a new level")
        XCTAssertNil(gameState.lastUndoableTileID, "lastUndoableTileID should be nil after starting a new level")
        XCTAssertTrue(gameState.tray.isEmpty, "tray should be empty after starting a new level")
        XCTAssertTrue(gameState.overflowTray.isEmpty, "overflowTray should be empty after starting a new level")
        XCTAssertFalse(gameState.board.isEmpty, "board should be populated after starting a new level")
    }

    func testUndoLastMove_whenNoUndosRemaining_doesNothing() {
        let gameState = GameState()
        gameState.undosRemaining = 0
        let testTile = BoardTile(iconName: "icon-1", paverName: "paver-1", row: 0, col: 0, layer: 0)
        gameState.tray = [testTile]
        gameState.lastUndoableTileID = testTile.id

        let initialBoardCount = gameState.board.count
        gameState.undoLastMove()

        XCTAssertEqual(gameState.board.count, initialBoardCount, "Board should not change when out of undos")
        XCTAssertEqual(gameState.tray.count, 1, "Tile should remain in tray")
        XCTAssertEqual(gameState.undosRemaining, 0, "Undos should remain 0")
    }

    func testUndoLastMove_whenGameOver_doesNothing() {
        let gameState = GameState()
        gameState.isGameOver = true
        let testTile = BoardTile(iconName: "icon-1", paverName: "paver-1", row: 0, col: 0, layer: 0)
        gameState.tray = [testTile]
        gameState.lastUndoableTileID = testTile.id

        let initialBoardCount = gameState.board.count
        gameState.undoLastMove()

        XCTAssertEqual(gameState.board.count, initialBoardCount, "Board should not change when game is over")
        XCTAssertEqual(gameState.tray.count, 1, "Tile should remain in tray")
    }

    func testUndoLastMove_whenLastUndoableTileIDNil_doesNothing() {
        let gameState = GameState()
        let testTile = BoardTile(iconName: "icon-1", paverName: "paver-1", row: 0, col: 0, layer: 0)
        gameState.tray = [testTile]
        gameState.lastUndoableTileID = nil

        let initialBoardCount = gameState.board.count
        gameState.undoLastMove()

        XCTAssertEqual(gameState.board.count, initialBoardCount, "Board should not change when lastUndoableTileID is nil")
        XCTAssertEqual(gameState.tray.count, 1, "Tile should remain in tray")
    }

    func testUndoLastMove_fromTray() {
        let gameState = GameState()
        let testTile = BoardTile(iconName: "icon-1", paverName: "paver-1", row: 0, col: 0, layer: 0)
        gameState.tray = [testTile]
        gameState.lastUndoableTileID = testTile.id
        gameState.undosRemaining = 1

        let initialBoardCount = gameState.board.count
        gameState.undoLastMove()

        XCTAssertEqual(gameState.board.count, initialBoardCount + 1, "Board should have 1 more tile after undo from tray")
        XCTAssertTrue(gameState.tray.isEmpty, "Tray should be empty after undo")
        XCTAssertTrue(gameState.board.contains(where: { $0.id == testTile.id }), "The undone tile should be on the board")
        XCTAssertNil(gameState.lastUndoableTileID, "lastUndoableTileID should be cleared")
    }

    func testUndoLastMove_fromOverflowTray() {
        let gameState = GameState()
        let testTile = BoardTile(iconName: "icon-1", paverName: "paver-1", row: 0, col: 0, layer: 0)
        gameState.overflowTray = [testTile]
        gameState.lastUndoableTileID = testTile.id
        gameState.undosRemaining = 1

        let initialBoardCount = gameState.board.count
        gameState.undoLastMove()

        XCTAssertEqual(gameState.board.count, initialBoardCount + 1, "Board should have 1 more tile after undo from overflow tray")
        XCTAssertTrue(gameState.overflowTray.isEmpty, "Overflow tray should be empty after undo")
        XCTAssertTrue(gameState.board.contains(where: { $0.id == testTile.id }), "The undone tile should be on the board")
        XCTAssertNil(gameState.lastUndoableTileID, "lastUndoableTileID should be cleared")
    }

    func testUndoLastMove_tileNotInTrays_doesNothing() {
        let gameState = GameState()
        let testTile = BoardTile(iconName: "icon-1", paverName: "paver-1", row: 0, col: 0, layer: 0)
        gameState.lastUndoableTileID = testTile.id
        gameState.undosRemaining = 1
        // Do NOT add to tray or overflowTray

        let initialBoardCount = gameState.board.count
        gameState.undoLastMove()

        XCTAssertEqual(gameState.board.count, initialBoardCount, "Board should not change if tile is not in trays")
        XCTAssertEqual(gameState.lastUndoableTileID, testTile.id, "lastUndoableTileID should remain unchanged if undo fails")

    func testUseBankedLife_Success() {
        UserDefaults.standard.removeObject(forKey: "lifeBank")

        let gameState = GameState()
        gameState.addToLifeBank(1)
        gameState.lives = 0
        gameState.isGameOver = true
        gameState.didWin = false

        let result = gameState.useBankedLife()

        XCTAssertTrue(result, "useBankedLife should return true when successful")
        XCTAssertEqual(gameState.lives, 1, "Lives should be restored to 1")
        XCTAssertEqual(gameState.lifeBank, 0, "Life bank should be decremented")
        XCTAssertFalse(gameState.isGameOver, "Game should restart (isGameOver = false)")

        let savedLifeBank = UserDefaults.standard.integer(forKey: "lifeBank")
        XCTAssertEqual(savedLifeBank, 0, "UserDefaults should be updated with new lifeBank value")
    }

    func testUseBankedLife_NoBankedLives_ReturnsFalse() {
        UserDefaults.standard.removeObject(forKey: "lifeBank")

        let gameState = GameState()
        gameState.lifeBank = 0
        gameState.lives = 0
        gameState.isGameOver = true
        gameState.didWin = false

        let result = gameState.useBankedLife()

        XCTAssertFalse(result, "useBankedLife should return false when lifeBank is 0")
        XCTAssertEqual(gameState.lives, 0, "Lives should not change")
    }

    func testUseBankedLife_HasLives_ReturnsFalse() {
        UserDefaults.standard.removeObject(forKey: "lifeBank")

        let gameState = GameState()
        gameState.addToLifeBank(1)
        gameState.lives = 1
        gameState.isGameOver = true
        gameState.didWin = false

        let result = gameState.useBankedLife()

        XCTAssertFalse(result, "useBankedLife should return false when lives > 0")
        XCTAssertEqual(gameState.lifeBank, 1, "Life bank should not change")
    }

    func testUseBankedLife_NotGameOver_ReturnsFalse() {
        UserDefaults.standard.removeObject(forKey: "lifeBank")

        let gameState = GameState()
        gameState.addToLifeBank(1)
        gameState.lives = 0
        gameState.isGameOver = false
        gameState.didWin = false

        let result = gameState.useBankedLife()

        XCTAssertFalse(result, "useBankedLife should return false when game is not over")
        XCTAssertEqual(gameState.lifeBank, 1, "Life bank should not change")
    }

    func testUseBankedLife_DidWin_ReturnsFalse() {
        UserDefaults.standard.removeObject(forKey: "lifeBank")

        let gameState = GameState()
        gameState.addToLifeBank(1)
        gameState.lives = 0
        gameState.isGameOver = true
        gameState.didWin = true

        let result = gameState.useBankedLife()

        XCTAssertFalse(result, "useBankedLife should return false when game was won")
        XCTAssertEqual(gameState.lifeBank, 1, "Life bank should not change")
    }
}
