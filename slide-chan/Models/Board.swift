import Foundation

struct Board: Codable, Identifiable {
    // 'board' es el ID corto del tablón (ej: "v", "a", "jp")
    let board: String
    var id: String { board }

    // 'title' es el nombre completo del tablón (ej: "Video Games")
    let title: String

    // 1 si es "Work Safe", 0 si no
    let ws_board: Int
    /// How many threads are on a single index page
    let per_page: Int

    //How many index pages does the board have
    let pages: Int

    // Otros campos opcionales útiles

    ///SEO meta description content for a board
    let meta_description: String?

    ///Maximum file size allowed for non .webm attachments (in KB)
    let max_filesize: Int?

    ///Maximum number of characters allowed in a post comment
    let max_comment_chars: Int?
    ///Maximum number of image replies per thread before image replies are discarded
    let image_limit: Int?

    let cooldowns: Cooldowns?

    // MARK: - Computed Properties

    /// Devuelve si el tablón es seguro para el trabajo
    var isWorkSafe: Bool {
        return ws_board == 1
    }

    /// Nombre formateado para mostrar en listas (ej: /v/ - Video Games)
    var displayName: String {
        return "/\(board)/ - \(title)".decodedHTML
    }

    /// Descripción limpia para mostrar en listas (ej: "Video Games")
    var cleanDescription: String {
        return (meta_description ?? "").decodedHTML
        // guard let desc = meta_description else { return "" }
        // return desc.replacingOccurrences(of: "&quot;", with: "\"")
        //            .replacingOccurrences(of: "&amp;", with: "&")
        //            .replacingOccurrences(of: "&#039;", with: "'")
        //            .replacingOccurrences(of: "&gt;", with: ">")
        //            .replacingOccurrences(of: "&lt;", with: "<")
    }
}

struct Cooldowns: Codable {
    let threads: Int
    let replies: Int
    let images: Int
}

/// Estructura para decodificar la lista completa de tablones de la API (https://a.4cdn.org/boards.json)
struct BoardsResponse: Codable {
    let boards: [Board]
}
