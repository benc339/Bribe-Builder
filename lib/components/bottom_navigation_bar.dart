import 'package:flutter/material.dart';

BottomNavigationBar buildBottomNavigationBar(onTabTapped, _currentIndex) {
  return BottomNavigationBar(
    showSelectedLabels: false,
    showUnselectedLabels: false,
    onTap: onTabTapped, // new
    currentIndex: _currentIndex, // new
    backgroundColor: Colors.blueGrey[200],
    items: [
      new BottomNavigationBarItem(
        icon: Icon(
          Icons.home,
          color: _currentIndex == 0 ? Colors.blue : Colors.black54,
        ),
        label: 'Home',
      ),
      new BottomNavigationBarItem(
        icon: Icon(
          Icons.view_list,
          color: _currentIndex == 1 ? Colors.blue : Colors.black54,
        ),
        label: '',
      ),
      new BottomNavigationBarItem(
        icon: Icon(
          Icons.videocam,
          color: _currentIndex == 2 ? Colors.blue : Colors.black54,
        ),
        label: '',
      )
    ],
  );
}
