import AVFoundation
import SwiftUI

@Observable
class AudioManager {
    static let shared = AudioManager()
    
    private var musicPlayer: AVAudioPlayer?
    private var sfxPlayers: [AVAudioPlayer] = []
    
    private let gameplayTracks = [
        "game-background-1",
        "game-background-2",
        "game-background-3",
        "game-background-4"
    ]
    private var runPlaylist: [String] = []
    private var currentGameplayTrack: String?
    
    var isMusicMuted = false {
        didSet {
            musicPlayer?.volume = isMusicMuted ? 0 : 0.6
        }
    }
    
    private init() {
        // Allow music to play even in silent mode
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }
    
    // MARK: - Music
    
    func playTitleMusic() {
        playMusic(named: "title-background", loop: true)
    }
    
    func startRunPlaylist() {
        runPlaylist = gameplayTracks.shuffled()
        currentGameplayTrack = nil
        playPlaylistTrack(forLevel: 1)
    }
    
    func playPlaylistTrack(forLevel level: Int) {
        if runPlaylist.isEmpty {
            runPlaylist = gameplayTracks.shuffled()
        }
        let index = (max(1, level) - 1) / 10
        let track = runPlaylist[index % runPlaylist.count]
        guard track != currentGameplayTrack else { return }
        currentGameplayTrack = track
        playMusic(named: track, loop: true)
    }
    
    func playGameplayMusic() {
        startRunPlaylist()
    }
    
    func stopMusic() {
        musicPlayer?.stop()
        musicPlayer = nil
        currentGameplayTrack = nil
    }
    
    private func playMusic(named name: String, loop: Bool) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else {
            print("Could not find music: \(name)")
            return
        }
        
        do {
            musicPlayer?.stop()
            musicPlayer = try AVAudioPlayer(contentsOf: url)
            musicPlayer?.numberOfLoops = loop ? -1 : 0
            musicPlayer?.volume = isMusicMuted ? 0 : 0.6
            musicPlayer?.play()
        } catch {
            print("Error playing music: \(error)")
        }
    }
    
    // MARK: - SFX
    
    func playSFX(_ name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: nil) ??
                        Bundle.main.url(forResource: name, withExtension: "wav") ??
                        Bundle.main.url(forResource: name, withExtension: "mp3") else {
            print("Could not find SFX: \(name)")
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = 0.9
            player.play()
            sfxPlayers.append(player)
            
            // Clean up finished players
            sfxPlayers.removeAll { !$0.isPlaying }
        } catch {
            print("Error playing SFX: \(error)")
        }
    }
    
    // Convenience methods
    func playButton()      { playSFX("button") }
    func playPlayButton()  { playSFX("play-button") }
    func playPaverGood()   { playSFX("paver-good") }
    func playPaverBad()    { playSFX("paver-bad") }
    func playMatch()       { playSFX("paver-match") }
    func playLevelWin()    { playSFX("level-win") }
    func playLevelLose()   { playSFX("level-lose") }
    func playApplause()    { playSFX("win-applause") }
    func playGameOver() {
        stopMusic()
        playSFX("game-over")
    }
}
