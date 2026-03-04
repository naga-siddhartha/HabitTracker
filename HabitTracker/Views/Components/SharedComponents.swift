import SwiftUI

// MARK: - Icon Circle

struct IconCircle: View {
    let iconName: String?
    let color: Color
    var size: CGFloat = 48
    var isCompleted: Bool = false
    
    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(isCompleted ? 1 : 0.15))
                .frame(width: size, height: size)
            if isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.375, weight: .bold))
                    .foregroundStyle(.white)
            } else if let iconName {
                Image(systemName: iconName)
                    .font(.system(size: size * 0.42))
                    .foregroundStyle(color)
            }
        }
    }
}

// MARK: - Progress Ring

struct ProgressRing: View {
    let progress: Double
    let count: Int
    let total: Int
    var size: CGFloat = 56
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.systemGray5, lineWidth: 6)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(progress == 1 ? Color.green : Color.accentColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(duration: 0.5), value: progress)
            VStack(spacing: 0) {
                Text("\(count)")
                    .font(.system(size: size * 0.36, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                Text("/\(total)")
                    .font(.system(size: size * 0.2, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
    }
}

