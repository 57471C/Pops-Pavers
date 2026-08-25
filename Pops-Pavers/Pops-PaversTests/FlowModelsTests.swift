import XCTest
@testable import Pops_Pavers

final class FlowModelsTests: XCTestCase {

    func testGridPosIsAdjacent() {
        let pos = GridPos(row: 2, col: 2)

        // Adjacent positions
        XCTAssertTrue(pos.isAdjacent(to: GridPos(row: 1, col: 2))) // Up
        XCTAssertTrue(pos.isAdjacent(to: GridPos(row: 3, col: 2))) // Down
        XCTAssertTrue(pos.isAdjacent(to: GridPos(row: 2, col: 1))) // Left
        XCTAssertTrue(pos.isAdjacent(to: GridPos(row: 2, col: 3))) // Right

        // Non-adjacent positions
        XCTAssertFalse(pos.isAdjacent(to: GridPos(row: 2, col: 2))) // Self
        XCTAssertFalse(pos.isAdjacent(to: GridPos(row: 1, col: 1))) // Diagonal
        XCTAssertFalse(pos.isAdjacent(to: GridPos(row: 4, col: 2))) // Two away
        XCTAssertFalse(pos.isAdjacent(to: GridPos(row: -1, col: 2))) // Negative
    }

    func testGridPosNeighbors() {
        let pos = GridPos(row: 2, col: 2)
        let neighbors = pos.neighbors

        XCTAssertEqual(neighbors.count, 4)
        XCTAssertTrue(neighbors.contains(GridPos(row: 1, col: 2)))
        XCTAssertTrue(neighbors.contains(GridPos(row: 3, col: 2)))
        XCTAssertTrue(neighbors.contains(GridPos(row: 2, col: 1)))
        XCTAssertTrue(neighbors.contains(GridPos(row: 2, col: 3)))
    }

    func testGridPosOpeningToward() {
        let pos = GridPos(row: 2, col: 2)

        XCTAssertEqual(pos.opening(toward: GridPos(row: 2, col: 1)), .left)
        XCTAssertEqual(pos.opening(toward: GridPos(row: 2, col: 3)), .right)
        XCTAssertEqual(pos.opening(toward: GridPos(row: 1, col: 2)), .up)
        XCTAssertEqual(pos.opening(toward: GridPos(row: 3, col: 2)), .down)

        // Non-adjacent should return nil
        XCTAssertNil(pos.opening(toward: GridPos(row: 2, col: 2)))
        XCTAssertNil(pos.opening(toward: GridPos(row: 1, col: 1)))
    }

    func testFlowGameStateInBounds() {
        let level = FlowLevel(id: 1, size: 5, pairs: [])
        let gameState = FlowGameState(level: level)

        // In bounds
        XCTAssertTrue(gameState.inBounds(GridPos(row: 0, col: 0)))
        XCTAssertTrue(gameState.inBounds(GridPos(row: 4, col: 4)))
        XCTAssertTrue(gameState.inBounds(GridPos(row: 2, col: 2)))

        // Out of bounds
        XCTAssertFalse(gameState.inBounds(GridPos(row: -1, col: 0)))
        XCTAssertFalse(gameState.inBounds(GridPos(row: 0, col: -1)))
        XCTAssertFalse(gameState.inBounds(GridPos(row: 5, col: 0)))
        XCTAssertFalse(gameState.inBounds(GridPos(row: 0, col: 5)))
        XCTAssertFalse(gameState.inBounds(GridPos(row: 5, col: 5)))
    }
}
