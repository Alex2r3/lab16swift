import Foundation
import AVFoundation
import UIKit
import FirebaseFirestore
import FirebaseAuth

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
    
    private let db = Firestore.firestore()
    
    private init() {
        // Escuchar cambios de autenticación para cargar o limpiar el progreso
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if user != nil {
                self?.loadProgress()
            } else {
                DispatchQueue.main.async {
                    self?.progressData = [:]
                }
            }
        }
    }
    
    func loadProgress() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
            guard let self = self, let snapshot = snapshot, snapshot.exists else { return }
            do {
                if let jsonString = snapshot.data()?["progressData"] as? String,
                   let data = jsonString.data(using: .utf8) {
                    let decoded = try JSONDecoder().decode([String: StoryProgress].self, from: data)
                    DispatchQueue.main.async {
                        self.progressData = decoded
                    }
                }
            } catch {
                print("ProgressManager: Error decodificando progreso de Firestore: \(error.localizedDescription)")
            }
        }
    }
    
    func saveProgress() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            let encoded = try JSONEncoder().encode(progressData)
            if let jsonString = String(data: encoded, encoding: .utf8) {
                db.collection("users").document(userId).setData(["progressData": jsonString], merge: true) { error in
                    if let error = error {
                        print("ProgressManager: Error guardando progreso en Firestore: \(error.localizedDescription)")
                    }
                }
            }
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
struct JSONNode: Decodable {
    let id: String
    let titulo: String?
    let introduccion: String?
    let narracion: String?
    let imagen: String?
    let esFinal: Bool?          // JSON: "es_final" → convertFromSnakeCase → esFinal
    let decisiones: [JSONDecision]?
    let endingTitle: String?
}

struct JSONDecision: Decodable {
    let texto: String
    let nodoDestinoId: String           // JSON: "nodo_destino_id"
    let introduccionDestino: String?    // JSON: "introduccion_destino"
    let requisitos: Requisitos?
    let consecuencias: Consecuencias?
}

// MARK: - Story Service
class StoryService {
    // URL del endpoint base. Cambiar cuando se suba a producción.
    static let apiBaseURL = "https://servicio-historias-api.onrender.com/api/v1/historias"
    
    static func loadAllStories() async throws -> [Story] {
        var stories: [Story] = []
        
        guard let url = URL(string: apiBaseURL) else {
            throw URLError(.badURL)
        }
        
        // Petición asíncrona a la API usando concurrencia moderna
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, 
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let nodes = try decoder.decode([JSONNode].self, from: data)
            
            if let story = mapNodesToStory(nodes) {
                stories.append(story)
            }
        } catch {
            print("Error decodificando el JSON de la API: \(error.localizedDescription)")
            throw error
        }
        
        return stories
    }
    
    private static func mapNodesToStory(_ nodes: [JSONNode]) -> Story? {
        var scenes: [GameScene] = []
        
        for node in nodes {
            var choices: [Choice] = []
            if let decisiones = node.decisiones {
                for dec in decisiones {
                    let choice = Choice(
                        text: dec.texto,
                        targetSceneID: dec.nodoDestinoId,
                        introduccionDestino: dec.introduccionDestino,
                        requisitos: dec.requisitos,
                        consecuencias: dec.consecuencias
                    )
                    choices.append(choice)
                }
            }
            
            let scene = GameScene(
                id: node.id,
                title: node.titulo,
                introduction: node.introduccion,
                characterName: nil, // Ya no se usa
                dialogue: node.narracion ?? "",
                backgroundImage: node.imagen ?? "default_bg",
                choices: choices,
                isEnding: node.esFinal ?? false,
                endingTitle: node.titulo
            )
            scenes.append(scene)
        }
        
        if scenes.isEmpty { return nil }
        
        return Story(
            id: "historias_tecsup",
            title: "Supervivencia Académica",
            description: "Logra superar el ciclo final mejorando tus notas y habilidades técnicas.",
            coverImage: "escena_1_aula",
            initialSceneID: scenes.first?.id ?? "1_1",
            scenes: scenes,
            genre: "Educativo/Drama",
            duration: "20 min"
        )
    }
    
}
