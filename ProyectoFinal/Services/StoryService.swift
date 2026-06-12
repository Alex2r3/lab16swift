import Foundation
import AVFoundation
import UIKit

// MARK: - Audio Manager
class AudioManager: NSObject, ObservableObject {
    static let shared = AudioManager()
    private var audioPlayer: AVAudioPlayer?
    private var currentTrack: String?
    
    func playMusic(named name: String) {
        guard currentTrack != name else { return }
        
        stopMusic()
        
        let extensions = ["mp3", "wav", "m4a", "MP3", "WAV", "M4A"]
        var fileURL: URL? = nil
        
        // Buscar en bundle y subdirectorios de Media
        for ext in extensions {
            if let path = Bundle.main.path(forResource: name, ofType: ext) {
                fileURL = URL(fileURLWithPath: path)
                break
            }
            if let path = Bundle.main.path(forResource: name, ofType: ext, inDirectory: "Media") {
                fileURL = URL(fileURLWithPath: path)
                break
            }
            if let path = Bundle.main.path(forResource: name, ofType: ext, inDirectory: "Media/Music") {
                fileURL = URL(fileURLWithPath: path)
                break
            }
        }
        
        guard let url = fileURL else {
            print("AudioManager: No se encontró el archivo '\(name)'")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1 // Bucle infinito
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            currentTrack = name
            print("AudioManager: Reproduciendo '\(name)'")
        } catch {
            print("AudioManager: Error reproduciendo '\(name)': \(error.localizedDescription)")
        }
    }
    
    func stopMusic() {
        audioPlayer?.stop()
        audioPlayer = nil
        currentTrack = nil
    }
}

// MARK: - Media Image Loader
struct MediaImageLoader {
    static func loadImage(named name: String) -> UIImage? {
        if let img = UIImage(named: name) {
            return img
        }
        
        let extensions = ["png", "jpg", "jpeg", "webp", "PNG", "JPG", "JPEG"]
        for ext in extensions {
            if let path = Bundle.main.path(forResource: name, ofType: ext) {
                if let image = UIImage(contentsOfFile: path) {
                    return image
                }
            }
            if let path = Bundle.main.path(forResource: name, ofType: ext, inDirectory: "Media") {
                if let image = UIImage(contentsOfFile: path) {
                    return image
                }
            }
            if let path = Bundle.main.path(forResource: name, ofType: ext, inDirectory: "Media/Images") {
                if let image = UIImage(contentsOfFile: path) {
                    return image
                }
            }
        }
        return nil
    }
}

// MARK: - JSON Decodable Helpers
struct JSONStory: Decodable {
    let title: String
    let description: String
    let coverImage: String
    let genre: String
    let duration: String
    let initialSceneKey: String
    let scenes: [String: JSONScene]
}

struct JSONScene: Decodable {
    let characterName: String?
    let dialogue: String
    let backgroundImage: String
    let musicTrack: String?
    let timeLimit: Double?
    let isEnding: Bool?
    let choices: [JSONChoice]?
}

struct JSONChoice: Decodable {
    let text: String
    let targetSceneKey: String
    let isBest: Bool?
    let isWorst: Bool?
    let trustImpact: Int?
    let braveryImpact: Int?
    let humanityImpact: Int?
}

// MARK: - Story Service
class StoryService {
    static func loadAllStories() -> [Story] {
        var stories: [Story] = []
        
        // 1. Cargar archivos JSON del bundle
        let paths = Bundle.main.paths(forResourcesOfType: "json", inDirectory: nil)
        for path in paths {
            if let story = parseStory(fromFile: path) {
                stories.append(story)
            }
        }
        
        let mediaPaths = Bundle.main.paths(forResourcesOfType: "json", inDirectory: "Media")
        for path in mediaPaths {
            if let story = parseStory(fromFile: path) {
                stories.append(story)
            }
        }
        
        // Evitar duplicados por título
        var uniqueStories: [Story] = []
        for story in stories {
            if !uniqueStories.contains(where: { $0.title == story.title }) {
                uniqueStories.append(story)
            }
        }
        
        // Fallback si no hay JSONs
        if uniqueStories.isEmpty {
            uniqueStories.append(getElUltimoFaro())
        }
        
        return uniqueStories
    }
    
