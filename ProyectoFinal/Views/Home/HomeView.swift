import SwiftUI

struct HomeView: View {
    @StateObject var viewModel = GameViewModel()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                // Banner Cinematográfico
                ZStack(alignment: .bottomLeading) {
                    Rectangle()
                        .fill(Theme.darkGray)
                        .frame(height: 500)
                        .overlay(
                            LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                        )
                    
                    VStack(alignment: .leading, spacing: 15) {
                        Text("HISTORIA PRINCIPAL")
                            .font(.caption).bold().padding(6).background(Theme.accentRed).cornerRadius(4)
                        
                        Text("El Último Faro")
                            .font(.system(size: 48, weight: .black))
                        
                        Text("Cada luz oculta una sombra. Cada decisión dicta tu supervivencia.")
                            .font(.subheadline).opacity(0.8)
                        
                        NavigationLink(destination: NarrativeView(viewModel: viewModel).onAppear {
                            viewModel.startStory(StoryService.getElUltimoFaro())
                        }) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("COMENZAR HISTORIA")
                            }
                            .font(.headline)
                            .padding()
                            .frame(width: 250)
                            .background(Color.white)
                            .foregroundColor(.black)
                            .cornerRadius(12)
                        }
                    }
                    .padding(30)
                }
                .ignoresSafeArea(edges: .top)
                
                // Sección de Exploración
                VStack(alignment: .leading, spacing: 15) {
                    Text("MÁS HISTORIAS")
                        .font(.headline).tracking(3).padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(0..<3) { _ in
                                StoryCard()
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.bottom, 50)
        }
    }
}

struct StoryCard: View {
    var body: some View {
        VStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 15)
                .fill(Theme.darkGray)
                .frame(width: 180, height: 260)
            Text("Próximamente")
                .font(.caption).bold()
            Text("Aventura • Suspenso")
                .font(.system(size: 10)).opacity(0.5)
        }
    }
}
