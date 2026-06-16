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
            audioPlayer?.volume = VoiceNarratorService.shared.isSpeaking ? 0.2 : 1.0
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
    
    func setVolume(_ volume: Float) {
        audioPlayer?.volume = volume
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

// MARK: - Voice Narrator Service
class VoiceNarratorService: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    static let shared = VoiceNarratorService()
    
    private let synthesizer = AVSpeechSynthesizer()
    
    @Published var isSpeaking = false
    @Published var isPaused = false
    @Published var speechRate: Float = AVSpeechUtteranceDefaultSpeechRate // 0.5 is default
    @Published var narrationCompleted = false
    
    var onCompletion: (() -> Void)?
    
    override init() {
        super.init()
        synthesizer.delegate = self
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("VoiceNarratorService: Error al configurar la sesión de audio: \(error.localizedDescription)")
        }
    }
    
    func speak(_ text: String) {
        stop()
        narrationCompleted = false
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "es-ES") ?? AVSpeechSynthesisVoice(language: AVSpeechSynthesisVoice.currentLanguageCode())
        utterance.rate = speechRate
        
        synthesizer.speak(utterance)
        isSpeaking = true
        isPaused = false
    }
    
    func pause() {
        if synthesizer.isSpeaking && !synthesizer.isPaused {
            synthesizer.pauseSpeaking(at: .immediate)
            isPaused = true
        }
    }
    
    func resume() {
        if synthesizer.isPaused {
            synthesizer.continueSpeaking()
            isPaused = false
        }
    }
    
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
        isPaused = false
    }
    
    func skip() {
        stop()
        narrationCompleted = true
        onCompletion?()
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isSpeaking = false
            self.isPaused = false
            self.narrationCompleted = true
            self.onCompletion?()
        }
    }
}

// MARK: - Progress Manager
class ProgressManager: ObservableObject {
    static let shared = ProgressManager()
    
    @Published var progressData: [String: StoryProgress] = [:]
    
    private let storageKey = "com.proyectoFinal.storyProgress"
    
    private init() {
        loadProgress()
    }
    
    func loadProgress() {
        if let data = UserDefaults.standard.data(forKey: storageKey) {
            do {
                let decoded = try JSONDecoder().decode([String: StoryProgress].self, from: data)
                DispatchQueue.main.async {
                    self.progressData = decoded
                }
            } catch {
                print("ProgressManager: Error decodificando progreso: \(error.localizedDescription)")
            }
        }
    }
    
    func saveProgress() {
        do {
            let encoded = try JSONEncoder().encode(progressData)
            UserDefaults.standard.set(encoded, forKey: storageKey)
        } catch {
            print("ProgressManager: Error codificando progreso: \(error.localizedDescription)")
        }
    }
    
    func visitScene(storyTitle: String, sceneID: String) {
        var progress = progressData[storyTitle] ?? StoryProgress(storyTitle: storyTitle)
        progress.visitedSceneIDs.insert(sceneID)
        progressData[storyTitle] = progress
        saveProgress()
    }
    
    func unlockEnding(storyTitle: String, endingID: String) {
        var progress = progressData[storyTitle] ?? StoryProgress(storyTitle: storyTitle)
        progress.unlockedEndingIDs.insert(endingID)
        progress.visitedSceneIDs.insert(endingID)
        progressData[storyTitle] = progress
        saveProgress()
    }
    
    func getProgress(for storyTitle: String) -> StoryProgress {
        return progressData[storyTitle] ?? StoryProgress(storyTitle: storyTitle)
    }
    
    func getGlobalEndingCount() -> Int {
        return progressData.values.reduce(0) { $0 + $1.unlockedEndingIDs.count }
    }
    
    func getGlobalReadCount() -> Int {
        return progressData.values.filter { !$0.visitedSceneIDs.isEmpty }.count
    }
}

struct StoryProgress: Codable {
    let storyTitle: String
    var visitedSceneIDs: Set<String> = []
    var unlockedEndingIDs: Set<String> = []
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
    let endingTitle: String?
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
        
        for (key, js) in jsonStory.scenes {
            var choices: [Choice] = []
            if let jcList = js.choices {
                for jc in jcList {
                    let choice = Choice(
                        text: jc.text,
                        targetSceneID: jc.targetSceneKey,
                        isCritical: (jc.isBest ?? false) || (jc.isWorst ?? false),
                        timeLimit: js.timeLimit,
                        isBest: jc.isBest ?? false,
                        isWorst: jc.isWorst ?? false,
                        trust: jc.trustImpact ?? 0,
                        bravery: jc.braveryImpact ?? 0,
                        humanity: jc.humanityImpact ?? 0
                    )
                    choices.append(choice)
                }
            }
            
            let scene = GameScene(
                id: key,
                characterName: js.characterName,
                dialogue: js.dialogue,
                backgroundImage: js.backgroundImage,
                choices: choices,
                isEnding: js.isEnding ?? false,
                musicTrack: js.musicTrack,
                timeLimit: js.timeLimit,
                endingTitle: js.endingTitle
            )
            scenes.append(scene)
        }
        