    static func parseStory(fromFile path: String) -> Story? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            return nil
        }
        do {
            let jsonStory = try JSONDecoder().decode(JSONStory.self, from: data)
            return mapJSONStoryToStory(jsonStory)
        } catch {
            print("Error parseando historia en \(path): \(error)")
            return nil
        }
    }
    
    private static func mapJSONStoryToStory(_ jsonStory: JSONStory) -> Story? {
        var scenes: [GameScene] = []
        var sceneKeyToUUID: [String: UUID] = [:]
        
        // Asignar UUIDs a cada escena por clave
        for key in jsonStory.scenes.keys {
            sceneKeyToUUID[key] = UUID()
        }
        
        guard let initialUUID = sceneKeyToUUID[jsonStory.initialSceneKey] else {
            print("Error: No se encontró la escena inicial '\(jsonStory.initialSceneKey)'")
            return nil
        }
        
        for (key, js) in jsonStory.scenes {
            guard let uuid = sceneKeyToUUID[key] else { continue }
            
            var choices: [Choice] = []
            if let jcList = js.choices {
                for jc in jcList {
                    if let targetUUID = sceneKeyToUUID[jc.targetSceneKey] {
                        let choice = Choice(
                            text: jc.text,
                            targetSceneID: targetUUID,
                            isCritical: (jc.isBest ?? false) || (jc.isWorst ?? false),
                            timeLimit: js.timeLimit,
                            isBest: jc.isBest ?? false,
                            isWorst: jc.isWorst ?? false,
                            trust: jc.trustImpact ?? 0,
                            bravery: jc.braveryImpact ?? 0,
                            humanity: jc.humanityImpact ?? 0
                        )
                        choices.append(choice)
                    } else {
                        print("Advertencia: Escena destino '\(jc.targetSceneKey)' no encontrada en '\(jc.text)'")
                    }
                }
            }
            
            let scene = GameScene(
                id: uuid,
                characterName: js.characterName,
                dialogue: js.dialogue,
                backgroundImage: js.backgroundImage,
                choices: choices,
                isEnding: js.isEnding ?? false,
                musicTrack: js.musicTrack,
                timeLimit: js.timeLimit
            )
            scenes.append(scene)
        }
        
        if scenes.isEmpty { return nil }
        
        return Story(
            id: UUID(),
            title: jsonStory.title,
            description: jsonStory.description,
            coverImage: jsonStory.coverImage,
            initialSceneID: initialUUID,
            scenes: scenes,
            genre: jsonStory.genre,
            duration: jsonStory.duration
        )
    }
    
    static func getElUltimoFaro() -> Story {
        let inicioID = UUID()
        let playaID = UUID()
        let bosqueID = UUID()
        let faroID = UUID()
        let finalID = UUID()
       
        // Escena 1: El Despertar
        let c1 = Choice(text: "Explorar la playa", targetSceneID: playaID, isWorst: true, bravery: 5, humanity: 2)
        let c2 = Choice(text: "Buscar sobrevivientes", targetSceneID: bosqueID, trust: 10, humanity: 5)
        let c3 = Choice(text: "Ir hacia el faro", targetSceneID: faroID, isBest: true, bravery: 15)
       
        let inicio = GameScene(
            id: inicioID,
            characterName: "Alex",
            dialogue: "Despierto con el sabor de la sal en mi boca. La tormenta ha pasado, pero el silencio es peor. A lo lejos, un faro emite una luz roja intermitente. ¿Qué debo hacer?",
            backgroundImage: "beach_start",
            choices: [c1, c2, c3],
            musicTrack: "mar_suspenso",
            timeLimit: 12.0
        )
       
        // Escena 2: La Playa
        let playa = GameScene(
            id: playaID,
            characterName: "Valeria",
            dialogue: "Veo a una mujer junto a unos restos de madera. Se presenta como Valeria. Dice que el faro no es lo que parece.",
            backgroundImage: "beach_mist",
            choices: [
                Choice(text: "Confiar en Valeria", targetSceneID: faroID, isBest: true, trust: 15, humanity: 5),
                Choice(text: "Sospechar de sus motivos", targetSceneID: bosqueID, isWorst: true, trust: -10, bravery: 5)
            ],
            musicTrack: "tension_playa",
            timeLimit: 10.0
        )
       
        // Escena 3: El Bosque
        let bosque = GameScene(
            id: bosqueID,
            characterName: "Noah",
            dialogue: "¡No te acerques! Noah me apunta con un trozo de metal afilado. Cree que somos parte de un experimento.",
            backgroundImage: "dark_forest",
            choices: [
                Choice(text: "Cálmalo", targetSceneID: faroID, isBest: true, trust: 10, humanity: 15),
                Choice(text: "Desarmarlo", targetSceneID: faroID, isWorst: true, bravery: 20)
            ],
            musicTrack: "suspenso_bosque",
            timeLimit: 10.0
        )
       
        // Escena 4: El Faro
        let faro = GameScene(
            id: faroID,
            characterName: "Elias",
            dialogue: "Elias está frente a una consola de bronce antigua. 'Alex, llegas justo a tiempo. Puedo apagarlo o usarlo para reescribir lo que pasó.'",
            backgroundImage: "lighthouse_interior",
            choices: [
                Choice(text: "Sacrificarse", targetSceneID: finalID, isBest: true, trust: 20, humanity: 30),
                Choice(text: "Usar la tecnología", targetSceneID: finalID, isWorst: true, trust: -20, bravery: 20)
            ],
            musicTrack: "lighthouse_ambient",
            timeLimit: 15.0
        )
       
        let finalScene = GameScene(
            id: finalID,
            dialogue: "El destino está sellado.",
            backgroundImage: "lighthouse_top",
            isEnding: true,
            musicTrack: "ending_theme"
        )

        return Story(
            id: UUID(),
            title: "El Último Faro",
            description: "Una isla que devora recuerdos.",
            coverImage: "faro_cover",
            initialSceneID: inicioID,
            scenes: [inicio, playa, bosque, faro, finalScene],
            genre: "Misterio",
            duration: "30 min"
        )
    }
}
