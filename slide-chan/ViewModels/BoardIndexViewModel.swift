import Foundation
import Combine

@MainActor
class BoardIndexViewModel: ObservableObject {
    @Published var threads: [Post] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    let board: String
    private let apiService = APIService.shared

    init(board: String) {
        self.board = board
    }

    /// Carga el catálogo completo del tablón usando el APIService
    func fetchCatalog() async {
        isLoading = true
        errorMessage = nil

        do {
            let fetchedThreads = try await apiService.fetchCatalog(board: board)
            self.threads = fetchedThreads
            self.isLoading = false
        } catch {
            self.errorMessage = "Error loading catalog: \(error.localizedDescription)"
            self.isLoading = false
            print("Error in BoardIndexViewModel: \(error)")
        }
    }

    /// Función de conveniencia para refrescar el catálogo
    func refresh() async {
        await fetchCatalog()
    }
}
