import SwiftUI
import Combine
import AVFoundation

class GameViewModel: ObservableObject {
    @Published var currentStory: Story?
    @Published var currentScene: GameScene?
    
    // Nuevos Atributos (Rango 0 - 10)
    @Published var disciplina: Int = 0
    @Published var inteligenciaPractica: Int = 0
    @Published var confianza: Int = 0
    @Published var energia: Int = 5 // Inicia en 5
    
    @Published var gameCompleted: Bool = false
    @Published var activeEndingTitle: String = ""
    @Published var activeEndingDescription: String = ""
    
    // Estados intermedios para las pantallas de transición
    @Published var activeDestinationIntro: String? = nil
    @Published var pendingStatChanges: [(String, Int)] = []
    @Published var nextSceneID: String? = nil
    @Published var showingNodeIntro: Bool = false
    @Published var currentNodeIntro: String? = nil
    
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
        self.disciplina = 0
        self.inteligenciaPractica = 0
        self.confianza = 0
        self.energia = 5
        self.gameCompleted = false
        self.activeEndingTitle = ""
        self.activeEndingDescription = ""
        
        self.activeDestinationIntro = nil
        self.showingNodeIntro = false
        self.pendingStatChanges = []
        
        let initialScene = story.scenes.first(where: { $0.id == story.initialSceneID })
        if let scene = initialScene {
            transitionToScene(scene, fromStart: true)
        }
    }
    
    func canShowChoice(_ choice: Choice) -> Bool {
        if let req = choice.requisitos {
            if let d = req.disciplinaMinima, disciplina < d { return false }
            if let i = req.inteligenciaPracticaMinima, inteligenciaPractica < i { return false }
            if let c = req.confianzaMinima, confianza < c { return false }
            if let e = req.energiaMinima, energia < e { return false }
            
            if let minAvg = req.min, let maxAvg = req.max {
                let avg = Double(disciplina + confianza + inteligenciaPractica) / 3.0
                if avg < minAvg || avg > maxAvg { return false }
            }
        }
        return true
    }
    
    func makeChoice(_ choice: Choice) {
        stopTimer()
        VoiceNarratorService.shared.stop()
        AudioManager.shared.setVolume(1.0)
        
        var statChanges: [(String, Int)] = []
        
        if let cons = choice.consecuencias {
            withAnimation(.spring()) {
                if let d = cons.modificarDisciplina, d != 0 {
                    disciplina = max(0, min(10, disciplina + d))
                    statChanges.append(("Disciplina", d))
                }
                if let i = cons.modificarInteligenciaPractica, i != 0 {
                    inteligenciaPractica = max(0, min(10, inteligenciaPractica + i))
                    statChanges.append(("Inteligencia Práctica", i))
                }
                if let c = cons.modificarConfianza, c != 0 {
                    confianza = max(0, min(10, confianza + c))
                    statChanges.append(("Confianza", c))
                }
                if let e = cons.modificarEnergia, e != 0 {
                    energia = max(0, min(10, energia + e))
                    statChanges.append(("Energía", e))
                }
            }
        }
        
        self.pendingStatChanges = statChanges
        self.nextSceneID = choice.targetSceneID
        
        if let intro = choice.introduccionDestino, !intro.isEmpty {
            withAnimation {
                self.activeDestinationIntro = intro
            }
        } else {
            // Si no hay introduccion destino, saltar directo al siguiente paso
            continueFromDestinationIntro()
        }
    }
    
    func continueFromDestinationIntro() {
        withAnimation {
            self.activeDestinationIntro = nil
        }
        
        guard let nextID = nextSceneID,
              let nextScene = currentStory?.scenes.first(where: { $0.id == nextID }) else {
            return
        }
        
        transitionToScene(nextScene, fromStart: false)
    }
    
    private func transitionToScene(_ scene: GameScene, fromStart: Bool) {
        // Registrar visita a la escena en el ProgressManager
        if let story = currentStory {
            ProgressManager.shared.visitScene(storyTitle: story.title, sceneID: scene.id)
        }
        
        self.currentScene = scene
        self.showChoices = false // Ocultar opciones al iniciar la narración
        
        // Si la escena tiene introducción, mostrarla primero (a menos que estemos en un final)
        if let intro = scene.introduction, !intro.isEmpty, !scene.isEnding {
            self.currentNodeIntro = intro
            withAnimation {
                self.showingNodeIntro = true
            }
        } else {
            startSceneExecution(scene)
        }
    }
    
    func continueFromNodeIntro() {
        withAnimation {
            self.showingNodeIntro = false
            self.currentNodeIntro = nil
        }
        
        if let scene = currentScene {
            startSceneExecution(scene)
        }
    }
    
    private func startSceneExecution(_ scene: GameScene) {
        // Detener el temporizador mientras se narra
        stopTimer()
        
        // Reproducir música (temporalmente deshabilitado por tema de limpieza)
        if let music = scene.musicTrack {
            // AudioManager.shared.playMusic(named: music)
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
        
        if !scene.dialogue.isEmpty {
            narrator.speak(scene.dialogue)
        } else {
            // Si no hay diálogo, saltar directamente a opciones
            narrator.skip()
        }
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
        
        let validChoices = scene.choices.filter { canShowChoice($0) }
        
        if let worstChoice = validChoices.first(where: { $0.isWorst }) {
            makeChoice(worstChoice)
        } else if let firstChoice = validChoices.first {
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
        self.activeDestinationIntro = nil
        self.showingNodeIntro = false
        self.pendingStatChanges = []
    }
}
