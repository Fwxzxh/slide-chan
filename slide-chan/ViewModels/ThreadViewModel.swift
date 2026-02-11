import Foundation
import Combine

@MainActor
class ThreadViewModel: ObservableObject {
    @Published var posts: [Post] = []
    @Published var rootNode: ThreadNode?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let board: String
    private let threadId: Int
    private let apiService = APIService.shared

    init(board: String, threadId: Int) {
        self.board = board
        self.threadId = threadId
    }

    /// Fetches all posts from a specific thread and builds the hierarchical tree
    func fetchThread() async {
        print("DEBUG: Iniciando fetchThread para hilo \(threadId) en board /\(board)/")
        guard !isLoading else {
            print("DEBUG: Fetch cancelado - ya está cargando")
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let fetchedPosts = try await apiService.fetchThread(board: board, threadId: threadId)
            print("DEBUG: API respondió con \(fetchedPosts.count) posts")

            self.posts = fetchedPosts
            buildTree(from: fetchedPosts)

            print("DEBUG: Árbol construido. rootNode es \(rootNode == nil ? "NULO" : "VÁLIDO")")
            self.isLoading = false
        } catch {
            print("DEBUG: ERROR in fetchThread: \(error)")
            self.errorMessage = "Error loading thread: \(error.localizedDescription)"
            self.isLoading = false
        }
    }

    /// Convierte la lista plana de posts de 4chan en una estructura de árbol.
    private func buildTree(from allPosts: [Post]) {
        guard let op = allPosts.first else {
            self.rootNode = nil
            return
        }

        // 1. Crear un diccionario de todos los posts envueltos en nodos (clases) para acceso rápido
        let nodes = allPosts.reduce(into: [Int: ThreadNode]()) { dict, post in
            dict[post.no] = ThreadNode(post: post)
        }

        // 2. Relacionar cada post con sus padres (quienes son citados)
        for post in allPosts {
            guard let currentNode = nodes[post.no] else { continue }
            let quotedIds = post.replyIds()

            // En 4chan, si un post no cita a nadie específicamente, se considera respuesta al OP
            if quotedIds.isEmpty && post.no != op.no {
                nodes[op.no]?.replies.append(currentNode)
            } else {
                // Usamos un Set para evitar duplicados si un post cita varias veces al mismo post
                for pId in Set(quotedIds) {
                    // Evitamos auto-citas y verificamos que el post citado exista en este hilo
                    if pId != post.no, let parentNode = nodes[pId] {
                        parentNode.replies.append(currentNode)
                    }
                }
            }
        }

        // 3. Asignamos el nodo raíz.
        // Esto disparará la actualización de la UI en ThreadLoadingView
        if let opNode = nodes[op.no] {
            self.rootNode = opNode
        }
    }

    /// Helper to refresh the thread
    func refresh() async {
        await fetchThread()
    }
}
