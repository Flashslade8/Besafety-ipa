import Foundation
import FirebaseFirestore

struct Trip: Identifiable {
    let id: String
    let name: String
    let joinCode: String
    let memberIds: [String]
    let memberNames: [String: String]
    let createdAt: Date

    init?(doc: QueryDocumentSnapshot) {
        let d = doc.data()
        guard let name = d["name"] as? String,
              let code = d["joinCode"] as? String,
              let ids = d["memberIds"] as? [String] else { return nil }
        self.id = doc.documentID
        self.name = name
        self.joinCode = code
        self.memberIds = ids
        self.memberNames = d["memberNames"] as? [String: String] ?? [:]
        self.createdAt = (d["createdAt"] as? Timestamp)?.dateValue() ?? Date()
    }
}

struct ChatMessage: Identifiable {
    let id: String
    let senderId: String
    let senderName: String
    let text: String
    let createdAt: Date
}

enum TripError: LocalizedError {
    case invalidCode
    var errorDescription: String? { "That trip code doesn't exist. Check it and try again." }
}

@MainActor
final class TripStore: ObservableObject {
    @Published var trips: [Trip] = []
    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()

    func start(uid: String) {
        listener?.remove()
        listener = db.collection("trips")
            .whereField("memberIds", arrayContains: uid)
            .addSnapshotListener { [weak self] snap, _ in
                guard let docs = snap?.documents else { return }
                let items = docs.compactMap { Trip(doc: $0) }
                    .sorted { $0.createdAt > $1.createdAt }
                Task { @MainActor in self?.trips = items }
            }
    }

    func stop() {
        listener?.remove()
        listener = nil
        trips = []
    }

    func createTrip(name: String, uid: String, displayName: String) async throws {
        let code = Self.makeCode()
        let ref = db.collection("trips").document()
        try await ref.setData([
            "name": name,
            "ownerId": uid,
            "joinCode": code,
            "memberIds": [uid],
            "memberNames": [uid: displayName],
            "createdAt": FieldValue.serverTimestamp()
        ])
        try await db.collection("joinCodes").document(code)
            .setData(["tripId": ref.documentID])
    }

    func joinTrip(code: String, uid: String, displayName: String) async throws {
        let clean = code.trimmingCharacters(in: .whitespaces).uppercased()
        let codeDoc = try await db.collection("joinCodes").document(clean).getDocument()
        guard let tripId = codeDoc.data()?["tripId"] as? String else {
            throw TripError.invalidCode
        }
        try await db.collection("trips").document(tripId).updateData([
            "memberIds": FieldValue.arrayUnion([uid]),
            "memberNames.\(uid)": displayName
        ])
    }

    private static func makeCode() -> String {
        let chars = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<6).map { _ in chars.randomElement()! })
    }
}

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()

    func start(tripId: String) {
        listener?.remove()
        listener = db.collection("trips").document(tripId).collection("messages")
            .order(by: "createdAt")
            .addSnapshotListener { [weak self] snap, _ in
                guard let docs = snap?.documents else { return }
                let items = docs.map { doc -> ChatMessage in
                    let d = doc.data()
                    return ChatMessage(
                        id: doc.documentID,
                        senderId: d["senderId"] as? String ?? "",
                        senderName: d["senderName"] as? String ?? "Member",
                        text: d["text"] as? String ?? "",
                        createdAt: (d["createdAt"] as? Timestamp)?.dateValue() ?? Date()
                    )
                }
                Task { @MainActor in self?.messages = items }
            }
    }

    func stop() {
        listener?.remove()
        listener = nil
    }

    func send(text: String, tripId: String, uid: String, name: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        try? await db.collection("trips").document(tripId).collection("messages").addDocument(data: [
            "senderId": uid,
            "senderName": name,
            "text": trimmed,
            "createdAt": FieldValue.serverTimestamp()
        ])
    }
}
