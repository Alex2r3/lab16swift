import SwiftUI

struct StatBar: View {
    let label: String
    let value: Int
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label).font(.system(size: 9, weight: .bold)).foregroundColor(.white.opacity(0.6))
                Spacer()
                Text("\(value)/10").font(.system(size: 10)).foregroundColor(color)
            }
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2).fill(Color.white.opacity(0.1)).frame(height: 4)
                RoundedRectangle(cornerRadius: 2).fill(color).frame(width: CGFloat(value) * 8.5, height: 4)
                    .shadow(color: color.opacity(0.5), radius: 3)
            }
        }.frame(width: 85)
    }
}
