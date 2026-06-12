import SwiftUI

struct NarrativeView: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Theme.black.ignoresSafeArea()
            
            // ── Fondo Cinematográfico ──────────────────────────────────
            if let scene = viewModel.currentScene {
                ZStack {
                    if let uiImage = MediaImageLoader.loadImage(named: scene.backgroundImage) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                    } else {
                        Theme.mainGradient
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
                    // Base scrim para legibilidad
                    LinearGradient(
                        colors: [.black.opacity(0.35), .black.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .ignoresSafeArea()
            }
            
            // ── Vigneta de borde con degradado (4 bordes) ─────────────
            if viewModel.isTimerActive && viewModel.maxTimerValue > 0 {
                let progress = max(0, min(1, (viewModel.maxTimerValue - viewModel.timerValue) / viewModel.maxTimerValue))
                let vigOpacity = progress * 0.9
                
                ZStack {
                    // Borde Superior
                    VStack {
                        LinearGradient(
                            colors: [Color.red.opacity(vigOpacity), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 180)
                        Spacer()
                    }
                    // Borde Inferior
                    VStack {
                        Spacer()
                        LinearGradient(
                            colors: [.clear, Color.red.opacity(vigOpacity)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 220)
                    }
                    // Borde Izquierdo
                    HStack {
                        LinearGradient(
                            colors: [Color.red.opacity(vigOpacity), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: 80)
                        Spacer()
                    }
                    // Borde Derecho
                    HStack {
                        Spacer()
                        LinearGradient(
                            colors: [.clear, Color.red.opacity(vigOpacity)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: 80)
                    }
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .animation(.easeInOut(duration: 0.3), value: progress)
            }
            
            // ── Contenido principal ────────────────────────────────────
            VStack(spacing: 0) {
                
                // HUD Estadísticas
                HStack(spacing: 10) {
                    StatBar(label: "CONFIANZA", value: viewModel.trust, color: .blue)
                    StatBar(label: "VALENTÍA",  value: viewModel.bravery,   color: Theme.accentRed)
                    StatBar(label: "HUMANIDAD", value: viewModel.humanity,  color: Theme.accentYellow)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.55))
                
                // ── Timer Grande ─────────────────────────────────────
                if viewModel.isTimerActive && viewModel.maxTimerValue > 0 {
                    let progress = max(0, min(1, viewModel.timerValue / viewModel.maxTimerValue))
                    let isUrgent = viewModel.timerValue < 4.0
                    
                    VStack(spacing: 6) {
                        // Barra de progreso gruesa
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white.opacity(0.1))
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            colors: isUrgent
                                                ? [Color.red, Color.orange]
                                                : [Color.yellow, Color.orange],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geo.size.width * CGFloat(progress))
                                    .animation(.linear(duration: 0.1), value: progress)
                            }
                        }
                        .frame(height: 14)
                        .padding(.horizontal, 16)
                        
                        // Cuenta regresiva grande
                        Text(String(format: "⏱  %.1f s", viewModel.timerValue))
                            .font(.system(size: 26, weight: .black, design: .monospaced))
                            .foregroundColor(isUrgent ? .red : .white.opacity(0.85))
                            .shadow(color: isUrgent ? .red.opacity(0.7) : .clear, radius: 8)
                    }
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.4))
                }
                
                Spacer()
                
                // ── Diálogo y opciones ────────────────────────────────
                VStack(spacing: 18) {
                    if let scene = viewModel.currentScene {
                        
                        // Caja de diálogo
                        VStack(alignment: .leading, spacing: 10) {
                            if let name = scene.characterName {
                                Text(name.uppercased())
                                    .font(.system(size: 13, weight: .black))
                                    .foregroundColor(Theme.accentYellow)
                                    .tracking(4)
                            }
                            Text(scene.dialogue)
                                .font(.custom("AvenirNext-Medium", size: 18))
                                .foregroundColor(.white)
                                .lineSpacing(7)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 22)
                                .fill(Color.black.opacity(0.72))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22)
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 16)
                        
                        // Opciones de decisión
                        if !viewModel.gameCompleted {
                            VStack(spacing: 10) {
                                ForEach(scene.choices) { choice in
                                    ChoiceButton(choice: choice) {
                                        viewModel.makeChoice(choice)
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 28)
                        } else {
                            // ── Pantalla de Final ─────────────────────
                            VStack(spacing: 22) {
                                Text(viewModel.activeEndingTitle)
                                    .font(.system(size: 30, weight: .black))
                                    .foregroundColor(Theme.accentRed)
                                    .multilineTextAlignment(.center)
                                
                                Text(viewModel.activeEndingDescription)
                                    .font(.body)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding(.horizontal)
                                
                                Button(action: {
                                    viewModel.resetGame()
                                    presentationMode.wrappedValue.dismiss()
                                }) {
                                    Text("VOLVER AL MENÚ")
                                        .font(.headline)
                                        .bold()
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.white)
                                        .foregroundColor(.black)
                                        .cornerRadius(14)
                                }
                            }
                            .padding(36)
                            .background(Color.black.opacity(0.9))
                            .cornerRadius(26)
                            .padding(16)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onDisappear {
            viewModel.resetGame()
        }
    }
}
