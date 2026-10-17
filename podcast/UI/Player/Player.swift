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

struct Player: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    // Declared as plain property to adhere to modern @Observable practices
    var viewModel: PlayerViewModel
    var bookmarksViewModel: BookmarksViewModel
    
    @State var showEpisodeNotes: Bool = false
         
    var body: some View {
        ZStack {
            VStack {
                PlayerHeaderView()
                PlayerNotesAndImage(showDescription: $showEpisodeNotes)
                    .onTapGesture {
                        withAnimation(.linear(duration: 0.1)) {
                            showEpisodeNotes.toggle()
                        }
                    }
                PlayerChapters()
                    .presentationDragIndicator(.visible)
                    .padding(.top, 40)
                Spacer()
                PlayerControlsView()
                    .padding(.horizontal, 50)
                PlayerOptionsView()
                    .padding(.horizontal, 50)
                    .padding(.top, 40)
            }
        }
        .background(Color(themeManager.selectedTheme.secondaryColor).ignoresSafeArea())
        .foregroundStyle(Color(themeManager.selectedTheme.primaryColor))
        .environment(viewModel)
        .environment(bookmarksViewModel)
        .environmentObject(themeManager)
    }
}

#Preview {
    Player(
        viewModel: PlayerViewModel.preview,
        bookmarksViewModel: BookmarksViewModel.preview
    )
        .environmentObject(ThemeManager())
}
