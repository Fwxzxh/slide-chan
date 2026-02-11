import Foundation
import UIKit

struct Post: Codable, Identifiable {
    // El 'no' es el ID único del post
    let no: Int

    var id: Int { no }

    // For replies: this is the ID of the thread being replied to. For OP: this value is zero
    let resto: Int?

    /// UNIX timestamp the post was created
    let time: Int?
    ///MM/DD/YY(Day)HH:MM (:SS on some boards), EST/EDT timezone
    let now: String?
    ///Name user posted with. Defaults to Anonymous
    let name: String?

    // Campos opcionales (no todos los posts tienen imagen o título)

    ///OP Subject text
    let sub: String?
    /// Comment (HTML escaped)
    let com: String?
    ///Filename as it appeared on the poster's device
    let filename: String?
    ///Filetype
    let ext: String?
    ///Unix timestamp + microtime that an image was uploaded
    let tim: Int64?
    ///Image width dimension
    let w: Int?
    ///Image height dimension
    let h: Int?
    ///Thumbnail image width dimension
    let tn_w: Int?
    ///Thumbnail image height dimension
    let tn_h: Int?
    ///Total number of replies to a thread
    let replies: Int?
    /// Total number of image replies to a thread
    let images: Int?

    /// Calculated aspect ratio for the media
    var aspectRatio: CGFloat {
        guard let w = w, let h = h, w > 0, h > 0 else { return 1.5 }
        return CGFloat(w) / CGFloat(h)
    }

    // Nuevos campos para mejorar la compatibilidad
    let sticky: Int?
    let closed: Int?
    let archived: Int?
    let trip: String?
    let capcode: String?
    let country: String?
    let country_name: String?
    let filedeleted: Int?
    let spoiler: Int?
    let custom_spoiler: Int?

    // MARK: - Helper Properties

    /// Indica si el post tiene un archivo adjunto
    var hasFile: Bool {
        return tim != nil && filedeleted != 1
    }

    /// Indica si la imagen es un spoiler
    var isSpoiler: Bool {
        return spoiler == 1
    }

    /// Limpia el comentario de etiquetas HTML, maneja saltos de línea y entidades comunes
    var cleanComment: String {
        guard var text = com else { return "" }

        // 1. Manejar saltos de línea HTML antes de limpiar etiquetas
        text = text.replacingOccurrences(of: "<br>", with: "\n")

        // 2. Limpiar etiquetas HTML (ej: <span class="quote">)
        text = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)

        // 3. Decodificar entidades HTML
        return text.decodedHTML.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Extrae los IDs de los posts a los que este post responde.
    /// 4chan usa &gt;&gt; para las citas en su API JSON.
    func replyIds() -> [Int] {
        guard let text = com else { return [] }
        // Detecta tanto >> como &gt;&gt; seguido de números
        let pattern = "(?:>>|&gt;&gt;)([0-9]+)"
        let regex = try? NSRegularExpression(pattern: pattern)
        let nsString = text as NSString
        let results = regex?.matches(in: text, range: NSRange(location: 0, length: nsString.length))

        return results?.compactMap { Int(nsString.substring(with: $0.range(at: 1))) } ?? []
    }

    /// Genera la URL de la imagen original (necesitas saber el board)
    func imageUrl(board: String) -> URL? {
        guard let tim = tim, let ext = ext else { return nil }
        // Forzamos String(tim) para evitar que el sistema añada separadores de miles
        return URL(string: "https://i.4cdn.org/\(board)/\(String(tim))\(ext)")
    }

    /// Genera la URL de la miniatura
    func thumbnailUrl(board: String) -> URL? {
        if isSpoiler {
            return URL(string: "https://s.4cdn.org/image/spoiler.png")
        }
        guard let tim = tim else { return nil }
        // Forzamos String(tim) para evitar separadores en la URL
        return URL(string: "https://i.4cdn.org/\(board)/\(String(tim))s.jpg")
    }

    /// Identifica el tipo de media basado en la extensión
    var mediaType: MediaType {
        guard let ext = ext?.lowercased() else { return .none }
        switch ext {
        case ".jpg", ".jpeg", ".png", ".heic":
            return .image
        case ".gif":
            return .gif
        case ".webm", ".mp4":
            return .video
        case ".pdf":
            return .pdf
        default:
            return .unknown
        }
    }

    enum MediaType {
        case image
        case gif
        case video
        case pdf
        case none
        case unknown
    }
}

/// Estructura para decodificar un hilo (Thread) completo de la API
struct ThreadResponse: Codable {
    let posts: [Post]
}


extension String {
    var decodedHTML: String {
        return self.replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&#039;", with: "'")
            .replacingOccurrences(of: "&apos;", with: "'")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&nbsp;", with: " ")
    }
}
