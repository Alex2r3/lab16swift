import Foundation

struct Story: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let coverImage: String
    let initialSceneID: UUID
    let scenes: [GameScene]
    let genre: String
    let duration: String
}
