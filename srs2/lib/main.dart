import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Lab3Screen(),
    );
  }
}

class Lab3Screen extends StatelessWidget {
  const Lab3Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 2. Цвет фона всего приложения
      backgroundColor: Colors.grey[300], 
      
      // 1. AppBar с заголовком и стилем
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: const Text(
          'Lab 3: Layout Basics',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20.0,
          ),
        ),
      ),
      
      // Чтобы контейнеры не прилипали к краям экрана, добавим общий отступ
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        // 3. Макет основной части (Body) - Column
        child: Column(
          children: [
            
            // 4, 5, 6. Первый контейнер
            Container(
              padding: const EdgeInsets.all(16.0), // Внутренний отступ
              alignment: Alignment.center, // Выравнивание по центру
              decoration: BoxDecoration(
                color: Colors.blue, // Синий цвет фона
                borderRadius: BorderRadius.circular(12.0), // Радиус скругления 12
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2), // Тень с прозрачностью
                    offset: const Offset(2, 2), // Смещение
                    blurRadius: 6.0, // Размытие
                  ),
                ],
              ),
              child: const Text(
                'Welcome to Flutter!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            // Отступ между контейнерами (часть пункта 3)
            const SizedBox(height: 16.0),
            
            // 7, 8, 9, 10, 11. Второй контейнер
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0), // Отступы 12 и 20
              decoration: BoxDecoration(
                color: Colors.green, // Зеленый цвет фона
                borderRadius: BorderRadius.circular(8.0), // Радиус скругления 8
                border: Border.all(
                  color: Colors.white, // Белая рамка
                  width: 2.0, // Толщина рамки 2
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // Расположение по противоположным краям
                children: [
                  Text(
                    'Left Text',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.0,
                    ),
                  ),
                  Text(
                    'Right Text',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.0,
                    ),
                  ),
                ],
              ),
            ),
            
          ],
        ),
      ),
    );
  }
}