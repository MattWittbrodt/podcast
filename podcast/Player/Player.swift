import SwiftUI
import AVKit
import CoreData

func formatFloat(_ value: Float) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 1  // Don't force decimal places
    formatter.maximumFractionDigits = 2  // But show up to 2 if needed
    
    return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
}

struct PlayerMenu: View {
    @EnvironmentObject var playbackManager: PlaybackManager
    let rates: [Float] = [0.75,1.0,1.25,1.5,1.75,2.0]
    
    var body: some View {
        Menu {
            ForEach(rates, id: \.self) { rate in
                Button {
                    Task { playbackManager.updatePlaybackRate(rate) }
                } label: {
                    LabeledContent {
                        if rate == playbackManager.playbackRate {
                            Image(systemName: "checkmark")
                        }
                    } label: {
                        Text("\(formatFloat(rate))x")
                    }
                }
            }
        } label: {
            menuLabel
        }
    }
    
    private var menuLabel: some View {
        HStack(spacing: 4) {
            Text("\(formatFloat(playbackManager.playbackRate))x")
                .font(.system(size: 14, weight: .medium))
                .monospacedDigit() // Ensures consistent width for numbers
            
            Image(systemName: "chevron.down")
                .font(.caption2)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct PlayerControlsView: View {
    @EnvironmentObject var playbackManager: PlaybackManager
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isEditing = false
    
    var body: some View {
        VStack {
            Slider(
                value: $playbackManager.currentTime, // Binds to the current time
                in: 0...playbackManager.duration,
                onEditingChanged: { isEditing in
                    playbackManager.isSeeking = isEditing
                    if !isEditing {
                        playbackManager.seek(to: playbackManager.currentTime)
                    }
                }
            )
            .tint(themeManager.selectedTheme.primaryColor)
            .padding(.horizontal)
            HStack {
                Text("\(playbackManager.currentTimeString)")
                    .fontWeight(.semibold)
                Spacer()
                Text("- \(formattedTime(time: Double(playbackManager.duration)-playbackManager.currentTime))")
                    .fontWeight(.semibold)
            }
            .padding()
            
            HStack {
                Button(action: { playbackManager.skipBackward(seconds: 30) }) {
                    Image(systemName: "gobackward.30")
                        .resizable()
                        .frame(width: 40, height: 45 )
                }
                Spacer()
                Button(action: { playbackManager.playPause() }) {
                    Image(systemName: playbackManager.isPlaying ? "pause.fill" : "play.fill")
                        .resizable()
                        .frame(width: 35, height: 45 )
                }
                Spacer()
                Button(action: { playbackManager.skipForward(seconds: 30) }) {
                    Image(systemName: "goforward.30")
                        .resizable()
                        .frame(width: 40, height: 45 )
                }
                
            }
            .padding(.leading, 75)
            .padding(.trailing, 75)
        }
    }
}


//struct PlayerImgNotes<ViewModel: PlayerViewModelProtocol>: View {
//    @EnvironmentObject var playerManager: ViewModel
//    @EnvironmentObject var themeManager: ThemeManager
//    @State private var currentPage: Int = 0
//    
//    private let spacing: CGFloat = 7
//    private let pageIndicatorTintColor = Color.gray.opacity(0.5)
//        
//    var body: some View {
//        VStack(spacing: spacing) {
//            GeometryReader { geometry in
//                TabView(selection: $currentPage) {
//                    PlayerImageHandler<ViewModel>()
//                        .environmentObject(playerManager)
//                        .tag(0)
//                        .frame(width: geometry.size.width)
//                    
//                    PlayerEpisodeDescriptionView(html: playerManager.currentEpisode?.displayDescription ?? "",
//                                                 theme: themeManager)
//                    .tag(1)
//                    .frame(width: geometry.size.width)
//                }
//                .tabViewStyle(.page(indexDisplayMode: .never))
//                .frame(height: 300)
//                .padding(.bottom, 15)
//            }
//            
//            // Page indicators
//            HStack(spacing: spacing) {
//                ForEach(0..<2, id: \.self) { index in
//                    Circle()
//                        .fill(index == currentPage ? themeManager.selectedTheme.primaryColor.opacity(0.8) : pageIndicatorTintColor)
//                        .frame(width: 8, height: 8)
//                        .onTapGesture {
//                            withAnimation {
//                                currentPage = index
//                            }
//                        }
//                }
//            }
//        }
//    }
//}

struct EpisodeImageView: View {
    @EnvironmentObject var playbackManager: PlaybackManager
        
    var body: some View {
        if let imgData = playbackManager.currentEpisodeImageData, let uIImg = UIImage(data: imgData) {
            Image(uiImage: uIImg)
                .resizable()
                .frame(width: 300, height: 300)
                .cornerRadius(25)
        } else {
            EmptyView()
        }
    }
}

struct AirPlayButton: UIViewRepresentable {
    var activeTint: UIColor
    
    init(activeTint: UIColor = .blue) {
        self.activeTint = activeTint
    }
    
    func makeUIView(context: Context) -> UIView {
        let routePickerView = AVRoutePickerView(frame: .zero)
        routePickerView.prioritizesVideoDevices = false
        routePickerView.activeTintColor = activeTint
        
        return routePickerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update the view if needed
    }
}
    

struct Player: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var playbackManager: PlaybackManager
    
//    private var bookmarkButton: some View {
//        Button {
//            playerManager.saveBookmark()
//        } label: {
//            Image(systemName: "bookmark.square")
//                .resizable()
//                .frame(width: 30, height: 30)
//                .opacity(0.85)
//        }
//    }
    
    var body: some View {
        Color(themeManager.selectedTheme.secondoryColor)
            .ignoresSafeArea(.all)
            .overlay(
                VStack {
                    Text(playbackManager.currentEpisode?.title ?? "No episode selected").lineLimit(1)
                        .font(.title3)
                        .fontWeight(.medium)
                        .padding(.leading, 10)
                        .padding(.trailing, 10)
                        .padding(.top, 15)
                    
                    Text(playbackManager.currentEpisode?.podcast?.title ?? "Podcast")
                        .font(.callout)
                        .foregroundStyle(Color(themeManager.selectedTheme.primaryColor)).opacity(0.7)
                    

                    EpisodeImageView()
                    
                    // Chapter display and list
                    PlayerChapters()
                        .environmentObject(playbackManager)
                        .environmentObject(themeManager)
                    
                    // Player controls
                    PlayerControlsView().padding(30)
                        .foregroundStyle(Color(themeManager.selectedTheme.primaryColor))
                    
                    // Playback rate menu
                    HStack {
                        PlayerMenu()
                            .environmentObject(playbackManager)
                            .foregroundStyle(Color(themeManager.selectedTheme.primaryColor))
                        Spacer()
                        //bookmarkButton
                    }
                    .padding(.leading, 120)
                    .padding(.trailing, 120)
                                        
                    Text(playbackManager.currentAudioDeviceName ?? "")
                    AirPlayButton(activeTint: UIColor(Color(themeManager.selectedTheme.primaryColor)))
                        .frame(width: 120, height: 50)
                        .padding(.top, 30)
                        .tint(Color(themeManager.selectedTheme.primaryColor))
                    
                    
                }
                .background(Color(themeManager.selectedTheme.secondoryColor))
                .foregroundStyle(Color(themeManager.selectedTheme.primaryColor))
            )
        }
}

#Preview {
    let dataManager = DataManager.preview
    let downloadManager = DownloadManager(dataManager: dataManager)
    let pm = PlaybackManager(downloadManager: downloadManager, dataManager: dataManager)
    
    // Create sample in the same context that PlaybackManager uses
    let episode = Episode.sample(in: dataManager.persistence.viewContext)
    pm.currentEpisode = episode
    
    guard let uiImage = UIImage(systemName: "photo.fill"),
          let data = uiImage.jpegData(compressionQuality: 1.0) else {
        fatalError("Mock image 'placeholder_image' not found or could not be converted to Data.")
    }
    
    episode.imageData = data
    dataManager.saveMainContext()
    
    return Player()
        .environmentObject(pm)
        .environmentObject(ThemeManager())
}
