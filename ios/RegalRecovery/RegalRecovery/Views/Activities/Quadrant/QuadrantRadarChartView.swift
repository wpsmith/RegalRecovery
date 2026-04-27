import SwiftUI

struct QuadrantRadarChartView: View {
    let bodyScore: Int
    let mindScore: Int
    let heartScore: Int
    let spiritScore: Int
    var previousBodyScore: Int? = nil
    var previousMindScore: Int? = nil
    var previousHeartScore: Int? = nil
    var previousSpiritScore: Int? = nil
    var size: CGFloat = 200

    private var padding: CGFloat { size * 0.22 }
    private var radius: CGFloat { (size / 2) - padding }
    private var center: CGPoint { CGPoint(x: size / 2, y: size / 2) }

    private let axes: [(angle: Double, quadrant: QuadrantType)] = [
        (angle: -90, quadrant: .body),
        (angle: 0,   quadrant: .mind),
        (angle: 90,  quadrant: .heart),
        (angle: 180, quadrant: .spirit),
    ]

    private var currentScores: [Int] { [bodyScore, mindScore, heartScore, spiritScore] }

    private var previousScores: [Int]? {
        guard let pb = previousBodyScore,
              let pm = previousMindScore,
              let ph = previousHeartScore,
              let ps = previousSpiritScore else { return nil }
        return [pb, pm, ph, ps]
    }

    private func point(score: Int, angleDegrees: Double) -> CGPoint {
        let fraction = Double(score) / 10.0
        let angleRad = angleDegrees * .pi / 180.0
        return CGPoint(
            x: center.x + fraction * radius * cos(angleRad),
            y: center.y + fraction * radius * sin(angleRad)
        )
    }

    private func axisEndPoint(angleDegrees: Double) -> CGPoint {
        let angleRad = angleDegrees * .pi / 180.0
        return CGPoint(
            x: center.x + radius * cos(angleRad),
            y: center.y + radius * sin(angleRad)
        )
    }

    private func labelPoint(angleDegrees: Double) -> CGPoint {
        let labelRadius = radius + padding * 0.55
        let angleRad = angleDegrees * .pi / 180.0
        return CGPoint(
            x: center.x + labelRadius * cos(angleRad),
            y: center.y + labelRadius * sin(angleRad)
        )
    }

    private func polygonPath(scores: [Int]) -> Path {
        var path = Path()
        for (index, axis) in axes.enumerated() {
            let pt = point(score: scores[index], angleDegrees: axis.angle)
            if index == 0 {
                path.move(to: pt)
            } else {
                path.addLine(to: pt)
            }
        }
        path.closeSubpath()
        return path
    }

    private func referencePath(fraction: Double) -> Path {
        var path = Path()
        for (index, axis) in axes.enumerated() {
            let angleRad = axis.angle * .pi / 180.0
            let pt = CGPoint(
                x: center.x + fraction * radius * cos(angleRad),
                y: center.y + fraction * radius * sin(angleRad)
            )
            if index == 0 {
                path.move(to: pt)
            } else {
                path.addLine(to: pt)
            }
        }
        path.closeSubpath()
        return path
    }

    var body: some View {
        Canvas { context, _ in
            for level in [0.2, 0.4, 0.6, 0.8, 1.0] {
                let path = referencePath(fraction: level)
                context.stroke(path, with: .color(Color.rrTextSecondary.opacity(0.18)), lineWidth: 1)
            }

            for axis in axes {
                var axisPath = Path()
                axisPath.move(to: center)
                axisPath.addLine(to: axisEndPoint(angleDegrees: axis.angle))
                context.stroke(axisPath, with: .color(Color.rrTextSecondary.opacity(0.25)), lineWidth: 1)
            }

            if let prevScores = previousScores {
                let prevPath = polygonPath(scores: prevScores)
                context.stroke(
                    prevPath,
                    with: .color(Color.rrTextSecondary.opacity(0.4)),
                    style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])
                )
            }

            let currentPath = polygonPath(scores: currentScores)
            context.fill(currentPath, with: .color(Color(.systemPurple).opacity(0.18)))
            context.stroke(currentPath, with: .color(Color(.systemPurple).opacity(0.7)), lineWidth: 2)

            for (index, axis) in axes.enumerated() {
                let pt = point(score: currentScores[index], angleDegrees: axis.angle)
                let dotRect = CGRect(x: pt.x - 4, y: pt.y - 4, width: 8, height: 8)
                context.fill(Path(ellipseIn: dotRect), with: .color(axis.quadrant.color))
            }
        }
        .frame(width: size, height: size)
        .overlay(axisLabelsOverlay)
        .accessibilityLabel(Text(String(localized: "Recovery Quadrant: Body \(bodyScore), Mind \(mindScore), Heart \(heartScore), Spirit \(spiritScore)")))
    }

    private var axisLabelsOverlay: some View {
        ZStack {
            ForEach(axes, id: \.quadrant) { axis in
                let lp = labelPoint(angleDegrees: axis.angle)
                VStack(spacing: 1) {
                    Image(systemName: axis.quadrant.icon)
                        .font(.system(size: size * 0.08))
                        .foregroundStyle(axis.quadrant.color)
                    Text(axis.quadrant.displayName)
                        .font(.system(size: size * 0.075, weight: .medium))
                        .foregroundStyle(Color.rrText)
                }
                .position(x: lp.x, y: lp.y)
            }
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    VStack(spacing: 24) {
        QuadrantRadarChartView(
            bodyScore: 8,
            mindScore: 6,
            heartScore: 4,
            spiritScore: 9,
            previousBodyScore: 6,
            previousMindScore: 5,
            previousHeartScore: 3,
            previousSpiritScore: 7,
            size: 240
        )

        QuadrantRadarChartView(
            bodyScore: 5,
            mindScore: 5,
            heartScore: 5,
            spiritScore: 5,
            size: 200
        )
    }
    .padding()
    .background(Color.rrBackground)
}
