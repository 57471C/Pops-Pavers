import XCTest
import AVFoundation
@testable import Pops_Pavers

final class AudioManagerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        AudioManager.shared.resetForTesting()
    }

    override func tearDown() {
        AudioManager.shared.resetForTesting()
        super.tearDown()
    }

    func testStartRunPlaylist() {
        let manager = AudioManager.shared
        XCTAssertTrue(manager.runPlaylist.isEmpty, "Playlist should be empty initially")
        XCTAssertNil(manager.currentGameplayTrack, "Current track should be nil initially")

        manager.startRunPlaylist()

        XCTAssertFalse(manager.runPlaylist.isEmpty, "Playlist should be populated")
        XCTAssertEqual(manager.runPlaylist.count, manager.gameplayTracks.count, "Playlist should contain all tracks")
        // Check if tracks are in the playlist, order should be shuffled
        for track in manager.gameplayTracks {
            XCTAssertTrue(manager.runPlaylist.contains(track), "Playlist should contain track: \(track)")
        }
        XCTAssertNotNil(manager.currentGameplayTrack, "Current track should be set")
    }

    func testPlayPlaylistTrackLevelProgression() {
        let manager = AudioManager.shared
        manager.startRunPlaylist()

        let initialTrack = manager.currentGameplayTrack

        // Playing track for levels 1-10 should not change the track unless called specifically,
        // but since playPlaylistTrack only switches when index changes (every 10 levels)

        manager.playPlaylistTrack(forLevel: 5)
        XCTAssertEqual(manager.currentGameplayTrack, manager.runPlaylist[0], "Track should remain the first track for level 5")

        manager.playPlaylistTrack(forLevel: 10)
        XCTAssertEqual(manager.currentGameplayTrack, manager.runPlaylist[0], "Track should remain the first track for level 10")

        manager.playPlaylistTrack(forLevel: 11)
        XCTAssertEqual(manager.currentGameplayTrack, manager.runPlaylist[1], "Track should switch to the second track for level 11")

        manager.playPlaylistTrack(forLevel: 21)
        XCTAssertEqual(manager.currentGameplayTrack, manager.runPlaylist[2], "Track should switch to the third track for level 21")

        manager.playPlaylistTrack(forLevel: 100)
        let expectedIndex = (100 - 1) / 10 % manager.runPlaylist.count
        XCTAssertEqual(manager.currentGameplayTrack, manager.runPlaylist[expectedIndex], "Track should wrap around correctly")
    }

    func testIsMusicMuted() {
        let manager = AudioManager.shared

        // Default state
        XCTAssertFalse(manager.isMusicMuted)

        // Start playing music
        manager.playTitleMusic()

        // AVPlayer might be nil if the file isn't found in tests, but we can test the state
        manager.isMusicMuted = true
        XCTAssertTrue(manager.isMusicMuted)
        if let player = manager.musicPlayer {
            XCTAssertEqual(player.volume, 0, "Volume should be 0 when muted")
        }

        manager.isMusicMuted = false
        XCTAssertFalse(manager.isMusicMuted)
        if let player = manager.musicPlayer {
            XCTAssertEqual(player.volume, 0.6, "Volume should be 0.6 when unmuted")
        }
    }

    func testStopMusic() {
        let manager = AudioManager.shared
        manager.startRunPlaylist()
        XCTAssertNotNil(manager.currentGameplayTrack)

        manager.stopMusic()
        XCTAssertNil(manager.musicPlayer)
        XCTAssertNil(manager.currentGameplayTrack)
    }

    func testStopAll() {
        let manager = AudioManager.shared
        manager.startRunPlaylist()
        // Simulate playing an SFX (which adds to sfxPlayers if successful)
        manager.playButton()

        manager.stopAll()

        XCTAssertNil(manager.musicPlayer)
        XCTAssertNil(manager.currentGameplayTrack)
        // Since playButton might fail to find the file in the test bundle and not add an AVAudioPlayer,
        // we mainly check that the sfxPlayers array is empty after calling stopAll.
        XCTAssertTrue(manager.sfxPlayers.isEmpty)
    }
}
