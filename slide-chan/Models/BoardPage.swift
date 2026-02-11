import Foundation

/// Representa una página del catálogo de un tablón.
/// La API de 4chan devuelve el catálogo como un array de estas páginas.
struct BoardPage: Codable {
    let page: Int?
    let threads: [Post]?
}
