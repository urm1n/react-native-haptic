import Foundation
import CoreHaptics

class HybridHaptic: HybridHapticSpec {

  private var engine: CHHapticEngine?
  private var player: CHHapticAdvancedPatternPlayer?
  private let engineQueue = DispatchQueue(label: "haptic.engine.queue")

  override init() {
    super.init()
    prepareEngine()
  }

  private func prepareEngine() {
    engineQueue.async { [weak self] in
      guard let self = self else { return }

      do {
        self.engine = try CHHapticEngine()
        self.engine?.isAutoShutdownEnabled = false

        self.engine?.stoppedHandler = { reason in
          print("❌ Haptic engine stopped:", reason.rawValue)
        }

        self.engine?.resetHandler = { [weak self] in
          print("⚡️ Haptic engine reset")
          self?.prepareEngine()
        }

        try self.engine?.start()
      } catch {
        print("❌ Failed to start haptic engine:", error)
      }
    }
  }

  // MARK: - play(duration)
  func play(duration: Double) throws {
    engineQueue.async { [weak self] in
      guard let self = self else { return }

      self.stopInternal() // stop any previous running pattern

      guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
        print("⚠️ Device does not support CoreHaptics")
        return
      }

      do {
        // Build continuous haptic pattern
        let event = CHHapticEvent(
          eventType: .hapticContinuous,
          parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
          ],
          relativeTime: 0,
          duration: duration / 1000.0 // convert ms → seconds
        )

        let pattern = try CHHapticPattern(events: [event], parameters: [])
        self.player = try self.engine?.makeAdvancedPlayer(with: pattern)

        try self.engine?.start()
        try self.player?.start(atTime: CHHapticTimeImmediate)

      } catch {
        print("❌ Haptic play error:", error)
      }
    }
  }

  // MARK: - stop()
  func stop() throws {
    engineQueue.async { [weak self] in
      self?.stopInternal()
    }
  }

  private func stopInternal() {
    do {
      try player?.stop(atTime: CHHapticTimeImmediate)
      player = nil
    } catch {
      print("⚠️ Could not stop haptic:", error)
    }
  }
}
