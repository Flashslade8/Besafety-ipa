import SwiftUI
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import GoogleSignIn

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var errorMessage: String?
    @Published var isLoading = false
    private var handle: AuthStateDidChangeListenerHandle?

    var displayName: String {
        if let n = user?.displayName, !n.isEmpty { return n }
        return user?.email?.components(separatedBy: "@").first ?? "Member"
    }

    init() {
        user = Auth.auth().currentUser
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in self?.user = user }
        }
    }

    func signIn(email: String, password: String) async {
        await run {
            try await Auth.auth().signIn(withEmail: email, password: password)
        }
    }

    func signUp(name: String, email: String, password: String) async {
        await run {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let change = result.user.createProfileChangeRequest()
            change.displayName = name
            try await change.commitChanges()
            self.user = Auth.auth().currentUser
            await self.saveProfile()
        }
    }

    func signInWithGoogle() async {
        await run {
            guard let clientID = FirebaseApp.app()?.options.clientID else {
                throw NSError(domain: "BeSafety", code: 1, userInfo: [NSLocalizedDescriptionKey: "Google sign-in is not configured. Check GoogleService-Info.plist."])
            }
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let root = scene.windows.first?.rootViewController else {
                throw NSError(domain: "BeSafety", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not open Google sign-in."])
            }
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: root)
            guard let idToken = result.user.idToken?.tokenString else {
                throw NSError(domain: "BeSafety", code: 3, userInfo: [NSLocalizedDescriptionKey: "Google did not return a token."])
            }
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            try await Auth.auth().signIn(with: credential)
            await self.saveProfile()
        }
    }

    func resetPassword(email: String) async {
        await run {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            self.errorMessage = "Password reset email sent."
        }
    }

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        try? Auth.auth().signOut()
    }

    private func saveProfile() async {
        guard let u = Auth.auth().currentUser else { return }
        try? await Firestore.firestore().collection("users").document(u.uid).setData([
            "displayName": u.displayName ?? displayName,
            "email": u.email ?? ""
        ], merge: true)
    }

    private func run(_ work: @escaping () async throws -> Void) async {
        isLoading = true
        errorMessage = nil
        do { try await work() }
        catch { errorMessage = error.localizedDescription }
        isLoading = false
    }
}
