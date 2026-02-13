import Foundation

/// Protocol defining the API service requirements for 4chan communication.
protocol APIServiceProtocol {
    /// Fetches the list of all available boards.
    func fetchBoards() async throws -> [Board]
    /// Fetches the catalog for a specific board.
    func fetchCatalog(board: String) async throws -> [Post]
    /// Fetches all posts within a specific thread.
    func fetchThread(board: String, threadId: Int) async throws -> [Post]
}

/// Service responsible for all 4chan API communications.
///
/// Centralizing network logic ensures consistency and facilitates testing via mocks.
final class APIService: APIServiceProtocol, Sendable {
    /// Global instance accessible from any context.
    nonisolated static let shared: APIServiceProtocol = APIService()
    private let decoder = JSONDecoder()

    private init() {}

    /// Possible errors encountered during API requests.
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

    /// Generic helper to perform data fetching and decoding.
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

    func fetchBoards() async throws -> [Board] {
        let response: BoardsResponse = try await fetch(from: APIConstants.boards())
        return response.boards
    }

    func fetchCatalog(board: String) async throws -> [Post] {
        let pages: [BoardPage] = try await fetch(from: APIConstants.catalog(board: board))
        return pages.flatMap { $0.threads ?? [] }
    }

    func fetchThread(board: String, threadId: Int) async throws -> [Post] {
        let response: ThreadResponse = try await fetch(from: APIConstants.thread(board: board, threadId: threadId))
        return response.posts
    }
}
