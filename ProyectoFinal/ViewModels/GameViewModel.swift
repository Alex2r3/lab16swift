import SwiftUI
import Combine

class GameViewModel: ObservableObject {
    @Published var currentStory: Story?
    @Published var currentScene: GameScene?
    
    @Published var trust: Int = 50
    @Published var bravery: Int = 50
    @Published var humanity: Int = 50
    
    @Published var gameCompleted: Bool = false
    @Published var activeEndingTitle: String = ""
    @Published var activeEndingDescription: String = ""
    
    @Published var timerValue: Double = 0
    @Published var maxTimerValue: Double = 1.0
    @Published var isTimerActive: Bool = false
    
    // Narrador por voz
    @Published var showChoices: Bool = false
    @Published var speechRate: Float = AVSpeechUtteranceDefaultSpeechRate {
        didSet {
            VoiceNarratorService.shared.speechRate = speechRate
        }
    }
    
    private var timerCancellable: AnyCancellable?
    private var narratorCancellables = Set<AnyCancellable>()

    init() {
        // Sincronizar velocidad del narrador
        VoiceNarratorService.shared.$speechRate
            .sink { [weak self] rate in
                guard let self = self else { return }
                if self.speechRate != rate {
                    self.speechRate = rate
                }
            }
            .store(in: &narratorCancellables)
    }

    func startStory(_ story: Story) {
        self.currentStory = story
        self.trust = 50
        self.bravery = 50
        self.humanity = 50
        self.gameCompleted = false
        self.activeEndingTitle = ""
        self.activeEndingDescription = ""
        
        let initialScene = story.scenes.first(where: { $0.id == story.initialSceneID })
        if let scene = initialScene {
            transitionToScene(scene)
        }
    }
    
    func makeChoice(_ choice: Choice) {
        stopTimer()
        VoiceNarratorService.shared.stop()
        AudioManager.shared.setVolume(1.0)
        
        withAnimation(.spring()) {
            trust = max(0, min(100, trust + choice.trustImpact))
            bravery = max(0, min(100, bravery + choice.braveryImpact))
            humanity = max(0, min(100, humanity + choice.humanityImpact))
        }
        
        var targetSceneID = choice.targetSceneID
        
        // Interceptar la escena de final del Último Faro para redirigir dinámicamente según estadísticas
        if targetSceneID == "final" {
            if humanity >= 80 && trust >= 70 {
                targetSceneID = "final_sacrificio"
            } else if bravery >= 80 && humanity >= 60 {
                targetSceneID = "final_escape"
            } else if trust <= 30 && humanity <= 40 {
                targetSceneID = "final_soledad"
            } else if bravery >= 70 && trust >= 40 {
                targetSceneID = "final_secreto"
            } else {
                targetSceneID = "final_verdad"
            }
        }
        
        if let nextScene = currentStory?.scenes.first(where: { $0.id == targetSceneID }) {
            transitionToScene(nextScene)
        }
    }
    
    private func transitionToScene(_ scene: GameScene) {
        // Registrar visita a la escena en el ProgressManager
        if let story = currentStory {
            ProgressManager.shared.visitScene(storyTitle: story.title, sceneID: scene.id)
        }
        
        withAnimation(.easeInOut(duration: 0.8)) {
            self.currentScene = scene
            self.showChoices = false // Ocultar opciones al iniciar la narración
        }
        
        // Detener el temporizador mientras se narra
        stopTimer()
        
        // Reproducir música
        if let music = scene.musicTrack {
            AudioManager.shared.playMusic(named: music)
        } else {
            AudioManager.shared.stopMusic()
        }
        
        // Configurar y reproducir el narrador por voz
        let narrator = VoiceNarratorService.shared
        AudioManager.shared.setVolume(0.2) // Atenuar música de fondo
        
        narrator.onCompletion = { [weak self] in
            guard let self = self else { return }
            
            // Restaurar volumen y mostrar opciones
            AudioManager.shared.setVolume(1.0)
            
            withAnimation(.spring()) {
                self.showChoices = true
            }
            
            // Si la escena es un final, registrarlo y finalizar la sesión
            if scene.isEnding {
                self.determineEnding(for: scene)
            } else if !scene.choices.isEmpty {
                // Iniciar temporizador solo después de terminar la narración
                let time = scene.timeLimit ?? 15.0
                self.startTimer(seconds: time, maxSeconds: time)
            }
        }
        
        narrator.speak(scene.dialogue)
    }
    
    private func determineEnding(for scene: GameScene) {
        self.gameCompleted = true
        self.activeEndingTitle = scene.displayNameForEnding
        self.activeEndingDescription = scene.dialogue
        
        // Registrar final descubierto
        if let story = currentStory {
            ProgressManager.shared.unlockEnding(storyTitle: story.title, endingID: scene.id)
        }
    }
    
    func startTimer(seconds: Double, maxSeconds: Double) {
        stopTimer()
        self.maxTimerValue = maxSeconds > 0 ? maxSeconds : 15.0
        self.timerValue = seconds
        self.isTimerActive = true
        
        timerCancellable = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.timerValue > 0 {
                    self.timerValue -= 0.1
                } else {
                    self.handleTimeOut()
                }
            }
    }
    
    func stopTimer() {
        isTimerActive = false
        timerCancellable?.cancel()
    }
    
    private func handleTimeOut() {
        stopTimer()
        guard let scene = currentScene, !scene.choices.isEmpty else { return }
        
        if let worstChoice = scene.choices.first(where: { $0.isWorst }) {
            makeChoice(worstChoice)
        } else if let firstChoice = scene.choices.first {
            makeChoice(firstChoice)
        }
    }
    
    func resetGame() {
        stopTimer()
        VoiceNarratorService.shared.stop()
        AudioManager.shared.stopMusic()
        AudioManager.shared.setVolume(1.0)
        self.currentStory = nil
        self.currentScene = nil
        self.gameCompleted = false
        self.activeEndingTitle = ""
        self.activeEndingDescription = ""
        self.showChoices = false
    }
}
