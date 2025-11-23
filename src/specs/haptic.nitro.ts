import type { HybridObject } from 'react-native-nitro-modules'

export interface Haptic extends HybridObject<{ ios: 'swift' }> {
  play(duration: number): void
}
