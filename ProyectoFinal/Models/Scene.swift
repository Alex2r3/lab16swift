import Foundation

struct GameScene: Identifiable, Codable {
    let id: UUID
    let characterName: String?
    let dialogue: String
    let backgroundImage: String
    let choices: [Choice]
    let isEnding: Bool
    
    init(id: UUID = UUID(), characterName: String? = nil, dialogue: String, backgroundImage: String, choices: [Choice] = [], isEnding: Bool = false) {
        self.id = id
        self.characterName = characterName
        self.dialogue = dialogue
        self.backgroundImage = backgroundImage
        self.choices = choices
        self.isEnding = isEnding
    }
}
