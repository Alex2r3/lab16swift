import Foundation

struct GameScene: Identifiable, Codable {
    let id: String
    let characterName: String?
    let dialogue: String
    let backgroundImage: String
    let choices: [Choice]
    let isEnding: Bool
    let musicTrack: String?
    let timeLimit: Double?
    let endingTitle: String?
    
    init(
        id: String,
        characterName: String? = nil,
        dialogue: String,
        backgroundImage: String,
        choices: [Choice] = [],
        isEnding: Bool = false,
        musicTrack: String? = nil,
        timeLimit: Double? = nil,
        endingTitle: String? = nil
    ) {
        self.id = id
        self.characterName = characterName
        self.dialogue = dialogue
        self.backgroundImage = backgroundImage
        self.choices = choices
        self.isEnding = isEnding
        self.musicTrack = musicTrack
        self.timeLimit = timeLimit
        self.endingTitle = endingTitle
    }
}
