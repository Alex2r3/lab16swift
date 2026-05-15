import SwiftUI

struct NarrativeView: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Theme.black.ignoresSafeArea()
            
            // Fondo Cinematográfico
            VStack {
                if let scene = viewModel.currentScene {
                    ZStack {
                        Rectangle().fill(Theme.darkGray)
                        Text("IMAGEN: \(scene.backgroundImage)")
                            .foregroundColor(.white.opacity(0.2))
                    }
                    .frame(maxHeight: .infinity)
                    .ignoresSafeArea()
                }
            }
            
            VStack {
                // HUD de Estadísticas
                HStack(spacing: 12) {
                    StatBar(label: "CONFIANZA", value: viewModel.trust, color: .blue)
                    StatBar(label: "VALENTÍA", value: viewModel.bravery, color: Theme.accentRed)
                    StatBar(label: "HUMANIDAD", value: viewModel.humanity, color: Theme.accentYellow)
                }
                .padding()
                .background(Color.black.opacity(0.6))
                
                // Timer de decisión
                if viewModel.isTimerActive {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle().fill(Color.white.opacity(0.1))
                            Rectangle()
                                .fill(Theme.accentRed)
                                .frame(width: geo.size.width * CGFloat(viewModel.timerValue / 5.0)) // Asumiendo 5s max
                        }
                    }
                    .frame(height: 4)
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Diálogo y Decisiones
                VStack(spacing: 20) {
                    if let scene = viewModel.currentScene {
                        VStack(alignment: .leading, spacing: 12) {
                            if let name = scene.characterName {
                                Text(name.uppercased())
                                    .font(.system(size: 14, weight: .black))
                                    .foregroundColor(Theme.accentYellow)
                                    .tracking(3)
                            }
                            
                            Text(scene.dialogue)
                                .font(.custom("AvenirNext-Medium", size: 19))
                                .lineSpacing(6)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(30)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.black.opacity(0.7))
                                .overlay(RoundedRectangle(cornerRadius: 25).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        )
                        .padding(.horizontal)
                        
                        if !viewModel.gameCompleted {
                            VStack(spacing: 12) {
                                ForEach(scene.choices) { choice in
                                    ChoiceButton(choice: choice) {
                                        viewModel.makeChoice(choice)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 30)
                        } else {
                            // Pantalla de Final
                            VStack(spacing: 20) {
                                Text(viewModel.activeEndingTitle)
                                    .font(.system(size: 32, weight: .black))
                                    .foregroundColor(Theme.accentRed)
                                
                                Text(viewModel.activeEndingDescription)
                                    .multilineTextAlignment(.center)
                                    .opacity(0.8)
                                    .padding(.horizontal)
                                
                                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                                    Text("VOLVER AL MENÚ")
                                        .bold()
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.white)
                                        .foregroundColor(.black)
                                        .cornerRadius(12)
                                }
                            }
                            .padding(40)
                            .background(Color.black)
                            .cornerRadius(30)
                            .padding()
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
}
