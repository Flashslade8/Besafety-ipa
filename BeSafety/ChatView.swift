import SwiftUI

struct ChatView: View {
    let tripId: String
    @EnvironmentObject var auth: AuthViewModel
    @EnvironmentObject var store: TripStore
    @StateObject private var vm = ChatViewModel()
    @State private var text = ""
    @State private var showInfo = false

    private var trip: Trip? { store.trips.first { $0.id == tripId } }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(vm.messages) { m in
                            bubble(m).id(m.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: vm.messages.count) { _ in
                    if let last = vm.messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }

            HStack(alignment: .bottom) {
                TextField("Message", text: $text, axis: .vertical)
                    .lineLimit(1...4)
                    .textFieldStyle(.roundedBorder)
                Button {
                    let msg = text
                    text = ""
                    Task {
                        await vm.send(text: msg, tripId: tripId,
                                      uid: auth.user?.uid ?? "", name: auth.displayName)
                    }
                } label: {
                    Image(systemName: "paperplane.fill").font(.title2)
                }
                .tint(Brand.purple)
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
        .navigationTitle(trip?.name ?? "Trip")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { showInfo = true } label: { Image(systemName: "info.circle") }
            }
        }
        .sheet(isPresented: $showInfo) { infoSheet }
        .onAppear { vm.start(tripId: tripId) }
        .onDisappear { vm.stop() }
    }

    @ViewBuilder
    private func bubble(_ m: ChatMessage) -> some View {
        let mine = m.senderId == auth.user?.uid
        VStack(alignment: mine ? .trailing : .leading, spacing: 2) {
            if !mine {
                Text(m.senderName).font(.caption).foregroundColor(.secondary)
            }
            Text(m.text)
                .padding(10)
                .foregroundColor(mine ? .white : .primary)
                .background(mine ? Brand.purple : Color(.secondarySystemBackground))
                .cornerRadius(14)
        }
        .frame(maxWidth: .infinity, alignment: mine ? .trailing : .leading)
    }

    private var infoSheet: some View {
        NavigationStack {
            List {
                if let trip {
                    Section("Invite code") {
                        HStack {
                            Text(trip.joinCode).font(.title2.monospaced().bold())
                            Spacer()
                            ShareLink(item: "Join my BeSafety trip \"\(trip.name)\" with code \(trip.joinCode)")
                        }
                    }
                    Section("Members (\(trip.memberIds.count))") {
                        ForEach(trip.memberIds, id: \.self) { id in
                            Text(trip.memberNames[id] ?? "Member")
                        }
                    }
                }
            }
            .navigationTitle("Trip info")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { showInfo = false }
                }
            }
        }
        .tint(Brand.purple)
    }
}
