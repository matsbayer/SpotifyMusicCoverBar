import SwiftUI

@main
struct SpotifyMusicCoverBarApp: App {
    @StateObject private var spotify = SpotifyManager()
    
    var body: some Scene {
        MenuBarExtra {
            MenuView(spotify: spotify)
        } label: {
            if let icon = spotify.menuBarIcon {
                Image(nsImage: icon)
            } else {
                Image(systemName: "music.note")
            }
        }
        .menuBarExtraStyle(.window)
    }
}
