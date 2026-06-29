import SwiftUI
import AVKit
import CoreData

func formatFloat(_ value: Float) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 1
    formatter.maximumFractionDigits = 2
    
    return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
}

struct PlayerMenu: View {
    @Environment(PlayerViewModel.self) var viewModel
    let rates: [Float] = [0.75,1.0,1.25,1.5,1.75,2.0]
    
    var body: some View {
        Menu {
            ForEach(rates, id: \.self) { rate in
                Button {
                    Task { viewModel.updateRate(rate) }
                } label: {
                    LabeledContent {
                        if rate == viewModel.playbackRate {
                            Image(systemName: "checkmark")
                        }
                    } label: {
                        Text("\(formatFloat(rate))x")
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text("\(formatFloat(viewModel.playbackRate))x")
                    .font(.system(size: 14, weight: .medium))
                    .monospacedDigit()
                
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

struct PlayerControlsView: View {
    @Environment(PlayerViewModel.self) var viewModel
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isEditing = false
    
    let forwardSkip: Int64
    let backwardSkip: Int64
    
    init(
        backwardSkip: Int64,
        forwardSkip: Int64
    ) {
        self.backwardSkip = backwardSkip
        self.forwardSkip = forwardSkip
    }
    
    var body: some View {
        @Bindable var viewModel = viewModel
        VStack {
            Slider(
                value: $viewModel.currentTime,
                in: 0...viewModel.duration,
                onEditingChanged: { isEditing in
                    viewModel.setIsSeeking(isEditing)
                    if !isEditing {
                        viewModel.finishedScrubbing()
                    }
                }
            )
            .tint(themeManager.selectedTheme.primaryColor)
            
            HStack {
                Text("\(viewModel.currentTimeString)")
                    .fontWeight(.semibold)
                Spacer()
                Text("- \(formattedTime(time: Double(viewModel.duration)-viewModel.currentTime))")
                    .fontWeight(.semibold)
            }
            .padding(.bottom, 20)
            
            HStack {
                Button(action: { viewModel.skipBackward(by: backwardSkip) }) {
                    Image(systemName: "gobackward.\(backwardSkip)")
                        .resizable()
                        .frame(width: 40, height: 45 )
                }
                Spacer()
                Button(action: { viewModel.togglePlayPause() }) {
                    Image(systemName: viewModel.playButtonIcon)
                        .resizable()
                        .frame(width: 35, height: 45 )
                }
                Spacer()
                Button(action: { viewModel.skipForward(by: forwardSkip) }) {
                    Image(systemName: "goforward.\(forwardSkip)")
                        .resizable()
                        .frame(width: 40, height: 45 )
                }
            }
            .padding([.leading, .trailing], 50)
        }
    }
}


struct EpisodeImageView: View {
    @Environment(PlayerViewModel.self) var viewModel
    @Binding var showDescriptions: Bool
    
    init(showDescriptions: Binding<Bool>) {
        _showDescriptions = showDescriptions
    }
    
    var body: some View {
        if let uIImg = viewModel.currentEpisodeImage {
            if !showDescriptions {
                Image(uiImage: uIImg)
                    .resizable()
                    .frame(width: 300, height: 300)
                    .cornerRadius(25)
            } else {
                Image(uiImage: uIImg)
                    .resizable()
                    .frame(width: 50, height: 50)
                    .cornerRadius(5)
                    .animation(.linear)
            }
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
    }
}
    
struct Player: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    // Declared as plain property to adhere to modern @Observable practices
    var viewModel: PlayerViewModel
    
    @State var showEpisodeNotes: Bool = false
        
    var body: some View {
        Color(themeManager.selectedTheme.secondoryColor)
            .ignoresSafeArea(.all)
            .overlay(
                VStack {
                    Spacer()
                    Text(viewModel.currentEpisode?.episodeTitle ?? "No episode selected").lineLimit(1)
                        .font(.title3)
                        .fontWeight(.regular)
                        .padding(.leading, 10)
                        .padding(.trailing, 10)
                        .padding(.top, 15)
                    
                    Text(viewModel.currentEpisode?.podcastTitle ?? "Podcast")
                        .font(.callout)
                        .foregroundStyle(Color(themeManager.selectedTheme.primaryColor)).opacity(0.7)
                    Spacer()
                    PlayerNotesAndImage(showDescription: $showEpisodeNotes)
                        .onTapGesture {
                            withAnimation(.linear(duration: 0.1)) {
                                showEpisodeNotes.toggle()
                            }
                        }
                        .environment(viewModel)
                        .environmentObject(themeManager)
                    
                    // Chapter display and list
                    PlayerChapters()
                        .environment(viewModel)
                        .environmentObject(themeManager)
                        .presentationDragIndicator(.visible)
                        .padding(.top, 40)
                    
                    // Player controls
                    Spacer()
                    VStack{
                        PlayerControlsView(
                            backwardSkip: Int64(viewModel.backwardSkip),
                            forwardSkip: Int64(viewModel.forwardSkip)
                        )
                            .padding([.leading, .trailing], 30)
                            .foregroundStyle(Color(themeManager.selectedTheme.primaryColor))
                            .environment(viewModel)
                        PlayerOptionsView(showDescription: $showEpisodeNotes)
                            .padding([.leading, .trailing], 30)
                            .padding(.top, 45)
                            .environment(viewModel)
                    }
                }
                .background(Color(themeManager.selectedTheme.secondoryColor))
                .foregroundStyle(Color(themeManager.selectedTheme.primaryColor))
            )
        }
}

struct PlayerNotesAndImage: View {
    @Environment(PlayerViewModel.self) var viewModel
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var showDescription: Bool
    
    init(showDescription: Binding<Bool>) {
        _showDescription = showDescription
    }
    
    var body: some View {
        VStack {
            EpisodeImageView(showDescriptions: $showDescription)
                .environment(viewModel)
            if showDescription {
                PlayerEpisodeDescriptionView(
                    html: viewModel.currentEpisodeDescription ?? "Bad"
                )
                .environmentObject(themeManager)
            }
        }
    }
}
