import Foundation

struct Requisitos: Codable {
    let disciplinaMinima: Int?
    let inteligenciaPracticaMinima: Int?
    let confianzaMinima: Int?
    let energiaMinima: Int?
    
    // Rango para nodos finales
    let min: Double?
    let max: Double?
}

struct Consecuencias: Codable {
    let modificarDisciplina: Int?
    let modificarInteligenciaPractica: Int?
    let modificarConfianza: Int?
    let modificarEnergia: Int?
}

struct Choice: Identifiable, Codable {
    let id: String
    let text: String
    let targetSceneID: String
    let introduccionDestino: String?
    
    // Estadísticas
    let requisitos: Requisitos?
    let consecuencias: Consecuencias?
    
    // Compatibilidad con opciones anteriores si es necesario
    let isCritical: Bool
    let timeLimit: Double?
    let isBest: Bool
    let isWorst: Bool
   
    init(
        id: String = UUID().uuidString,
        text: String,
        targetSceneID: String,
        introduccionDestino: String? = nil,
        requisitos: Requisitos? = nil,
        consecuencias: Consecuencias? = nil,
        isCritical: Bool = false,
        timeLimit: Double? = nil,
        isBest: Bool = false,
        isWorst: Bool = false
    ) {
        self.id = id
        self.text = text
        self.targetSceneID = targetSceneID
        self.introduccionDestino = introduccionDestino
        self.requisitos = requisitos
        self.consecuencias = consecuencias
        self.isCritical = isCritical
        self.timeLimit = timeLimit
        self.isBest = isBest
        self.isWorst = isWorst
    }
}
