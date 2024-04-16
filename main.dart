import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:tradesync/firebase_options.dart';
import 'package:tradesync/homescreen.dart';
import 'package:tradesync/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VetInspect',
      home: Login(),
    );
  }
}