        if scenes.isEmpty { return nil }
        
        return Story(
            id: jsonStory.title,
            title: jsonStory.title,
            description: jsonStory.description,
            coverImage: jsonStory.coverImage,
            initialSceneID: jsonStory.initialSceneKey,
            scenes: scenes,
            genre: jsonStory.genre,
            duration: jsonStory.duration
        )
    }
    
    static func getElUltimoFaro() -> Story {
        let inicioID = "inicio"
        let playaID = "playa"
        let bosqueID = "bosque"
        let faroID = "faro"
        
        let finalSacrificioID = "final_sacrificio"
        let finalEscapeID = "final_escape"
        let finalSoledadID = "final_soledad"
        let finalSecretoID = "final_secreto"
        let finalVerdadID = "final_verdad"
       
        // Escena 1: El Despertar
        let c1 = Choice(text: "Explorar la playa", targetSceneID: playaID, isWorst: true, trust: 0, bravery: 5, humanity: 2)
        let c2 = Choice(text: "Buscar sobrevivientes", targetSceneID: bosqueID, trust: 10, bravery: 0, humanity: 5)
        let c3 = Choice(text: "Ir hacia el faro", targetSceneID: faroID, isBest: true, trust: 0, bravery: 15, humanity: 0)
       
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
                Choice(text: "Confiar en Valeria", targetSceneID: faroID, isBest: true, trust: 15, bravery: 0, humanity: 5),
                Choice(text: "Sospechar de sus motivos", targetSceneID: bosqueID, isWorst: true, trust: -10, bravery: 5, humanity: 0)
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
                Choice(text: "Cálmalo", targetSceneID: faroID, isBest: true, trust: 10, bravery: 0, humanity: 15),
                Choice(text: "Desarmarlo", targetSceneID: faroID, isWorst: true, trust: 0, bravery: 20, humanity: 0)
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
                Choice(text: "Sacrificarse", targetSceneID: "final", isBest: true, trust: 20, bravery: 0, humanity: 30),
                Choice(text: "Usar la tecnología", targetSceneID: "final", isWorst: true, trust: -20, bravery: 20, humanity: 0)
            ],
            musicTrack: "lighthouse_ambient",
            timeLimit: 15.0
        )
       
        let finalSacrificio = GameScene(
            id: finalSacrificioID,
            dialogue: "Alex activa el faro para salvar a los demás, pero queda atrapado para siempre en sus engranajes de luz.",
            backgroundImage: "lighthouse_top",
            choices: [],
            isEnding: true,
            musicTrack: "ending_theme",
            endingTitle: "SACRIFICIO"
        )
        
        let finalEscape = GameScene(
            id: finalEscapeID,
            dialogue: "Lograste reparar el barco. El horizonte ya no es un sueño, sino tu destino.",
            backgroundImage: "boat_escape",
            choices: [],
            isEnding: true,
            musicTrack: "ending_theme",
            endingTitle: "ESCAPE"
        )
        
        let finalSoledad = GameScene(
            id: finalSoledadID,
            dialogue: "Tus aliados se han ido. El faro se apaga y la oscuridad de la isla te consume.",
            backgroundImage: "lighthouse_dark",
            choices: [],
            isEnding: true,
            musicTrack: "ending_theme",
            endingTitle: "SOLEDAD"
        )
        
        let finalSecreto = GameScene(
            id: finalSecretoID,
            dialogue: "Has descubierto la tecnología de manipulación mental. El mundo nunca volverá a ser el mismo.",
            backgroundImage: "lighthouse_interior",
            choices: [],
            isEnding: true,
            musicTrack: "ending_theme",
            endingTitle: "EL SECRETO DEL FARO"
        )
        
        let finalVerdad = GameScene(
            id: finalVerdadID,
            dialogue: "Las paredes de la realidad se desmoronan. Todo era una simulación de laboratorio.",
            backgroundImage: "laboratory",
            choices: [],
            isEnding: true,
            musicTrack: "ending_theme",
            endingTitle: "LA VERDAD"
        )

        return Story(
            id: "El Último Faro",
            title: "El Último Faro",
            description: "Una isla que devora recuerdos.",
            coverImage: "faro_cover",
            initialSceneID: inicioID,
            scenes: [inicio, playa, bosque, faro, finalSacrificio, finalEscape, finalSoledad, finalSecreto, finalVerdad],
            genre: "Misterio",
            duration: "30 min"
        )
    }
}
