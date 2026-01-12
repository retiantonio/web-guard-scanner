import 'package:flutter/material.dart';
import 'package:flutter_1/pages/LoginPage.dart';
import 'package:provider/provider.dart';
import 'package:flutter_1/state/ScoreController.dart';
import 'package:flutter_1/state/AuthController.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ScoreController()),
        ChangeNotifierProvider(create: (_) => AuthController()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}
