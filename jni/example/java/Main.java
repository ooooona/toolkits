package com.jni;

public class Main {
 private Cat cat;
 static {
 System.load("/tmp/libcat.so");
 }
 
 public static void main(String...args) {
  Cat cat = new Cat();
  cat.say();
  System.out.println("jni: " + cat.follow("hello"));
 }
}
