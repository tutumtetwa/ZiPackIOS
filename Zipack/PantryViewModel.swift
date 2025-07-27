
import Foundation
import FirebaseFirestore
import Combine

class PantryViewModel: ObservableObject {
    @Published var pantryItems: [PantryItem] = []
    @Published var newPantryItemName: String = ""
    @Published var newPantryItemExpiration: Date = Date() // Use Date for SwiftUI DatePicker
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private var db: Firestore { FirebaseManager.shared.db }
    private var userId: String? { FirebaseManager.shared.userId }
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupPantryListener()
    }

    private func setupPantryListener() {
        FirebaseManager.shared.$isAuthReady
            .filter { $0 }
            .compactMap { _ in FirebaseManager.shared.userId }
            .sink { [weak self] uid in
                guard let self = self else { return }
                // Ensure all UI-related updates happen on the main thread
                DispatchQueue.main.async {
                    self.isLoading = true
                }
                self.db.collection("artifacts/\(NATIVE_APP_ID)/users/\(uid)/pantryItems")
                    .addSnapshotListener { querySnapshot, error in
                        // Ensure all UI-related updates happen on the main thread
                        DispatchQueue.main.async {
                            self.isLoading = false
                            if let error = error {
                                self.errorMessage = "Error fetching pantry items: \(error.localizedDescription)"
                                print(self.errorMessage!)
                                return
                            }
                            self.pantryItems = querySnapshot?.documents.compactMap { document in
                                try? document.data(as: PantryItem.self)
                            } ?? []
                            // Client-side sort by expiration date (earliest first), then addedAt
                            self.pantryItems.sort { (item1, item2) -> Bool in
                                let dateFormatter = ISO8601DateFormatter() // Use a consistent formatter
                                let date1 = item1.expirationDate.flatMap { dateFormatter.date(from: $0) } ?? .distantFuture
                                let date2 = item2.expirationDate.flatMap { dateFormatter.date(from: $0) } ?? .distantFuture
                                
                                if date1 != date2 { return date1 < date2 }
                                return item1.addedAt.dateValue() < item2.addedAt.dateValue()
                            }
                        }
                    }
            }
            .store(in: &cancellables)
    }

    func addPantryItem() {
        guard let userId = userId, !newPantryItemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Pantry item name cannot be empty and user must be authenticated."
            return
        }
        // Ensure UI updates on main thread
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }

        // Format Date to String for Firestore storage (ISO8601 is good for consistency)
        let dateFormatter = ISO8601DateFormatter()
        let expirationDateString = dateFormatter.string(from: newPantryItemExpiration)

        let newItem = PantryItem(
            name: newPantryItemName.trimmingCharacters(in: .whitespacesAndNewlines),
            addedAt: Timestamp(date: Date()),
            expirationDate: expirationDateString
        )

        do {
            _ = try db.collection("artifacts/\(NATIVE_APP_ID)/users/\(userId)/pantryItems")
                .addDocument(from: newItem) { error in
                    // Ensure all UI-related updates happen on the main thread
                    DispatchQueue.main.async {
                        self.isLoading = false
                        if let error = error {
                            self.errorMessage = "Error adding pantry item: \(error.localizedDescription)"
                        } else {
                            self.newPantryItemName = "" // Clear input
                            self.newPantryItemExpiration = Date() // Reset date to today
                            print("Pantry item added successfully.")
                        }
                    }
                }
        } catch {
            // Ensure UI updates on main thread
            DispatchQueue.main.async {
                self.isLoading = false
                self.errorMessage = "Error encoding pantry item: \(error.localizedDescription)"
            }
        }
    }

    func removePantryItem(item: PantryItem) {
        guard let userId = userId, let id = item.id else { return }
        // Ensure UI updates on main thread
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        db.collection("artifacts/\(NATIVE_APP_ID)/users/\(userId)/pantryItems").document(id).delete { error in
            // Ensure all UI-related updates happen on the main thread
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = "Error removing pantry item: \(error.localizedDescription)"
                } else {
                    print("Pantry item removed successfully.")
                }
            }
        }
    }
    
    // Returns pantry items expiring within the next 7 days (inclusive of today)
    func getExpiringPantryItems() -> [PantryItem] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date()) // Start of today
        let sevenDaysFromNow = calendar.date(byAdding: .day, value: 7, to: today)!

        let dateFormatter = ISO8601DateFormatter()

        return pantryItems.filter { item in
            guard let expDateString = item.expirationDate,
                  let expDate = dateFormatter.date(from: expDateString) else {
                return false // No expiration date or invalid format
            }
            // Check if expiration date is today or in the future, and within 7 days from today
            return expDate >= today && expDate <= sevenDaysFromNow
        }
    }
}
