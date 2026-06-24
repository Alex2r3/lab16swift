import SwiftUI

struct StatBar: View {
    let label: String
    let value: Int
    let color: Color
    
    // El valor máximo es 10, así que calculamos el porcentaje (de 0.0 a 1.0)
    private var progress: CGFloat {
        CGFloat(clampedValue) / 10.0
    }
    
    // Evitamos que explote si por error llega un número fuera de rango
    private var clampedValue: Int {
        max(0, min(value, 10))
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // ── CÍRCULO DE PROGRESO ──
            ZStack {
                // Fondo del círculo (gris traslúcido)
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 6)
                
                // Anillo de progreso de color
                Circle()
                    .trim(from: 0.0, to: progress)
                    .stroke(
                        color,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round) // Extremos redondeados elegantes
                    )
                    .rotationEffect(Angle(degrees: -90)) // Rota para que empiece arriba en el centro
                    .animation(.easeOut(duration: 0.6), value: progress) // Animación suave al cambiar
                    .shadow(color: color.opacity(0.4), radius: 4)
                
                // Texto interno (ej: "8/10")
                Text("\(clampedValue)/10")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(color)
            }
            .frame(width: 40, height: 40) // Tamaño controlado del anillo
            
            // ── TEXTO DEL ATRIBUTO ──
            Text(label.uppercased())
                .font(.system(size: 9, weight: .black))
                .foregroundColor(color.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineLimit(1)
        }
        .frame(width: 70) // Ancho del contenedor para alinearlos fácilmente en un HStack
    }
}
