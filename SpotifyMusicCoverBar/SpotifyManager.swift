import Foundation
import AppKit

class SpotifyManager: ObservableObject {
    @Published var trackName: String = "Spotify lädt..."
    @Published var artistName: String = ""
    @Published var isPlaying: Bool = false
    @Published var fullArtwork: NSImage? = nil
    @Published var menuBarIcon: NSImage? = nil
    @Published var currentPosition: Double = 0
    @Published var trackDuration: Double = 1
    
    private var positionTimer: Timer?
    private var lastCoverUrl: String = ""
    
    init() {
        setupObserver()
        startPositionTimer()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.refresh()
        }
    }
    
    private func setupObserver() {
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handlePlaybackChange),
            name: NSNotification.Name("com.spotify.client.PlaybackStateChanged"),
            object: nil
        )
    }
    
    @objc private func handlePlaybackChange() {
        DispatchQueue.main.async {
            self.refresh()
        }
    }
    
    // Lässt den Fortschrittsbalken mitlaufen, wenn Musik spielt
    private func startPositionTimer() {
        positionTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self, self.isPlaying else { return }
            self.refreshPositionOnly()
        }
    }
    
    func refresh() {
        let script = """
        if application "Spotify" is running then
            tell application "Spotify"
                set pState to player state as string
                set trackArtist to artist of current track
                set trackName to name of current track
                set artUrl to artwork url of current track
                set pPos to player position
                set pDur to (duration of current track) / 1000
                return pState & "|||" & trackArtist & "|||" & trackName & "|||" & artUrl & "|||" & pPos & "|||" & pDur
            end tell
        else
            return "CLOSED"
        end if
        """
        
        DispatchQueue.global(qos: .userInitiated).async {
            var error: NSDictionary?
            guard let appleScript = NSAppleScript(source: script) else { return }
            let output = appleScript.executeAndReturnError(&error)
            let result = output.stringValue ?? ""
            
            DispatchQueue.main.async {
                if result.contains("|||") {
                    let parts = result.components(separatedBy: "|||")
                    if parts.count >= 6 {
                        let state = parts[0]
                        self.isPlaying = (state == "playing" || state == "kPSP")
                        self.artistName = parts[1]
                        self.trackName = parts[2]
                        
                        let coverUrl = parts[3]
                        if coverUrl != self.lastCoverUrl {
                            self.lastCoverUrl = coverUrl
                            self.loadCover(from: coverUrl)
                        }
                        
                        let posString = parts[4].replacingOccurrences(of: ",", with: ".")
                        let durString = parts[5].replacingOccurrences(of: ",", with: ".")
                        self.currentPosition = Double(posString) ?? self.currentPosition
                        self.trackDuration = max(Double(durString) ?? 1, 1)
                    }
                } else if result == "CLOSED" {
                    self.isPlaying = false
                    self.trackName = "Spotify geschlossen"
                    self.artistName = ""
                    self.fullArtwork = nil
                    self.menuBarIcon = nil
                    self.currentPosition = 0
                    self.trackDuration = 1
                    self.lastCoverUrl = ""
                }
            }
        }
    }
    
    // Schlankere Abfrage rein für den Fortschritt (schont Ressourcen)
    private func refreshPositionOnly() {
        let script = """
        if application "Spotify" is running then
            tell application "Spotify"
                return (player position as string)
            end tell
        else
            return "0"
        end if
        """
        
        DispatchQueue.global(qos: .userInitiated).async {
            var error: NSDictionary?
            guard let appleScript = NSAppleScript(source: script) else { return }
            let output = appleScript.executeAndReturnError(&error)
            if let posString = output.stringValue {
                let formatted = posString.replacingOccurrences(of: ",", with: ".")
                DispatchQueue.main.async {
                    if let pos = Double(formatted) {
                        self.currentPosition = pos
                    }
                }
            }
        }
    }
    
    private func loadCover(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data, let originalImage = NSImage(data: data) else { return }
            let tinyIcon = originalImage.resizedForMenuBar(size: 18, cornerRadius: 4)
            
            DispatchQueue.main.async {
                self?.fullArtwork = originalImage
                self?.menuBarIcon = tinyIcon
            }
        }.resume()
    }
    
    func seek(to seconds: Double) {
        self.currentPosition = seconds
        let script = "tell application \"Spotify\" to set player position to \(seconds)"
        DispatchQueue.global(qos: .userInitiated).async {
            var error: NSDictionary?
            NSAppleScript(source: script)?.executeAndReturnError(&error)
        }
    }
    
    func sendCommand(_ cmd: String) {
        if cmd == "playpause" {
            self.isPlaying.toggle()
        }
        
        let script = "tell application \"Spotify\" to \(cmd)"
        DispatchQueue.global(qos: .userInitiated).async {
            var error: NSDictionary?
            NSAppleScript(source: script)?.executeAndReturnError(&error)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.refresh()
            }
        }
    }
    
    deinit {
        positionTimer?.invalidate()
    }
}
