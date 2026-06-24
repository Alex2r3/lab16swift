import SwiftUI

struct NarrativeView: View {
    @ObservedObject var viewModel: GameViewModel
    @ObservedObject var narrator = VoiceNarratorService.shared
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Theme.black.ignoresSafeArea()
            
            if let destIntro = viewModel.activeDestinationIntro {
                // Pantalla Intermedia 1: Introducción Destino
                DestinationIntroView(
                    text: destIntro,
                    statChanges: viewModel.pendingStatChanges,
                    onContinue: {
                        viewModel.continueFromDestinationIntro()
                    }
                )
                .transition(.opacity)
                .zIndex(3)
            } else if viewModel.showingNodeIntro, let nodeIntro = viewModel.currentNodeIntro {
                // Pantalla Intermedia 2: Introducción de nuevo nodo
                NodeIntroView(
                    text: nodeIntro,
                    onContinue: {
                        viewModel.continueFromNodeIntro()
                    }
                )
                .transition(.opacity)
                .zIndex(2)
            } else {
                // Escena Principal
                mainSceneView
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // Ocultar tab bar para experiencia inmersiva de juego
            setTabBarHidden(true)
        }
        .onDisappear {
            // Restaurar tab bar al salir de la vista
            setTabBarHidden(false)
            viewModel.resetGame()
            VoiceNarratorService.shared.stop()
        }
    }
    
    /// Oculta o muestra el UITabBar del TabView padre
    private func setTabBarHidden(_ hidden: Bool) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first(where: { $0.isKeyWindow }),
              let tabBar = window.rootViewController as? UITabBarController
        else { return }
        UIView.animate(withDuration: 0.2) {
            tabBar.tabBar.isHidden = hidden
            tabBar.tabBar.alpha = hidden ? 0 : 1
        }
    }
    
    // MARK: - Main Scene View
    var mainSceneView: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // ── HUD Estadísticas (siempre visible, fondo sólido) ──
                HStack(spacing: 8) {
                    StatBar(label: "DISCIPLINA",   value: viewModel.disciplina,           color: .blue)
                    StatBar(label: "I.PRÁCTICA",   value: viewModel.inteligenciaPractica, color: .purple)
                    StatBar(label: "CONFIANZA",    value: viewModel.confianza,            color: Theme.accentRed)
                    StatBar(label: "ENERGÍA",      value: viewModel.energia,              color: Theme.accentYellow)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.92))
                
                
                
                
                // ── Zona de imagen + contenido superpuesto ──
                // GeometryReader da un frame fijo explícito a la imagen.
                // La imagen se clipea a sí misma; el contenido de texto NO se clipea
                // (usa .overlay en el contenedor exterior).
                GeometryReader { geo in
                    // Imagen de fondo: frame explícito = resto de pantalla tras el HUD
                    Group {
                        if let scene = viewModel.currentScene {
                            if let uiImage = MediaImageLoader.loadImage(named: scene.backgroundImage) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .mask(
                                                LinearGradient(
                                                    colors: [.black, .black, .black.opacity(0.5), .clear],
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                )
                                            )
                                    .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
                                    
                                    .clipped()          // Solo la imagen se clipea
                            } else {
                                Theme.mainGradient
                                    .frame(width: geo.size.width, height: geo.size.height)
                                    .overlay(
                                        VStack(spacing: 16) {
                                            Image(systemName: "photo.on.rectangle.angled")
                                                .font(.system(size: 64))
                                                .foregroundColor(.white.opacity(0.1))
                                            Text(scene.backgroundImage)
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.2))
                                                .tracking(2)
                                        }
                                    )
                            }
                        } else {
                            Color.black.frame(width: geo.size.width, height: geo.size.height)
                        }
                    }
                    // Degradado oscuro sobre la imagen (solo cubre el área de la imagen)
                    .overlay(
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.25), .black.opacity(0.82)],
                            startPoint: .top, endPoint: .bottom
                        )
                        .allowsHitTesting(false)
                    )
                    // Viñeta roja del timer (sobre la imagen)
                    .overlay(
                        Group {
                            if viewModel.isTimerActive && viewModel.maxTimerValue > 0 && viewModel.showChoices {
                                let progress = max(0, min(1, (viewModel.maxTimerValue - viewModel.timerValue) / viewModel.maxTimerValue))
                                let vigOpacity = progress * 0.9
                                ZStack {
                                    VStack {
                                        LinearGradient(colors: [Color.red.opacity(vigOpacity), .clear], startPoint: .top, endPoint: .bottom).frame(height: 180)
                                        Spacer()
                                    }
                                    VStack {
                                        Spacer()
                                        LinearGradient(colors: [.clear, Color.red.opacity(vigOpacity)], startPoint: .top, endPoint: .bottom).frame(height: 220)
                                    }
                                    HStack {
                                        LinearGradient(colors: [Color.red.opacity(vigOpacity), .clear], startPoint: .leading, endPoint: .trailing).frame(width: 80)
                                        Spacer()
                                    }
                                    HStack {
                                        Spacer()
                                        LinearGradient(colors: [.clear, Color.red.opacity(vigOpacity)], startPoint: .leading, endPoint: .trailing).frame(width: 80)
                                    }
                                }
                                .allowsHitTesting(false)
                                .animation(.easeInOut(duration: 0.3), value: progress)
                            }
                        }
                    )
                    // ── Timer (cuando está activo) ──
                    .overlay(alignment: .top){
                        if viewModel.isTimerActive && viewModel.maxTimerValue > 0 && viewModel.showChoices {
                            let progress = max(0, min(1, viewModel.timerValue / viewModel.maxTimerValue))
                            let isUrgent = viewModel.timerValue < 4.0
                            VStack(spacing: 6) {
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.1))
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(LinearGradient(
                                                colors: isUrgent ? [Color.red, Color.orange] : [Color.yellow, Color.orange],
                                                startPoint: .leading, endPoint: .trailing))
                                            .frame(width: geo.size.width * CGFloat(progress))
                                            .animation(.linear(duration: 0.1), value: progress)
                                    }
                                }
                                .frame(height: 5)
                                .padding(.horizontal, 16)
                                Text(String(format: "%.1f s", viewModel.timerValue))
                                    .font(.system(size: 12, weight: .black, design: .monospaced))
                                    .foregroundColor(isUrgent ? .red : .white.opacity(0.85))
                                    .shadow(color: isUrgent ? .red.opacity(0.7) : .clear, radius: 8)
                            }
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                // Ajusta el número para más o menos curvas
                                .fill(Color.black.opacity(0.65))
                            )
                            .padding(.horizontal, 10)
                            .padding(.top, 10)
                        }
                    }
                    // ── Contenido (narración / opciones) en overlay separado ──
                    // Al estar en .overlay NO hereda el clipping de la imagen.
                    // El texto puede tener su tamaño natural sin cortarse.
                    .overlay(alignment: .bottom) {
                        VStack(spacing: 0) {
                            if let scene = viewModel.currentScene {
                                
                                if viewModel.gameCompleted {
                                    // Pantalla de Final
                                    VStack(spacing: 22) {
                                        Text(viewModel.activeEndingTitle)
                                            .font(.system(size: 30, weight: .black))
                                            .foregroundColor(Theme.accentRed)
                                            .multilineTextAlignment(.center)
                                        Text(viewModel.activeEndingDescription)
                                            .font(.body).multilineTextAlignment(.center)
                                            .foregroundColor(.white.opacity(0.8)).padding(.horizontal)
                                        Button(action: {
                                            viewModel.resetGame()
                                            presentationMode.wrappedValue.dismiss()
                                        }) {
                                            Text("VOLVER AL MENÚ")
                                                .font(.headline).bold().padding()
                                                .frame(maxWidth: .infinity)
                                                .background(Color.white).foregroundColor(.black).cornerRadius(14)
                                        }
                                    }
                                    .padding(36).background(Color.black.opacity(0.9))
                                    .cornerRadius(26).padding(16).padding(.bottom, 20)
                                    
                                } else if viewModel.showChoices {
                                    // ── OPCIONES ──
                                    VStack(spacing: 10) {
                                        let availableChoices = scene.choices.filter { viewModel.canShowChoice($0) }
                                        ForEach(availableChoices) { choice in
                                            ChoiceButton(choice: choice) {
                                                viewModel.makeChoice(choice)
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.bottom, 35)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .bottom).combined(with: .opacity),
                                        removal:   .move(edge: .bottom).combined(with: .opacity)
                                    ))
                                    
                                } else {
                                    // ── CAJA DE NARRACIÓN ──
                                    VStack(spacing: 12) {
                                        if !scene.dialogue.isEmpty {
                                            VStack(alignment: .leading, spacing: 10) {
                                                if let title = scene.title {
                                                    Text(title.uppercased())
                                                        .font(.system(size: 13, weight: .black))
                                                        .foregroundColor(Theme.accentYellow)
                                                        .tracking(2)
                                                }
                                                Text(scene.dialogue)
                                                    .font(.custom("AvenirNext-Medium", size: 16))
                                                    .foregroundColor(.white)
                                                    .lineSpacing(6)
                                                    .fixedSize(horizontal: false, vertical: true)
                                            }
                                            .padding(20)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .background(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .fill(Color.black.opacity(0.78))
                                                    .overlay(RoundedRectangle(cornerRadius: 20)
                                                        .stroke(Color.white.opacity(0.08), lineWidth: 1))
                                            )
                                            .padding(.horizontal, 16)
                                            .onTapGesture { narrator.skip() }
                                        }
                                        
                                        // Controles del Narrador de Voz
                                        if narrator.isSpeaking || narrator.isPaused {
                                            HStack(spacing: 16) {
                                                if narrator.isSpeaking && !narrator.isPaused {
                                                    SoundWaveVisualizer()
                                                } else {
                                                    HStack(spacing: 3) {
                                                        ForEach(0..<4) { _ in
                                                            RoundedRectangle(cornerRadius: 2)
                                                                .fill(Color.gray.opacity(0.5))
                                                                .frame(width: 3, height: 8)
                                                        }
                                                    }
                                                    .frame(height: 24)
                                                }
                                                Button(action: {
                                                    if narrator.isPaused { narrator.resume() } else { narrator.pause() }
                                                }) {
                                                    Image(systemName: narrator.isPaused ? "play.fill" : "pause.fill")
                                                        .font(.title3).foregroundColor(.white)
                                                        .frame(width: 40, height: 40)
                                                        .background(Color.white.opacity(0.12)).clipShape(Circle())
                                                }
                                                Spacer()
                                                Button(action: { narrator.skip() }) {
                                                    Text("OMITIR")
                                                        .font(.system(size: 11, weight: .black))
                                                        .foregroundColor(Theme.accentYellow)
                                                        .padding(.vertical, 8).padding(.horizontal, 12)
                                                        .background(Theme.accentYellow.opacity(0.15)).cornerRadius(8)
                                                }
                                            }
                                            .padding(.horizontal, 16).padding(.vertical, 10)
                                            .background(
                                                RoundedRectangle(cornerRadius: 18)
                                                    .fill(Color.black.opacity(0.6))
                                                    .overlay(RoundedRectangle(cornerRadius: 18)
                                                        .stroke(Color.white.opacity(0.1), lineWidth: 1))
                                            )
                                            .padding(.horizontal, 16)
                                            .transition(.opacity.combined(with: .scale))
                                        }
                                    }
                                    .padding(.bottom, 35)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .bottom).combined(with: .opacity),
                                        removal:   .move(edge: .bottom).combined(with: .opacity)
                                    ))
                                }
                            }
                        }
                        .animation(.easeInOut(duration: 0.45), value: viewModel.showChoices)
                        .animation(.easeInOut(duration: 0.35), value: viewModel.gameCompleted)
                        // Padding inferior: home indicator (~34pt) + espacio de aire
                        .padding(.bottom, 50)
                    }
                }
                .ignoresSafeArea(edges: .bottom)
            }
        }
    }
}

