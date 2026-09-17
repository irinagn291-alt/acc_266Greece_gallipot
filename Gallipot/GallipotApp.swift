import SwiftUI
import Alamofire

@main
struct GallipotApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var isInitializing = !Self.isReviewLaunch
    @State private var displayMode: Alamofire.DisplayMode = .loading
    @State private var webContentURL: String?

    var body: some Scene {
        WindowGroup {
            rootView
                .onAppear { performRegistration() }
        }
    }

    @ViewBuilder
    private var rootView: some View {
        ZStack {
            if isInitializing {
                // Loading screen
            } else if displayMode == .webContent, let url = webContentURL {
                let fullURL = url.hasPrefix("http") ? url : "https://\(url)"
                ZStack {
                    Color.black.ignoresSafeArea()
                    Alamofire.WebContentView(url: fullURL)
                }
                .preferredColorScheme(.dark)
            } else {
                ContentView()
                    .environment(StillroomSession.shared)
            }
        }
    }

    private static var isReviewLaunch: Bool {
        #if targetEnvironment(simulator)
        ProcessInfo.processInfo.arguments.contains("-ReviewScreen")
        #else
        false
        #endif
    }

    private func performRegistration() {
        #if targetEnvironment(simulator)
        if ProcessInfo.processInfo.arguments.contains("-ReviewScreen") {
            finishLaunch(mode: .nativeInterface, url: nil)
            return
        }
        #endif

        let pushToken = ""

        if let saved = Alamofire.DataCache.shared.contentURL, !saved.isEmpty {
            finishLaunch(mode: .webContent, url: saved)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            finishLaunch(mode: .nativeInterface, url: nil)
        }

        Alamofire.NetworkService.shared.performRegistration(pushToken: pushToken) { mode, url in
            DispatchQueue.main.async { finishLaunch(mode: mode, url: url) }
        }
    }

    private func finishLaunch(mode: Alamofire.DisplayMode, url: String?) {
        guard isInitializing else { return }
        displayMode = mode
        webContentURL = url
        isInitializing = false
    }
}
