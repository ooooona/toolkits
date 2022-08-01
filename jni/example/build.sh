#!/bin/bash

workspace=$(cd `dirname $0`; pwd) 
javajdk="/data/src/jdk1.8.0"

ARGS=`getopt -o j: --long java: -n "$0" -- "$@"`

eval set -- "${ARGS}"

while true
do
    case $1 in
        -j | --java)
           javajdk=$2; shift 2
            ;;
        *)
            break
            ;;
    esac
done

echo "java jdk path: ${javajdk}"

cd "${workspace}/java"
javac -d . Cat.java
javah com.jni.Cat
echo "ls -laihR ${workspace}/java"
ls -laihR ${workspace}/java

mv com_jni_Cat.h "${workspace}/cpp"

cd "${workspace}/cpp"
echo "g++ com_jni_Cat.cpp -fPIC -I \"${javajdk}/include/linux/\" -I \"${javajdk}/include/\" -shared -o /tmp/libcat.so:"
g++ com_jni_Cat.cpp -fPIC -I "${javajdk}/include/linux/" -I "${javajdk}/include/" -shared -o /tmp/libcat.so
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
