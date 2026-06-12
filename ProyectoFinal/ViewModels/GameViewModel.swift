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
    
    private var timerCancellable: AnyCancellable?

    func startStory(_ story: Story) {
        self.currentStory = story
        let initialScene = story.scenes.first(where: { $0.id == story.initialSceneID })
        self.currentScene = initialScene
        self.trust = 50
        self.bravery = 50
        self.humanity = 50
        self.gameCompleted = false
        
        if let scene = initialScene {
            if let music = scene.musicTrack {
                AudioManager.shared.playMusic(named: music)
            } else {
                AudioManager.shared.stopMusic()
            }
            
            if !scene.choices.isEmpty {
                let time = scene.timeLimit ?? 15.0
                startTimer(seconds: time, maxSeconds: time)
            } else {
                stopTimer()
            }
        }
    }
    
    func makeChoice(_ choice: Choice) {
        stopTimer()
        
        withAnimation(.spring()) {
            trust = max(0, min(100, trust + choice.trustImpact))
            bravery = max(0, min(100, bravery + choice.braveryImpact))
            humanity = max(0, min(100, humanity + choice.humanityImpact))
        }
        
        if let nextScene = currentStory?.scenes.first(where: { $0.id == choice.targetSceneID }) {
            transitionToScene(nextScene)
        }
    }
    
    private func transitionToScene(_ scene: GameScene) {
        withAnimation(.easeInOut(duration: 0.8)) {
            self.currentScene = scene
        }
        
        if let music = scene.musicTrack {
            AudioManager.shared.playMusic(named: music)
        }
        
        if scene.isEnding {
            determineEnding()
            stopTimer()
        } else if !scene.choices.isEmpty {
            let time = scene.timeLimit ?? 15.0
            startTimer(seconds: time, maxSeconds: time)
        } else {
            stopTimer()
        }
    }
    
    private func determineEnding() {
        self.gameCompleted = true
        
        if humanity >= 80 && trust >= 70 {
            activeEndingTitle = "SACRIFICIO"
            activeEndingDescription = "Alex activa el faro para salvar a los demás, pero queda atrapado para siempre en sus engranajes de luz."
        } else if bravery >= 80 && humanity >= 60 {
            activeEndingTitle = "ESCAPE"
            activeEndingDescription = "Lograste reparar el barco. El horizonte ya no es un sueño, sino tu destino."
        } else if trust <= 30 && humanity <= 40 {
            activeEndingTitle = "SOLEDAD"
            activeEndingDescription = "Tus aliados se han ido. El faro se apaga y la oscuridad de la isla te consume."
        } else if bravery >= 70 && trust >= 40 {
            activeEndingTitle = "EL SECRETO DEL FARO"
            activeEndingDescription = "Has descubierto la tecnología de manipulación mental. El mundo nunca volverá a ser el mismo."
        } else {
            activeEndingTitle = "LA VERDAD"
            activeEndingDescription = "Las paredes de la realidad se desmoronan. Todo era una simulación de laboratorio."
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
        AudioManager.shared.stopMusic()
        self.currentStory = nil
        self.currentScene = nil
        self.gameCompleted = false
    }
}
