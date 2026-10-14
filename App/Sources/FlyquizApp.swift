import SwiftUI

@main
struct FlyquizApp: App {
    @State private var app = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(app)
                .preferredColorScheme(.dark)
                .tint(Theme.accent)
        }
    }
}

struct RootView: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        @Bindable var app = app
        NavigationStack {
            HomeView()
        }
        .fullScreenCover(item: $app.session) { session in
            GameContainerView(session: session)
        }
    }
}
