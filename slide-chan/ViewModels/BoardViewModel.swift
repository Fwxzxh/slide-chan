import Foundation
import Combine

@MainActor
class BoardViewModel: ObservableObject {
    @Published var boards: [Board] = []
    @Published var favoriteBoardIDs: Set<String> = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    /// Filtro opcional para mostrar solo tablones SFW (Safe For Work)
    @Published var showOnlySFW: Bool = false {
        didSet {
            filterBoards()
        }
    }

    private var allBoards: [Board] = []
    private let apiService = APIService.shared
    private let favoritesKey = "favorite_boards_ids"

    init() {
        loadFavorites()
    }

    /// Obtiene la lista completa de tablones usando el APIService
    func fetchBoards() async {
        isLoading = true
        errorMessage = nil

        do {
            let fetchedBoards = try await apiService.fetchBoards()
            self.allBoards = fetchedBoards
            filterBoards()
            self.isLoading = false
        } catch {
            self.errorMessage = "Error al cargar tablones: \(error.localizedDescription)"
            self.isLoading = false
            print("Error in BoardViewModel: \(error)")
        }
    }

    /// Filtra los tablones basados en las preferencias del usuario
    private func filterBoards() {
        if showOnlySFW {
            self.boards = allBoards.filter { $0.isWorkSafe }
        } else {
            self.boards = allBoards
        }
    }

    // MARK: - Favorites Logic

    /// Lista de tablones marcados como favoritos que están presentes en la lista actual
    var favoriteBoards: [Board] {
        allBoards.filter { favoriteBoardIDs.contains($0.board) }
    }

    /// Devuelve si un tablón específico es favorito
    func isFavorite(_ board: Board) -> Bool {
        favoriteBoardIDs.contains(board.board)
    }

    /// Alterna el estado de favorito de un tablón y lo persiste
    func toggleFavorite(_ board: Board) {
        if favoriteBoardIDs.contains(board.board) {
            favoriteBoardIDs.remove(board.board)
        } else {
            favoriteBoardIDs.insert(board.board)
        }
        saveFavorites()
    }

    /// Guarda los IDs de los favoritos en UserDefaults
    private func saveFavorites() {
        let array = Array(favoriteBoardIDs)
        UserDefaults.standard.set(array, forKey: favoritesKey)
    }

    /// Carga los IDs de los favoritos desde UserDefaults
    private func loadFavorites() {
        if let array = UserDefaults.standard.stringArray(forKey: favoritesKey) {
            self.favoriteBoardIDs = Set(array)
        }
    }
}
