import 'package:flutter/material.dart';

import 'src/ui/game_screen.dart';

void main() => runApp(const LeadersApp());

class LeadersApp extends StatelessWidget {
  const LeadersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Leaders',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E6FDB),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const GameScreen(),
    );
  }
}
