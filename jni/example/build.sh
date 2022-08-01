#!/bin/bash

workspace=$(cd `dirname $0`; pwd) 

cd "${workspace}/java"
javac -d . Cat.java
javah com.jni.Cat
echo "ls -laihR ${workspace}/java"
ls -laihR ${workspace}/java

mv com_jni_Cat.h "${workspace}/cpp"

cd "${workspace}/cpp"
g++ com_jni_Cat.cpp -fPIC -I /data/src/jdk1.8.0/include/linux/ -I /data/src/jdk1.8.0/include/ -shared -o /tmp/libcat.so
echo "ls -laihR ${workspace}/cpp"
ls -laihR ${workspace}/cpp
echo "ls -laihR /tmp/libcat.so"
ls -laihR /tmp/libcat.so

cd "${workspace}/java"
javac -d . Main.java
echo "ls -laihR ${workspace}/java"
ls -laihR ${workspace}/java

echo "java com.jni.Main:"
java com.jni.Main
