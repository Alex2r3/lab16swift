import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Política de Privacidad")
                        .font(.largeTitle)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                        .padding(.bottom, 10)
                    
                    Group {
                        Text("Introducción")
                            .font(.title2)
                            .bold()
                            .foregroundColor(Theme.accentYellow)
                        
                        Text("Proyecto Final, la aplicación se compromete a proteger la privacidad de sus usuarios. Esta Política de privacidad describe cómo utilizamos su información personal cuando utilizamos la Aplicación.")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.85))
                            .lineSpacing(4)
                    }
                    
                    Divider().background(Color.gray.opacity(0.3))
                    
                    Group {
                        Text("Recopilación de información personal")
                            .font(.title2)
                            .bold()
                            .foregroundColor(Theme.accentYellow)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            BulletPoint(title: "Información de la cuenta", description: "Cuando crea una cuenta en la Aplicación, le pedimos que proporcione su dirección de correo electrónico y contraseña.")
                            
                            BulletPoint(title: "Datos de uso", description: "No recopilamos ningún tipo de dato adicional.")
                            
                            BulletPoint(title: "Datos del dispositivo", description: "No recopilamos ningún tipo de dato adicional.")
                        }
                    }
                    
                    Divider().background(Color.gray.opacity(0.3))
                    
                    Group {
                        Text("Uso de la información personal")
                            .font(.title2)
                            .bold()
                            .foregroundColor(Theme.accentYellow)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            BulletPoint(title: "Comunicarnos con usted", description: "Podemos utilizar su información personal para comunicarnos con usted sobre su cuenta, la Aplicación o nuestros servicios.")
                            
                            BulletPoint(title: "Seguridad y protección", description: "Podemos utilizar su información personal para fines de seguridad y protección, como para detectar y prevenir fraudes o abusos.")
                        }
                    }
                    
                    Divider().background(Color.gray.opacity(0.3))
                    
                    Group {
                        Text("Divulgación de la información personal")
                            .font(.title2)
                            .bold()
                            .foregroundColor(Theme.accentYellow)
                        
                        Text("No divulgamos su información personal a terceros sin su consentimiento. Sin excepciones.")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.85))
                    }
                    
                    Divider().background(Color.gray.opacity(0.3))
                    
                    Group {
                        Text("Sus opciones")
                            .font(.title2)
                            .bold()
                            .foregroundColor(Theme.accentYellow)
                        
                        Text("En cualquier momento, usted tiene la opción de eliminar su cuenta completamente desde el panel de perfil de la Aplicación. Al hacerlo, eliminaremos de manera permanente y definitiva toda su información personal, incluyendo progreso y logros, de nuestras bases de datos y sistemas de autenticación.")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.85))
                    }
                    
                    Divider().background(Color.gray.opacity(0.3))

                    Group {
                        Text("Seguridad de la información personal")
                            .font(.title2)
                            .bold()
                            .foregroundColor(Theme.accentYellow)
                        
                        Text("Tomamos medidas razonables para proteger su información personal contra la pérdida, el robo, el uso no autorizado, la divulgación y la alteración. Sin embargo, ninguna medida de seguridad es perfecta y no podemos garantizar la seguridad absoluta de su información personal.")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.85))
                    }
                    
                    Divider().background(Color.gray.opacity(0.3))
                    
                    Group {
                        Text("Cambios en esta política de privacidad")
                            .font(.title2)
                            .bold()
                            .foregroundColor(Theme.accentYellow)
                        
                        Text("Podemos actualizar esta Política de privacidad de vez en cuando. Le notificaremos de cualquier cambio publicando la Política de privacidad actualizada en la Aplicación.")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.85))
                    }
                    
                    Divider().background(Color.gray.opacity(0.3))
                    
                    Group {
                        Text("Contacto")
                            .font(.title2)
                            .bold()
                            .foregroundColor(Theme.accentYellow)
                        
                        Text("Si tiene alguna pregunta sobre esta Política de privacidad, puede contactarnos en:")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.85))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Link("marchunque7880@gmail.com", destination: URL(string: "mailto:marchunque7880@gmail.com")!)
                                .font(.headline)
                                .foregroundColor(Theme.accentRed)
                            
                            Link("antoniovs11nov@gmail.com", destination: URL(string: "mailto:antoniovs11nov@gmail.com")!)
                                .font(.headline)
                                .foregroundColor(Theme.accentRed)
                        }
                        .padding(.top, 2)
                    }
                    
                    Divider().background(Color.gray.opacity(0.3))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Fecha de vigencia: 2 de julio de 2026")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 10)
                }
                .padding()
            }
            .background(Theme.black.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

struct BulletPoint: View {
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("•")
                .foregroundColor(Theme.accentRed)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.75))
                    .lineSpacing(2)
            }
        }
    }
}

struct PrivacyPolicyView_Previews: PreviewProvider {
    static var previews: some View {
        PrivacyPolicyView()
            .preferredColorScheme(.dark)
    }
}
