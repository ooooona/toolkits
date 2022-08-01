#include "com_jni_Cat.h"

#include <string>
#include <cstring>


JNIEXPORT void JNICALL Java_com_jni_Cat_say
  (JNIEnv *env, jobject obj) {
  printf("miaomiao~~\n");
}

JNIEXPORT jstring JNICALL Java_com_jni_Cat_follow
  (JNIEnv *env, jobject obj, jstring jstr) {
  const char* icstr = env->GetStringUTFChars(jstr, JNI_FALSE);
  std::string str(icstr);
  env->ReleaseStringUTFChars(jstr, icstr);
  str += " world!";
  const char* ocstr = str.c_str();
  jstring out = env->NewStringUTF(ocstr);
  return out;
}

