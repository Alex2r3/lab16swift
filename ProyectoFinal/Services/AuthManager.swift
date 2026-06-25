import Foundation
import FirebaseAuth
import FirebaseCore

class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var userSession: FirebaseAuth.User?
    
    private init() {
        self.userSession = Auth.auth().currentUser
        
        // Escuchar cambios en el estado de autenticación
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.userSession = user
            }
        }
    }
    
    var isAuthenticated: Bool {
        return userSession != nil
    }
    
    var currentUserId: String? {
        return userSession?.uid
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                self.userSession = nil
            }
        } catch {
            print("Error cerrando sesión: \(error.localizedDescription)")
        }
    }
}
