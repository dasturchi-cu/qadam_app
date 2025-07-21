import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'challenges_screen.dart';
import 'shop_screen.dart';
import 'referral_screen.dart';
import 'notifications_screen.dart';

class MainNavigation extends StatefulWidget {
  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    HomeScreen(),
    ChallengesScreen(),
    ShopScreen(),
    ReferralScreen(),
    NotificationsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Color(0xFF4CAF50),
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Bosh sahifa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: 'Challenge\'lar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Do\'kon',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Referral',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Xabarlar',
          ),
        ],
      ),
    );
  }
}