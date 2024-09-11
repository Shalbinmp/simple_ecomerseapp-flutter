import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:infinity_scrolling_project/screens/news_scrolling.dart';
import 'package:infinity_scrolling_project/screens/profile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            alignment: Alignment.center,
            child: Text(
              'HomeScreen',
              style: TextStyle(fontWeight: FontWeight.w400, fontSize: 30),
            ),
          )
        ],
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final PageController _pageController = PageController();
  int selectedIndex = 0;

  final List<Widget> _pages = [
    HomeScreen(),
    ScrollingPage(),
    Profile(),
  ];

  void onPageChanged(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  void onItemTapped(int index) {
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: onPageChanged,
        children: _pages,
      ),
      bottomNavigationBar: BuildBottomUI(),
    );
  }

  Widget BuildBottomUI() {
    var size = MediaQuery.of(context).size;
    var height = size.height;
    var width = size.width;

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity! > 0) {
          // Swiped right
          setState(() {
            selectedIndex = (selectedIndex - 1).clamp(0, 2);
            onItemTapped(selectedIndex);
          });
        } else if (details.primaryVelocity! < 0) {
          // Swiped left
          setState(() {
            selectedIndex = (selectedIndex + 1).clamp(0, 2);
            onItemTapped(selectedIndex);
          });
        }
      },
      child: Container(
        color: Colors.blueGrey[50],
        height: height * 0.12,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildIcon(Icons.home, 0),
            _buildIcon(Icons.store, 1),
            _buildIcon(Icons.person, 2),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(IconData icon, int index) {
    return GestureDetector(
      onTap: () {
        onItemTapped(index);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: selectedIndex == index ? Colors.black87 : Colors.blueGrey[50],
        ),
        padding: EdgeInsets.all(15),
        child: Icon(
          icon,
          color: selectedIndex == index ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}
