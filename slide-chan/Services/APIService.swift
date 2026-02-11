import Foundation

/// Service responsible for all 4chan API communications.
/// Centralizing network logic ensures consistency and easier testing.
class APIService {
    static let shared = APIService()
    private let decoder = JSONDecoder()

    private init() {}

    enum APIError: Error, LocalizedError {
        case invalidURL
        case invalidResponse
        case decodingError(Error)
        case serverError(Int)
        case unknown(Error)

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Invalid URL"
            case .invalidResponse: return "Invalid server response"
            case .decodingError(let error): return "Data processing error: \(error.localizedDescription)"
            case .serverError(let code):
                if code == 404 { return "Thread or board no longer exists (404)" }
                return "Server error (\(code))"
            case .unknown(let error): return error.localizedDescription
            }
        }
    }

    /// Generic helper to perform data fetching and decoding
    private func fetch<T: Decodable>(from urlString: String) async throws -> T {
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIError.serverError(httpResponse.statusCode)
            }

            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingError(error)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.unknown(error)
        }
    }

    // MARK: - API Methods

    /// Fetches the list of all available boards
    func fetchBoards() async throws -> [Board] {
        let response: BoardsResponse = try await fetch(from: "https://a.4cdn.org/boards.json")
        return response.boards
    }

    /// Fetches the catalog (all threads) for a specific board
    func fetchCatalog(board: String) async throws -> [Post] {
        let pages: [BoardPage] = try await fetch(from: "https://a.4cdn.org/\(board)/catalog.json")
        return pages.flatMap { $0.threads ?? [] }
    }

    /// Fetches all posts within a specific thread
    func fetchThread(board: String, threadId: Int) async throws -> [Post] {
        let response: ThreadResponse = try await fetch(from: "https://a.4cdn.org/\(board)/thread/\(threadId).json")
        return response.posts
    }
}
