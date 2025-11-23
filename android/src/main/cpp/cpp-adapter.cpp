#include <jni.h>
#include "NitroHapticOnLoad.hpp"

JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM* vm, void*) {
  return margelo::nitro::haptic::initialize(vm);
}