// MARK: - Subvistas para el Flujo Intermedio

struct DestinationIntroView: View {
    let text: String
    let statChanges: [(String, Int)]
    let onContinue: () -> Void
    
    @State private var cardsVisible = false
    
    // Icono por nombre de stat
    private func icon(for stat: String) -> String {
        switch stat {
        case "Disciplina": return "target"
        case "Confianza": return "person.fill.checkmark"
        case "Inteligencia Práctica": return "brain.head.profile"
        case "Energía": return "bolt.fill"
        default: return "star.fill"
        }
    }
    
    // Color por nombre de stat
    private func statColor(for stat: String) -> Color {
        switch stat {
        case "Disciplina": return .blue
        case "Confianza": return Color(red: 0.9, green: 0.2, blue: 0.3)
        case "Inteligencia Práctica": return .purple
        case "Energía": return Color(red: 1.0, green: 0.8, blue: 0.0)
        default: return .white
        }
    }
    
    var body: some View {
        ZStack {
            // Fondo con gradiente cinematográfico
            LinearGradient(
                colors: [Color.black, Color(red: 0.05, green: 0.05, blue: 0.15)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Título de sección
                if !statChanges.isEmpty {
                    Text("CONSECUENCIAS")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.white.opacity(0.4))
                        .tracking(4)
                        .padding(.bottom, 16)
                }
                
                // Texto de intro (solo si no es blank)
                let displayText = text.trimmingCharacters(in: .whitespaces)
                if !displayText.isEmpty {
                    Text(displayText)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .lineSpacing(6)
                        .padding(.horizontal, 30)
                        .padding(.bottom, statChanges.isEmpty ? 0 : 36)
                }
                
                // Tarjetas de cambio de stats
                if !statChanges.isEmpty {
                    VStack(spacing: 12) {
                        ForEach(Array(statChanges.enumerated()), id: \.offset) { index, change in
                            let isPositive = change.1 > 0
                            let color = statColor(for: change.0)
                            
                            HStack(spacing: 14) {
                                // Icono de stat
                                Image(systemName: icon(for: change.0))
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(color)
                                    .frame(width: 28)
                                
                                // Nombre de stat
                                Text(change.0)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                // Badge de cambio
                                Text(isPositive ? "+\(change.1)" : "\(change.1)")
                                    .font(.system(size: 20, weight: .black, design: .rounded))
                                    .foregroundColor(isPositive ? .green : .red)
                                    .frame(width: 52, height: 38)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill((isPositive ? Color.green : Color.red).opacity(0.18))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke((isPositive ? Color.green : Color.red).opacity(0.4), lineWidth: 1)
                                            )
                                    )
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.05))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(color.opacity(0.2), lineWidth: 1)
                                    )
                            )
                            .opacity(cardsVisible ? 1 : 0)
                            .offset(y: cardsVisible ? 0 : 20)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7).delay(Double(index) * 0.12), value: cardsVisible)
                        }
                    }
                    .padding(.horizontal, 24)
                }
                
                Spacer()
                
                Button(action: onContinue) {
                    Text("CONTINUAR")
                        .font(.system(size: 15, weight: .black))
                        .tracking(2)
                        .foregroundColor(.black)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .cornerRadius(16)
                        .padding(.horizontal, 30)
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            withAnimation { cardsVisible = true }
        }
    }
}

