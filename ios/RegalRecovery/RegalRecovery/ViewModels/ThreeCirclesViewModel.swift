import Foundation
import Observation

@Observable
class ThreeCirclesViewModel {
    var redCircle: [String] = []    // Acting out behaviors
    var yellowCircle: [String] = [] // Warning behaviors
    var greenCircle: [String] = []  // Healthy behaviors

    func load() async {
        let data = MockData.threeCircles
        redCircle = data.red
        yellowCircle = data.yellow
        greenCircle = data.green
    }

    func addItem(to circle: String, item: String) async throws {
        guard !item.isEmpty else { return }

        switch circle.lowercased() {
        case "red":
            guard !redCircle.contains(item) else { return }
            redCircle.append(item)
        case "yellow":
            guard !yellowCircle.contains(item) else { return }
            yellowCircle.append(item)
        case "green":
            guard !greenCircle.contains(item) else { return }
            greenCircle.append(item)
        default:
            break
        }
    }

    func removeItem(from circle: String, item: String) async throws {
        switch circle.lowercased() {
        case "red":
            redCircle.removeAll(where: { $0 == item })
        case "yellow":
            yellowCircle.removeAll(where: { $0 == item })
        case "green":
            greenCircle.removeAll(where: { $0 == item })
        default:
            break
        }
    }

    func moveItem(from: String, to: String, item: String) async throws {
        try await removeItem(from: from, item: item)
        try await addItem(to: to, item: item)
    }
}
