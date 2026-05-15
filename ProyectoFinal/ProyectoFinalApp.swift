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
    @State private var selectedTab = 0
    
    init() {
        // Personalización básica de la TabBar para modo oscuro
        UITabBar.appearance().barTintColor = .black
        UITabBar.appearance().unselectedItemTintColor = .gray
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                HomeView()
                    .background(Theme.black.ignoresSafeArea())
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text("Inicio")
            }
            .tag(0)
            
            NavigationView {
                Text("Biblioteca de Historias")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Theme.black.ignoresSafeArea())
            }
            .tabItem {
                Image(systemName: "books.vertical.fill")
                Text("Librería")
            }
            .tag(1)
            
            NavigationView {
                Text("Perfil de Usuario")
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Theme.black.ignoresSafeArea())
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
