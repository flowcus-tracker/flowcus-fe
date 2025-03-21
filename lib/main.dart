import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flowcus_fe/pages/calendar_page.dart';
import 'package:flowcus_fe/pages/leaderboard_page.dart';
import 'package:flowcus_fe/pages/report_page.dart';
import 'package:flowcus_fe/pages/task_page.dart';
import 'package:flowcus_fe/pages/timer_page.dart';
import 'package:flowcus_fe/pages/task_provider.dart'
    as provider; // Added prefix

void main() => runApp(
      ChangeNotifierProvider(
        create: (context) => provider.TaskProvider(),
        child: MyApp(),
      ),
    );

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flow Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      home: MainLayout(),
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    TimerPage(),
    TasksPage(),
    CalendarPage(),
    LeaderboardPage(),
    ReportPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _pages[_currentIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.timer), label: 'Timer'),
          BottomNavigationBarItem(icon: Icon(Icons.task), label: 'Tasks'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today), label: 'Calendar'),
          BottomNavigationBarItem(
              icon: Icon(Icons.leaderboard), label: 'Leaderboard'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Report'),
        ],
      ),
    );
  }
}
