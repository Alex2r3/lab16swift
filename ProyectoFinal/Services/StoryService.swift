import Foundation
import AVFoundation
import UIKit
import FirebaseFirestore
import FirebaseAuth
import SwiftData

// MARK: - Audio Manager
class AudioManager: NSObject, ObservableObject {
    static let shared = AudioManager()
    private var audioPlayer: AVAudioPlayer?
    private var currentTrack: String?
    
    func playMusic(named name: String) {
        // Normalizar el nombre quitando la extensión si viene incluida (ej: "track.mp3" -> "track")
        let cleanName = (name as NSString).deletingPathExtension
        
        guard currentTrack != cleanName else { return }
        
        stopMusic()
        
        let extensions = ["mp3", "wav", "m4a", "MP3", "WAV", "M4A"]
        var fileURL: URL? = nil
        
        // Buscar en bundle y subdirectorios de Media
        for ext in extensions {
            if let path = Bundle.main.path(forResource: cleanName, ofType: ext) {
                fileURL = URL(fileURLWithPath: path)
                break
            }
            if let path = Bundle.main.path(forResource: cleanName, ofType: ext, inDirectory: "Media") {
                fileURL = URL(fileURLWithPath: path)
                break
            }
            if let path = Bundle.main.path(forResource: cleanName, ofType: ext, inDirectory: "Media/Music") {
                fileURL = URL(fileURLWithPath: path)
                break
            }
        }
        
        guard let url = fileURL else {
            print("AudioManager: No se encontró el archivo '\(cleanName)'")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1 // Bucle infinito
            // Volumen general más bajo para que no sature.
            audioPlayer?.volume = VoiceNarratorService.shared.isSpeaking ? 0.02 : 0.35
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            currentTrack = cleanName
            print("AudioManager: Reproduciendo '\(cleanName)'")
        } catch {
            print("AudioManager: Error reproduciendo '\(cleanName)': \(error.localizedDescription)")
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
        
        // El llamado a speechVoices() precarga la metadata y evita el error "Data corrupted" común en iOS.
        let voices = AVSpeechSynthesisVoice.speechVoices()
        
        // Buscamos una voz de alta calidad (Premium o Enhanced) en español
        if let premiumVoice = voices.first(where: { $0.language.starts(with: "es") && $0.quality == .premium }) {
            utterance.voice = premiumVoice
        } else if let enhancedVoice = voices.first(where: { $0.language.starts(with: "es") && $0.quality == .enhanced }) {
            utterance.voice = enhancedVoice
        } else {
            // Fallback a voz por defecto si no hay de alta calidad
            utterance.voice = AVSpeechSynthesisVoice(language: "es-ES") ?? AVSpeechSynthesisVoice(language: AVSpeechSynthesisVoice.currentLanguageCode())
        }
        
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
@MainActor
class ProgressManager: ObservableObject {
    static let shared = ProgressManager()
    
    @Published var progressData: [String: StoryProgress] = [:]
    var modelContext: ModelContext?
    
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
        
        // 1. Cargar desde SwiftData primero (rápido, offline)
        if let context = modelContext {
            let descriptor = FetchDescriptor<OfflineProgress>(predicate: #Predicate { $0.userId == userId })
            if let cachedProgress = try? context.fetch(descriptor) {
                var localProgress: [String: StoryProgress] = [:]
                for cp in cachedProgress {
                    localProgress[cp.storyTitle] = StoryProgress(
                        storyTitle: cp.storyTitle,
                        visitedSceneIDs: cp.getVisitedSceneIDs(),
                        unlockedEndingIDs: cp.getUnlockedEndingIDs()
                    )
                }
                DispatchQueue.main.async {
                    self.progressData = localProgress
                }
            }
        }
        
        // 2. Si hay internet, cargar de Firestore y hacer merge
        if NetworkMonitor.shared.isConnected {
            db.collection("users").document(userId).getDocument { [weak self] snapshot, error in
                guard let self = self, let snapshot = snapshot, snapshot.exists else { return }
                do {
                    if let jsonString = snapshot.data()?["progressData"] as? String,
                       let data = jsonString.data(using: .utf8) {
                        let remoteData = try JSONDecoder().decode([String: StoryProgress].self, from: data)
                        
                        // Merge local y remoto
                        DispatchQueue.main.async {
                            for (key, remoteProgress) in remoteData {
                                if var local = self.progressData[key] {
                                    local.visitedSceneIDs.formUnion(remoteProgress.visitedSceneIDs)
                                    local.unlockedEndingIDs.formUnion(remoteProgress.unlockedEndingIDs)
                                    self.progressData[key] = local
                                } else {
                                    self.progressData[key] = remoteProgress
                                }
                            }
                            // Guardar el merge localmente y remotamente
                            self.saveProgress()
                        }
                    }
                } catch {
                    print("ProgressManager: Error decodificando progreso de Firestore: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func saveProgress() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // 1. Guardar en SwiftData (Offline)
        if let context = modelContext {
            for (title, prog) in progressData {
                let id = "\(userId)_\(title)"
                let descriptor = FetchDescriptor<OfflineProgress>(predicate: #Predicate { $0.id == id })
                if let existing = try? context.fetch(descriptor).first {
                    existing.visitedSceneIDsData = (try? JSONEncoder().encode(prog.visitedSceneIDs)) ?? Data()
                    existing.unlockedEndingIDsData = (try? JSONEncoder().encode(prog.unlockedEndingIDs)) ?? Data()
                    existing.lastUpdated = Date()
                    existing.isSyncedWithRemote = NetworkMonitor.shared.isConnected
                } else {
                    let newProgress = OfflineProgress(
                        userId: userId,
                        storyTitle: title,
                        visitedSceneIDs: prog.visitedSceneIDs,
                        unlockedEndingIDs: prog.unlockedEndingIDs,
                        isSyncedWithRemote: NetworkMonitor.shared.isConnected
                    )
                    context.insert(newProgress)
                }
            }
            try? context.save()
        }
        
        // 2. Guardar en Firestore si hay internet
        if NetworkMonitor.shared.isConnected {
            do {
                let encoded = try JSONEncoder().encode(progressData)
                if let jsonString = String(data: encoded, encoding: .utf8) {
                    db.collection("users").document(userId).setData(["progressData": jsonString], merge: true) { error in
                        if let error = error {
                            print("ProgressManager: Error guardando progreso en Firestore: \(error.localizedDescription)")
                        } else {
                            // Actualizar flag de sync local
                            if let context = self.modelContext {
                                let descriptor = FetchDescriptor<OfflineProgress>(predicate: #Predicate { $0.userId == userId })
                                if let items = try? context.fetch(descriptor) {
                                    for item in items { item.isSyncedWithRemote = true }
                                    try? context.save()
                                }
                            }
                        }
                    }
                }
            } catch {
                print("ProgressManager: Error codificando progreso: \(error.localizedDescription)")
            }
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
    let musica: String?
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
    
    @MainActor
    static func loadAllStories(modelContext: ModelContext? = nil) async throws -> [Story] {
        var stories: [Story] = []
        let storyId = "historias_tecsup"
        
        // 1. Si hay internet, intentamos descargar de la API y actualizar caché
        if NetworkMonitor.shared.isConnected {
            guard let url = URL(string: apiBaseURL) else {
                throw URLError(.badURL)
            }
            
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let nodes = try decoder.decode([JSONNode].self, from: data)
                
                if let story = mapNodesToStory(nodes) {
                    stories.append(story)
                    
                    // Actualizar/Sobrescribir el caché local en SwiftData
                    if let context = modelContext {
                        let descriptor = FetchDescriptor<OfflineStory>(predicate: #Predicate { $0.id == storyId })
                        if let existing = try? context.fetch(descriptor).first {
                            existing.jsonData = data
                        } else {
                            let newOfflineStory = OfflineStory(id: storyId, jsonData: data)
                            context.insert(newOfflineStory)
                        }
                        try? context.save()
                    }
                    return stories
                }
            } catch {
                print("Error obteniendo del API, intentando cargar de caché local fallback: \(error.localizedDescription)")
                // Si falla el API por cualquier cosa pero tenemos local, continuamos e intentamos cargar el local
            }
        }
        
        // 2. Si no hay internet o falló la llamada al API, intentamos usar el caché local
        if let context = modelContext {
            let descriptor = FetchDescriptor<OfflineStory>(predicate: #Predicate { $0.id == storyId })
            if let cached = try? context.fetch(descriptor).first {
                do {
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    let nodes = try decoder.decode([JSONNode].self, from: cached.jsonData)
                    if let story = mapNodesToStory(nodes) {
                        stories.append(story)
                        print("Cargado con éxito desde el caché local de SwiftData")
                        return stories
                    }
                } catch {
                    print("Error decodificando caché local de historias: \(error.localizedDescription)")
                }
            }
        }
        
        // 3. Si no hay internet y tampoco tenemos caché guardado
        if !NetworkMonitor.shared.isConnected {
            throw URLError(.notConnectedToInternet)
        } else {
            throw URLError(.badServerResponse)
        }
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
                musicTrack: node.musica,
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
