import Foundation
import Network
import OSLog

// MARK: - Connection Type

enum ConnectionType: String, Sendable {
    case wifi
    case cellular
    case wiredEthernet
    case unknown
}

// MARK: - Network Monitor

/// Observes device network reachability using NWPathMonitor.
/// UI can bind to `isConnected` and `connectionType` for offline indicators.
@Observable
final class NetworkMonitor: @unchecked Sendable {

    // MARK: - Published State

    private(set) var isConnected: Bool = true
    private(set) var connectionType: ConnectionType = .unknown
    private(set) var isExpensive: Bool = false
    private(set) var isConstrained: Bool = false

    // MARK: - Internals

    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "com.regalrecovery.network-monitor", qos: .utility)
    private let logger = Logger(subsystem: "com.regalrecovery.app", category: "NetworkMonitor")

    /// Callback invoked when connectivity changes. SyncEngine subscribes to this.
    var onConnectivityChanged: (@Sendable (Bool) -> Void)?

    // MARK: - Lifecycle

    init() {
        self.monitor = NWPathMonitor()
    }

    /// Start observing network path changes.
    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }

            let connected = path.status == .satisfied
            let type = self.mapConnectionType(path)
            let expensive = path.isExpensive
            let constrained = path.isConstrained

            // Dispatch to main for @Observable property updates
            DispatchQueue.main.async {
                let wasConnected = self.isConnected
                self.isConnected = connected
                self.connectionType = type
                self.isExpensive = expensive
                self.isConstrained = constrained

                if wasConnected != connected {
                    self.logger.info("Network connectivity changed: \(connected ? "online" : "offline") (\(type.rawValue))")
                    self.onConnectivityChanged?(connected)
                }
            }
        }
        monitor.start(queue: queue)
        logger.info("NetworkMonitor started")
    }

    /// Stop observing.
    func stop() {
        monitor.cancel()
        logger.info("NetworkMonitor stopped")
    }

    // MARK: - Private

    private func mapConnectionType(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .wiredEthernet
        } else {
            return .unknown
        }
    }
}
