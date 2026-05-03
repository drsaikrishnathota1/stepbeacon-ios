import CoreMotion
import Foundation

@MainActor
final class MotionAccessManager: ObservableObject {
    @Published private(set) var authorizationState: MotionAuthorizationState = .unknown
    @Published private(set) var isStepCountingAvailable = CMPedometer.isStepCountingAvailable()
    @Published private(set) var isFloorCountingAvailable = CMPedometer.isFloorCountingAvailable()
    @Published private(set) var isPaceAvailable = CMPedometer.isPaceAvailable()

    init() {
        refreshStatus()
    }

    func refreshStatus() {
        isStepCountingAvailable = CMPedometer.isStepCountingAvailable()
        isFloorCountingAvailable = CMPedometer.isFloorCountingAvailable()
        isPaceAvailable = CMPedometer.isPaceAvailable()
        authorizationState = Self.currentState()
    }

    static func currentState() -> MotionAuthorizationState {
        guard CMPedometer.isStepCountingAvailable() else {
            return .unavailable
        }

        switch CMPedometer.authorizationStatus() {
        case .authorized:
            return .authorized
        case .denied:
            return .denied
        case .restricted:
            return .restricted
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .unknown
        }
    }
}
