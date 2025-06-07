import 'package:flutter/material.dart';
import 'pages/dashboard_page.dart';


void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      theme: ThemeData.dark(),
      home: const DashboardPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}