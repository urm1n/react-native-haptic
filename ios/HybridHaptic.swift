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

        self.stopInternal()

        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        do {
          let seconds = duration / 1000.0

          // ---- Intensity Curve (0 → 0.6) ----
          let intensityCurve = CHHapticParameterCurve(
              parameterID: .hapticIntensityControl,
              controlPoints: [
                  CHHapticParameterCurve.ControlPoint(relativeTime: 0.0, value: 0.0),
                  CHHapticParameterCurve.ControlPoint(relativeTime: seconds * 0.25, value: 0.25),
                  CHHapticParameterCurve.ControlPoint(relativeTime: seconds * 0.5, value: 0.45),
                  CHHapticParameterCurve.ControlPoint(relativeTime: seconds * 1.0, value: 0.6)
              ],
              relativeTime: 0
          )

          // ---- Sharpness Curve (0.1 → 0.3) ----
          let sharpnessCurve = CHHapticParameterCurve(
              parameterID: .hapticSharpnessControl,
              controlPoints: [
                  .init(relativeTime: 0.0, value: 0.1),
                  .init(relativeTime: seconds * 0.5, value: 0.2),
                  .init(relativeTime: seconds * 1.0, value: 0.3)
              ],
              relativeTime: 0
          )

          // Continuous event (baseline)
          let event = CHHapticEvent(
              eventType: .hapticContinuous,
              parameters: [],
              relativeTime: 0,
              duration: seconds
          )

          let pattern = try CHHapticPattern(
              events: [event],
              parameterCurves: [intensityCurve, sharpnessCurve]
          )

          self.player = try self.engine?.makeAdvancedPlayer(with: pattern)
          try self.engine?.start()
          try self.player?.start(atTime: 0)

        } catch {
          print("Haptic error:", error)
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
