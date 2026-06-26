import SwiftUI
import FirebaseAuth

struct AuthView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoginMode = true
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            Theme.black.ignoresSafeArea()
            
            VStack(spacing: 25) {
                // Logo o Título
                VStack(spacing: 10) {
                    Image("logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height:200)
                    
                    Text("Proyecto Final")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(2)
                    
                    Text(isLoginMode ? "Inicia sesión para continuar" : "Crea tu cuenta")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 30)
                
                // Formulario
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.red)
                        TextField("Correo Electrónico", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .foregroundStyle(.red)
                    }
                    .padding()
                    .background(Theme.darkGray)
                    .cornerRadius(12)
                    
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.red)
                        SecureField("Contraseña",text: $password)
                            .foregroundStyle(.red)
                            .tint(.red)
                    }
                    .padding()
                    .background(Theme.darkGray)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                
                // Mensaje de Error
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Botón Principal
                Button(action: handleAction) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(isLoginMode ? "Iniciar Sesión" : "Registrarse")
                                .font(.headline)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.accentRed)
                    .cornerRadius(12)
                }
                .disabled(isLoading || email.isEmpty || password.isEmpty)
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // Alternar Modo
                Button(action: {
                    withAnimation {
                        isLoginMode.toggle()
                        errorMessage = ""
                    }
                }) {
                    Text(isLoginMode ? "¿No tienes cuenta? Regístrate aquí" : "¿Ya tienes cuenta? Inicia sesión")
                        .font(.footnote)
                        .foregroundColor(Theme.accentYellow)
                }
                .padding(.top, 10)
                
                Spacer()
            }
            .padding(.top, 50)
        }
    }
    
    private func handleAction() {
        isLoading = true
        errorMessage = ""
        
        if isLoginMode {
            Auth.auth().signIn(withEmail: email, password: password) { result, error in
                isLoading = false
                if let error = error {
                    self.errorMessage = "Error al iniciar sesión: \(error.localizedDescription)"
                }
            }
        } else {
            Auth.auth().createUser(withEmail: email, password: password) { result, error in
                isLoading = false
                if let error = error {
                    self.errorMessage = "Error al registrarse: \(error.localizedDescription)"
                }
            }
        }
    }
}

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView()
    }
}
