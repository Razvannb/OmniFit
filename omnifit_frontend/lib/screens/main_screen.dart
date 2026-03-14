import 'package:flutter/material.dart';
import 'workout_screen.dart'; // Importăm ecranul de antrenament creat de tine

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Setăm indexul inițial la 1 (Workouts), exact ca în imaginea ta
  int _selectedIndex = 1;

  // Aici definim lista de ecrane care se vor schimba când apeși pe tab-uri
  final List<Widget> _screens = [
    const Center(child: Text('Home Dashboard', style: TextStyle(fontSize: 24))), // 0: Home
    const WorkoutScreen(),                                                       // 1: Workouts
    const Center(child: Text('Calories Tracker', style: TextStyle(fontSize: 24))),// 2: Calories
    const Center(child: Text('Goals & Progress', style: TextStyle(fontSize: 24))),// 3: Goals
    const Center(child: Text('AI Form Check', style: TextStyle(fontSize: 24))),   // 4: Form Check
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Afișăm ecranul corespunzător indexului selectat
      body: _screens[_selectedIndex],
      
      // Bara de navigație de jos
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Esențial pentru a afișa toate cele 5 tab-uri corect
        backgroundColor: Colors.white,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blueAccent, // Culoarea din imagine pentru cel activ
        unselectedItemColor: Colors.grey,     // Culoarea pentru cele inactive
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
        elevation: 8, // O mică umbră deasupra barei
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center_outlined),
            activeIcon: Icon(Icons.fitness_center),
            label: 'Workouts',
          ),
          BottomNavigationBarItem(
            // Am înlocuit mărul cu o iconiță stabilă de Nutriție/Calorii
            icon: Icon(Icons.restaurant_outlined), 
            activeIcon: Icon(Icons.restaurant),
            label: 'Calories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.track_changes_outlined),
            activeIcon: Icon(Icons.track_changes),
            label: 'Goals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt_outlined),
            activeIcon: Icon(Icons.camera_alt),
            label: 'Form Check',
          ),
        ],
      ),
    );
  }
}