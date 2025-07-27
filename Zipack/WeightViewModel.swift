
import Foundation
import FirebaseFirestore
import Combine

class WeightViewModel: ObservableObject {
    @Published var weightHistory: [WeightEntry] = []
    @Published var newWeight: Double? // Optional to allow empty input field
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private var db: Firestore { FirebaseManager.shared.db }
    private var userId: String? { FirebaseManager.shared.userId }
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupWeightHistoryListener()
    }

    private func setupWeightHistoryListener() {
        FirebaseManager.shared.$isAuthReady
            .filter { $0 } // Wait until Firebase is ready
            .compactMap { _ in FirebaseManager.shared.userId }
            .sink { [weak self] uid in
                guard let self = self else { return }
                // Ensure all UI-related updates happen on the main thread
                DispatchQueue.main.async {
                    self.isLoading = true
                }
                self.db.collection("artifacts/\(NATIVE_APP_ID)/users/\(uid)/weightHistory")
                    .order(by: "timestamp", descending: false) // Order by timestamp to get chronological history
                    .addSnapshotListener { querySnapshot, error in
                        // Ensure all UI-related updates happen on the main thread
                        DispatchQueue.main.async {
                            self.isLoading = false
                            if let error = error {
                                self.errorMessage = "Error fetching weight history: \(error.localizedDescription)"
                                print(self.errorMessage!)
                                return
                            }
                            // Map documents to WeightEntry objects
                            self.weightHistory = querySnapshot?.documents.compactMap { document in
                                try? document.data(as: WeightEntry.self)
                            } ?? []
                        }
                    }
            }
            .store(in: &cancellables)
    }

    func addWeight() {
        guard let userId = userId, let weight = newWeight, weight > 0 else {
            errorMessage = "Please enter a valid weight (greater than 0) and ensure user is authenticated."
            return
        }
        // Ensure UI updates on main thread
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        do {
            // Add a new document to the weightHistory collection
            _ = try db.collection("artifacts/\(NATIVE_APP_ID)/users/\(userId)/weightHistory")
                .addDocument(from: WeightEntry(weight: weight, timestamp: Timestamp(date: Date()))) { error in
                    // Ensure all UI-related updates happen on the main thread
                    DispatchQueue.main.async {
                        self.isLoading = false
                        if let error = error {
                            self.errorMessage = "Error adding weight: \(error.localizedDescription)"
                        } else {
                            self.newWeight = nil // Clear input field after successful add
                            print("Weight logged successfully.")
                        }
                    }
                }
        } catch {
            // Ensure UI updates on main thread
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Error encoding weight entry: \(error.localizedDescription)"
            }
        }
    }
}
