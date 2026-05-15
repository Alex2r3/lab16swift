import Foundation


struct Choice: Identifiable, Codable {
    let id: UUID
    let text: String
    let targetSceneID: UUID
    let isCritical: Bool
    let timeLimit: Double?
   
    // Estadísticas
    let trustImpact: Int
    let braveryImpact: Int
    let humanityImpact: Int
   
    // Inicializador corregido para ser más flexible
    init(
        text: String,
        targetSceneID: UUID,
        isCritical: Bool = false,
        timeLimit: Double? = nil,
        trust: Int = 0,
        bravery: Int = 0,
        humanity: Int = 0
    ) {
        self.id = UUID()
        self.text = text
        self.targetSceneID = targetSceneID
        self.isCritical = isCritical
        self.timeLimit = timeLimit
        self.trustImpact = trust
        self.braveryImpact = bravery
        self.humanityImpact = humanity
    }
}


