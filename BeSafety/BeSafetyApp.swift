import SwiftUI
import FirebaseCore
import GoogleSignIn

@main
struct BeSafetyApp: App {
    static let configured: Bool = {
        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
            return false
        }
        FirebaseApp.configure()
        return true
    }()

    var body: some Scene {
        WindowGroup {
            if Self.configured {
                AppRoot()
            } else {
                VStack(spacing: 12) {
                    Text("Setup problem").font(.title.bold())
                    Text("GoogleService-Info.plist is missing from the app. Check it is inside the BeSafety folder in GitHub, then rebuild.")
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
        }
    }
}

struct AppRoot: View {
    @StateObject private var auth = AuthViewModel()

    var body: some View {
        RootView()
            .environmentObject(auth)
            .onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
            }
    }
}
