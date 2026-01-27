import Foundation

/// Representa un nodo en la estructura de árbol de un hilo.
/// Se define como clase (Reference Type) para permitir la construcción del árbol
/// de forma eficiente y evitar errores de "overlapping access" durante la mutación.
class ThreadNode: Identifiable {
    let id: Int
    let post: Post
    var replies: [ThreadNode]

    init(post: Post, replies: [ThreadNode] = []) {
        self.id = post.no
        self.post = post
        self.replies = replies
    }
}
