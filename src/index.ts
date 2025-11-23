import { NitroModules } from 'react-native-nitro-modules'
import type { Haptic as HapticSpec } from './specs/haptic.nitro'

export const Haptic = NitroModules.createHybridObject<HapticSpec>('Haptic')
