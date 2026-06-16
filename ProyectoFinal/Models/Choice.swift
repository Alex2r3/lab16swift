import Foundation


struct Choice: Identifiable, Codable {
    let id: String
    let text: String
    let targetSceneID: String
    let isCritical: Bool
    let timeLimit: Double?
    let isBest: Bool
    let isWorst: Bool
   
    // Estadísticas
    let trustImpact: Int
    let braveryImpact: Int
    let humanityImpact: Int
   
    // Inicializador corregido para ser más flexible
    init(
        text: String,
        targetSceneID: String,
        isCritical: Bool = false,
        timeLimit: Double? = nil,
        isBest: Bool = false,
        isWorst: Bool = false,
        trust: Int = 0,
        bravery: Int = 0,
        humanity: Int = 0
    ) {
        self.id = UUID().uuidString
        self.text = text
        self.targetSceneID = targetSceneID
        self.isCritical = isCritical
        self.timeLimit = timeLimit
        self.isBest = isBest
        self.isWorst = isWorst
        self.trustImpact = trust
        self.braveryImpact = bravery
        self.humanityImpact = humanity
    }
}


