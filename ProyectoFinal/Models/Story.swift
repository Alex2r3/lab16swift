import Foundation

struct Story: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let coverImage: String
    let initialSceneID: String
    let scenes: [GameScene]
    let genre: String
    let duration: String
}

extension Story {
    var allEndings: [GameScene] {
        return scenes.filter { $0.isEnding }
    }
    
    func completionPercentage(progress: StoryProgress) -> Int {
        let visitedEndingsCount = allEndings.filter { progress.unlockedEndingIDs.contains($0.id) }.count
        let totalEndingsCount = allEndings.count
        guard totalEndingsCount > 0 else { return 0 }
        return Int(Double(visitedEndingsCount) / Double(totalEndingsCount) * 100)
    }
    
    func isSceneVisited(_ sceneID: String, progress: StoryProgress) -> Bool {
        return progress.visitedSceneIDs.contains(sceneID)
    }
}