struct NodeIntroView: View {
    let text: String
    let onContinue: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                Text(text)
                    .font(.title2)
                    .fontWeight(.light)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding(30)
                
                Spacer()
                
                Button(action: onContinue) {
                    Text("INICIAR ESCENA")
                        .font(.headline)
                        .bold()
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(14)
                        .padding(.horizontal, 30)
                }
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Sound Wave Visualizer
struct SoundWaveVisualizer: View {
    @State private var animate = false
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<4) { index in
                RoundedRectangle(cornerRadius: 2).fill(Theme.accentYellow)
                    .frame(width: 3, height: animate ? CGFloat.random(in: 6...24) : 8)
                    .animation(Animation.easeInOut(duration: Double.random(in: 0.25...0.45)).repeatForever(autoreverses: true), value: animate)
            }
        }
        .frame(height: 24)
        .onAppear { animate = true }
        .onDisappear { animate = false }
    }
}

// MARK: - Previews

#Preview("Escena de Juego Activa") {
    // 1. Creamos una escena de prueba simulando la llegada desde el JSON/Modelo
    let mockScene = GameScene(
        id: "escena_callejon_01",
        title: "El Encuentro",
        introduction: "Capítulo 1: La decisión inevitable",
        dialogue: "Un silencio sepulcral inunda el callejón. A lo lejos, divisas una silueta que se acerca a paso firme. Tu energía decae, pero tu instinto te dice que no debes huir. ¿Qué harás?",
        backgroundImage: "bg_dark_alley",
        choices: [
            Choice(id: "c1", text: "Enfrentar a la silueta con calma", targetSceneID: "next_01", introduccionDestino: "Decides mantener la compostura.", requisitos: nil, consecuencias: nil, isWorst: false),
            Choice(id: "c2", text: "Esconderte detrás de los contenedores", targetSceneID: "next_02", introduccionDestino: "Buscas cobertura rápidamente.", requisitos: nil, consecuencias: nil, isWorst: true)
        ],
        isEnding: false,
        musicTrack: "tension_theme",
        timeLimit: 12.0,
    )
    
    // 2. Instanciamos el ViewModel real
    let viewModel = GameViewModel()
    
    // 3. Inyectamos los estados iniciales simulados para que el Canvas los pinte
    viewModel.currentScene = mockScene
    viewModel.disciplina = 6
    viewModel.inteligenciaPractica = 4
    viewModel.confianza = 8
    viewModel.energia = 5
    
    // Forzamos a que muestre el flujo principal (puedes cambiarlo a false para ver la caja de texto)
    viewModel.showChoices = true
    
    // Opcional: Si quieres probar cómo se ve el Timer corriendo en tiempo real en la vista interactiva
    viewModel.isTimerActive = true
    viewModel.maxTimerValue = 12.0
    viewModel.timerValue = 8.4

    return NavigationStack {
        NarrativeView(viewModel: viewModel)
    }
}
