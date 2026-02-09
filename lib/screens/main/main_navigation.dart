import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../utils/constants.dart';
import '../home/home_screen.dart';
import '../offers/my_offers_screen.dart';
import '../chat/chat_list_screen.dart';
import '../profile/profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    MyOffersScreen(),
    ChatListScreen(),
    ProfileScreen(),
  ];

  final List<String> _titles = [
    'Home',
    'My Offers',
    'Messages',
    'Profile',
  ];

  final List<IconData> _icons = [
    Icons.home,
    Icons.local_taxi,
    Icons.chat,
    Icons.person,
  ];

  final List<IconData> _activeIcons = [
    Icons.home_filled,
    Icons.local_taxi,
    Icons.chat_bubble,
    Icons.person,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          _buildNavItem(0),
          _buildNavItem(1),
          _buildNavItemWithBadge(2),
          _buildNavItem(3),
        ],
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(int index) {
    return BottomNavigationBarItem(
      icon: Icon(_icons[index]),
      activeIcon: Icon(_activeIcons[index]),
      label: _titles[index],
    );
  }

  BottomNavigationBarItem _buildNavItemWithBadge(int index) {
    return BottomNavigationBarItem(
      icon: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          final unreadCount = chatProvider.getUnreadCount();
          return unreadCount > 0
              ? Badge(
                  label: Text(unreadCount.toString()),
                  child: Icon(_icons[index]),
                )
              : Icon(_icons[index]);
        },
      ),
      activeIcon: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          final unreadCount = chatProvider.getUnreadCount();
          return unreadCount > 0
              ? Badge(
                  label: Text(unreadCount.toString()),
                  child: Icon(_activeIcons[index]),
                )
              : Icon(_activeIcons[index]);
        },
      ),
      label: _titles[index],
    );
  }
}
