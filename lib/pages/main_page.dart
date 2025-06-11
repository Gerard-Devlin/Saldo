import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import 'detail_page.dart';
import 'ai_page.dart';
import 'search_page.dart';
import '../widgets/custom_animated_bottom_bar.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    DashboardPage(),
    DetailPage(),
    SearchPage(),
    AiPage(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: CustomAnimatedBottomBar(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemTapped,
        backgroundColor: Colors.black,
        itemCornerRadius: 28,
        containerHeight: 50.0,
        items: <MyBottomNavigationBarItem>[
          MyBottomNavigationBarItem(
            icon: const Icon(Icons.home),
            title: const Text('Home'),
            activeColor: const Color(0xFF64B5F6),
            inactiveColor: Colors.white54,
          ),
          MyBottomNavigationBarItem(
            icon: const Icon(Icons.apps),
            title: const Text('Detail'),
            activeColor: const Color(0xFF81C784),
            inactiveColor: Colors.white54,
          ),
          MyBottomNavigationBarItem(
            icon: const Icon(Icons.search),
            title: const Text('Search'),
            activeColor: const Color(0xFFBA68C8),
            inactiveColor: Colors.white54,
          ),
          MyBottomNavigationBarItem(
            icon: const Icon(Icons.auto_awesome),
            title: const Text('AI'),
            activeColor: const Color(0xFFFFB74D),
            inactiveColor: Colors.white54,
          ),
        ],
      ),
    );
  }
}
