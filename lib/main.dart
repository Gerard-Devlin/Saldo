import 'package:flutter/material.dart';
import 'pages/main_page.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Saldo',
      theme: ThemeData.dark(),
      home: const MainPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
