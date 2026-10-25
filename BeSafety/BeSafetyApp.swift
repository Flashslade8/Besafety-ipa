import SwiftUI
import FirebaseCore
import GoogleSignIn

@main
struct BeSafetyApp: App {
    @StateObject private var auth: AuthViewModel

    init() {
        FirebaseApp.configure()
        _auth = StateObject(wrappedValue: AuthViewModel())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
