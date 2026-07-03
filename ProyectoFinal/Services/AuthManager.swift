import Foundation
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore


class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var userSession: FirebaseAuth.User?
    
    @Published var accountDeletedSuccessfully = false
    
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
                self.accountDeletedSuccessfully = false
            }
        } catch {
            print("Error cerrando sesión: \(error.localizedDescription)")
        }
    }
    
    func deleteAccount(completion: @escaping (Error?) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(NSError(domain: "Auth", code: -1, userInfo: [NSLocalizedDescriptionKey: "No hay usuario autenticado."]))
            return
        }
        
        let userId = user.uid
        let db = FirebaseFirestore.Firestore.firestore()
        
        // 1. Delete user data from Firestore
        db.collection("users").document(userId).delete { error in
            if let error = error {
                print("Error eliminando datos de Firestore: \(error.localizedDescription)")
                // Continuar de todas formas con la eliminación de Auth por si los datos no existían
            }
            
            // 2. Delete user from Firebase Auth
            user.delete { authError in
                if let authError = authError {
                    completion(authError)
                } else {
                    DispatchQueue.main.async {
                        self.userSession = nil
                        self.accountDeletedSuccessfully = true
                        completion(nil)
                    }
                }
            }
        }
    }
}
