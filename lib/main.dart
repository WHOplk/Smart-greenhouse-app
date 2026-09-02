import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // ✅ เพิ่ม Firebase Core
import 'screen/home.dart'; // นำเข้า home.dart

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // ✅ ต้องใส่ก่อนเรียก Firebase.initializeApp()
  await Firebase.initializeApp(); // ✅ เรียก Firebase ก่อนใช้งาน Firestore
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Greenhouse',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: HomeScreen(), // ใช้ HomeScreen ที่แยกไป
    );
  }
}
