import SwiftUI

struct TripsView: View {
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var store: TripStore
    @State private var showCreate = false
    @State private var showJoin = false
    @State private var input = ""
    @State private var errorText: String?

    var body: some View {
        NavigationStack {
            Group {
                if store.trips.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.largeTitle).foregroundColor(.secondary)
                        Text("No trips yet").font(.headline)
                        Text("Create a trip or join one with a code.")
                            .font(.subheadline).foregroundColor(.secondary)
                    }
                } else {
                    List(store.trips) { trip in
                        NavigationLink {
                            ChatView(tripId: trip.id)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(trip.name).font(.headline)
                                Text("\(trip.memberIds.count) member\(trip.memberIds.count == 1 ? "" : "s")")
                                    .font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("My Trips")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Create a trip", systemImage: "plus") { input = ""; showCreate = true }
                        Button("Join with code", systemImage: "person.badge.plus") { input = ""; showJoin = true }
                    } label: { Image(systemName: "plus.circle.fill") }
                }
            }
            .alert("New trip", isPresented: $showCreate) {
                TextField("Trip name", text: $input)
                Button("Create") {
                    guard let uid = auth.user?.uid else { return }
                    Task {
                        do { try await store.createTrip(name: input, uid: uid, displayName: auth.displayName) }
                        catch { errorText = error.localizedDescription }
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Join a trip", isPresented: $showJoin) {
                TextField("6-character code", text: $input)
                    .textInputAutocapitalization(.characters)
                Button("Join") {
                    guard let uid = auth.user?.uid else { return }
                    Task {
                        do { try await store.joinTrip(code: input, uid: uid, displayName: auth.displayName) }
                        catch { errorText = error.localizedDescription }
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            .alert("Something went wrong", isPresented: Binding(
                get: { errorText != nil },
                set: { if !$0 { errorText = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: { Text(errorText ?? "") }
        }
    }
}
