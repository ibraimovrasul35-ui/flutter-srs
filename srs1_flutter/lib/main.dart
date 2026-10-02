import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Моё первое приложение',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.teal),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        title: const Text('Первое Flutter-приложение'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            // Container с цветом, отступами, скруглёнными углами и тенью
            Container(
              width: 300,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.teal, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Text(
                'Привет, Flutter!',
                textAlign: .center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: .bold,
                  color: Colors.teal,
                ),
              ),
            ),
            // Container фиксированного размера с выравниванием текста
            Container(
              width: 300,
              height: 100,
              alignment: .center,
              color: Colors.orange.shade200,
              child: const Text(
                'Лабораторная работа №1:\nвиджеты Text и Container',
                textAlign: .center,
                style: TextStyle(fontSize: 18, fontStyle: .italic),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Основы разработки приложений на Flutter',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
