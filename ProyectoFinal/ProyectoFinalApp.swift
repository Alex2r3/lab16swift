import SwiftUI

@main
struct ProyectoFinalApp: App {
    var body: some Scene {
        WindowGroup {
            MainContentView()
        }
    }
}

struct MainContentView: View {
    @StateObject private var viewModel = GameViewModel()
    @State private var selectedTab = 0
    
    init() {
        // Personalización básica de la TabBar para modo oscuro
        UITabBar.appearance().barTintColor = .black
        UITabBar.appearance().unselectedItemTintColor = .gray
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                HomeView(viewModel: viewModel)
                    .background(Theme.black.ignoresSafeArea())
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarHidden(true)
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text("Inicio")
            }
            .tag(0)
            
            NavigationView {
                LibraryView(viewModel: viewModel)
                    .navigationBarHidden(true)
            }
            .tabItem {
                Image(systemName: "books.vertical.fill")
                Text("Librería")
            }
            .tag(1)
            
            NavigationView {
                ProfileView()
                    .navigationBarHidden(true)
            }
            .tabItem {
                Image(systemName: "person.fill")
                Text("Perfil")
            }
            .tag(2)
        }
        .accentColor(.white)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Library View
struct LibraryView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var allStories: [Story] = []
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("BIBLIOTECA")
                    .font(.system(size: 28, weight: .black))
                    .tracking(2)
                    .foregroundColor(.white)
                    .padding(.horizontal)
                    .padding(.top, 25)
                
                if allStories.isEmpty {
                    Text("No se encontraron historias.")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    ForEach(allStories) { story in
                        NavigationLink(destination: StoryDetailView(story: story, viewModel: viewModel)) {
                            HStack(spacing: 16) {
                                if let uiImage = MediaImageLoader.loadImage(named: story.coverImage) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 80, height: 110)
                                        .cornerRadius(8)
                                        .clipped()
                                } else {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Theme.darkGray)
                                        .frame(width: 80, height: 110)
                                        .overlay(
                                            Image(systemName: "book.fill")
                                                .foregroundColor(.white.opacity(0.3))
                                        )
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(story.title)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Text(story.description)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.leading)
                                    
                                    HStack {
                                        Text(story.genre.uppercased())
                                            .font(.system(size: 10, weight: .bold))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 3)
                                            .background(Theme.accentRed.opacity(0.2))
                                            .foregroundColor(Theme.accentRed)
                                            .cornerRadius(4)
                                        
                                        Spacer()
                                        
                                        Text(story.duration)
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding()
                            .background(Theme.darkGray.opacity(0.5))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(.bottom, 30)
        }
        .background(Theme.black.ignoresSafeArea())
        .onAppear {
            self.allStories = StoryService.loadAllStories()
        }
    }
}

// MARK: - Profile View
struct ProfileView: View {
    @ObservedObject var progressManager = ProgressManager.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header de Perfil
                VStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(Theme.accentYellow)
                    
                    Text("Explorador de Destinos")
                        .font(.title2).bold()
                        .foregroundColor(.white)
                    
                    let endingsCount = progressManager.getGlobalEndingCount()
                    Text("Nivel \(1 + endingsCount / 2) • \(getTitleForLevel(endingsCount))")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.top, 40)
                
                // Tarjetas de Estadísticas
                HStack(spacing: 20) {
                    ProfileStatCard(title: "Historias Iniciadas", value: "\(progressManager.getGlobalReadCount())")
                    ProfileStatCard(title: "Finales Descubiertos", value: "\(progressManager.getGlobalEndingCount())")
                }
                .padding(.horizontal)
                
                // Sección de Logros
                VStack(alignment: .leading, spacing: 15) {
                    Text("LOGROS OBTENIDOS")
                        .font(.headline).tracking(2)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                    
                    let endingsCount = progressManager.getGlobalEndingCount()
                    let readCount = progressManager.getGlobalReadCount()
                    
                    VStack(spacing: 12) {
                        AchievementRow(icon: "star.fill", title: "Primer Paso", desc: "Comenzaste tu primera aventura.", unlocked: readCount >= 1)
                        AchievementRow(icon: "timer", title: "Reflejos Rápidos", desc: "Tomaste una decisión antes del límite de tiempo.", unlocked: readCount >= 1)
                        AchievementRow(icon: "crown.fill", title: "Coleccionista de Destinos", desc: "Desbloqueaste al menos 3 finales.", unlocked: endingsCount >= 3)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 50)
        }
        .background(Theme.black.ignoresSafeArea())
    }
    
    func getTitleForLevel(_ endingsCount: Int) -> String {
        if endingsCount >= 10 {
            return "Maestro de Destinos"
        } else if endingsCount >= 5 {
            return "Lector Avanzado"
        } else if endingsCount >= 2 {
            return "Aventurero Novato"
        } else {
            return "Viajero Inicial"
        }
    }
}

struct ProfileStatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 32, weight: .black))
                .foregroundColor(.white)
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Theme.darkGray)
        .cornerRadius(12)
    }
}

struct AchievementRow: View {
    let icon: String
    let title: String
    let desc: String
    let unlocked: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(unlocked ? Theme.accentYellow : .gray)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(unlocked ? .white : .gray)
                Text(desc)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            if unlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Image(systemName: "lock.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Theme.darkGray.opacity(0.4))
        .cornerRadius(12)
    }
}
