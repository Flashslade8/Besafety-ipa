import SwiftUI

struct RootView: View {
    @EnvironmentObject var auth: AuthViewModel

    var body: some View {
        if auth.user == nil {
            AuthView()
        } else {
            MainTabs()
        }
    }
}

struct MainTabs: View {
    @EnvironmentObject var auth: AuthViewModel
    @StateObject private var store = TripStore()

    var body: some View {
        TabView {
            ContentView()
                .tabItem { Label("Home", systemImage: "map") }
            TripsView()
                .tabItem { Label("Trips", systemImage: "bubble.left.and.bubble.right") }
            AccountView()
                .tabItem { Label("Account", systemImage: "person.circle") }
        }
        .environmentObject(store)
        .tint(Brand.purple)
        .onAppear {
            if let uid = auth.user?.uid { store.start(uid: uid) }
        }
        .onDisappear { store.stop() }
    }
}

struct AccountView: View {
    @EnvironmentObject var auth: AuthViewModel

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(auth.displayName).font(.headline)
                    if let email = auth.user?.email { Text(email).foregroundColor(.secondary) }
                }
                Section {
                    Button("Log out", role: .destructive) { auth.signOut() }
                }
            }
            .navigationTitle("Account")
        }
    }
}
