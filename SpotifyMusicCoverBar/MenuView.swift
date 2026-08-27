import SwiftUI

struct MenuView: View {
    @ObservedObject var spotify: SpotifyManager
    @State private var rotationDegree: Double = 0
    @State private var lastDate: Date = Date()
    @State private var isDraggingSlider: Bool = false
    @State private var sliderTempPosition: Double = 0
    
    var body: some View {
        VStack(spacing: 8) {
            
            // Vinyl like artwork cover
            Button(action: { spotify.sendCommand("playpause") }) {
                ZStack {
                    if let cover = spotify.fullArtwork {
                        TimelineView(.animation(paused: !spotify.isPlaying)) { timeline in
                            Image(nsImage: cover)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Circle()
                                        .fill(Color(NSColor.windowBackgroundColor))
                                        .frame(width: 16, height: 16)
                                )
                                .clipShape(Circle())
                                .shadow(radius: 5)
                                .rotationEffect(.degrees(rotationDegree))
                                .opacity(spotify.isPlaying ? 1.0 : 0.6)
                                .onChange(of: timeline.date) { _, newDate in
                                    if spotify.isPlaying {
                                        let delta = newDate.timeIntervalSince(lastDate)
                                        
                                        if delta < 0.1 {
                                            rotationDegree = (rotationDegree + delta * 36).truncatingRemainder(dividingBy: 360)
                                        }
                                    }
                                    lastDate = newDate
                                }
                        }
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.secondary.opacity(0.2))
                            .frame(width: 80, height: 80)
                    }
                    
                    if !spotify.isPlaying {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 26))
                            .foregroundColor(.white)
                            .shadow(radius: 4)
                    }
                }
            }
            .buttonStyle(.plain)
            
            // Title & Artist
            VStack(alignment: .center, spacing: 2) {
                Text(spotify.trackName)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                
                if !spotify.artistName.isEmpty {
                    Text(spotify.artistName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity)
            
            // Progress slider
            VStack(spacing: 2) {
                Slider(
                    value: Binding(
                        get: {
                            isDraggingSlider ? sliderTempPosition : spotify.currentPosition
                        },
                        set: { newValue in
                            sliderTempPosition = newValue
                        }
                    ),
                    in: 0...max(spotify.trackDuration, 1),
                    onEditingChanged: { editing in
                        isDraggingSlider = editing
                        if !editing {
                            spotify.seek(to: sliderTempPosition)
                        }
                    }
                )
                .controlSize(.mini)
                .tint(.white)
                
                HStack {
                    Text(formatTime(isDraggingSlider ? sliderTempPosition : spotify.currentPosition))
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(formatTime(spotify.trackDuration))
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 2)
            
            
            // Playback controls
            HStack(spacing: 8) {
                Button(action: { spotify.sendCommand("previous track") }) {
                    Image(systemName: "backward.fill")
                }
                
                Button(action: { spotify.sendCommand("playpause") }) {
                    Image(systemName: spotify.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 16))
                }
                .frame(width: 24, height: 24, alignment: .center)
                
                Button(action: { spotify.sendCommand("next track") }) {
                    Image(systemName: "forward.fill")
                }
            }.buttonStyle(.borderless)
            
        }
        .padding()
        .frame(width: 180)
        .background(.thinMaterial)
        .overlay(alignment: .topTrailing) {
            Button(action: {
                let menu = NSMenu()
                
                let quitItem = NSMenuItem(title: "Close", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
                
                menu.addItem(quitItem)
                
                if let event = NSApp.currentEvent {
                    NSMenu.popUpContextMenu(menu, with: event, for: NSApp.keyWindow?.contentView ?? NSView())
                }
            }) {
                Text("⋮")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.secondary)
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding([.top, .trailing], 10)
        }
    }
    
    private func formatTime(_ seconds: Double) -> String {
        guard !seconds.isNaN && seconds.isFinite else { return "0:00" }
        let total = Int(seconds)
        let mins = total / 60
        let secs = total % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
