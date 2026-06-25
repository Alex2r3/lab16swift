import Foundation
import SwiftData

@Model
class OfflineStory {
    @Attribute(.unique) var id: String
    var jsonData: Data
    var isDownloaded: Bool
    
    init(id: String, jsonData: Data, isDownloaded: Bool = true) {
        self.id = id
        self.jsonData = jsonData
        self.isDownloaded = isDownloaded
    }
}

@Model
class OfflineProgress {
    @Attribute(.unique) var id: String // e.g., "userId_storyTitle"
    var userId: String
    var storyTitle: String
    var visitedSceneIDsData: Data
    var unlockedEndingIDsData: Data
    var lastUpdated: Date
    var isSyncedWithRemote: Bool
    
    init(userId: String, storyTitle: String, visitedSceneIDs: Set<String>, unlockedEndingIDs: Set<String>, lastUpdated: Date = Date(), isSyncedWithRemote: Bool = false) {
        self.id = "\(userId)_\(storyTitle)"
        self.userId = userId
        self.storyTitle = storyTitle
        self.visitedSceneIDsData = (try? JSONEncoder().encode(visitedSceneIDs)) ?? Data()
        self.unlockedEndingIDsData = (try? JSONEncoder().encode(unlockedEndingIDs)) ?? Data()
        self.lastUpdated = lastUpdated
        self.isSyncedWithRemote = isSyncedWithRemote
    }
    
    func getVisitedSceneIDs() -> Set<String> {
        (try? JSONDecoder().decode(Set<String>.self, from: visitedSceneIDsData)) ?? []
    }
    
    func getUnlockedEndingIDs() -> Set<String> {
        (try? JSONDecoder().decode(Set<String>.self, from: unlockedEndingIDsData)) ?? []
    }
}
