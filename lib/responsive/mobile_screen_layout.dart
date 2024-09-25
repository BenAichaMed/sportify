import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sportify1/utils/colors.dart';
import 'package:sportify1/utils/global_variable.dart';


class MobileScreenLayout extends StatefulWidget {
  const MobileScreenLayout({super.key});

  @override
  State<MobileScreenLayout> createState() => _MobileScreenLayoutState();
}


class _MobileScreenLayoutState extends State<MobileScreenLayout> {
  int _page = 0;
  late PageController pageController; // for tabs animation

  @override
  void initState() {
    super.initState();
    pageController = PageController();
  }


  @override
  void dispose() {
    super.dispose();
    pageController.dispose();
  }

  void onPageChanged(int page) {
    setState(() {
      _page = page;
    });
  }

  void navigationTapped(int page) {
    //Animating Page
    pageController.jumpToPage(page);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: PageView(
        controller: pageController,
        onPageChanged: onPageChanged,
        children: homeScreenItems(context),
      ),
      bottomNavigationBar: CupertinoTabBar(
        backgroundColor: mobileBackgroundColor,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home,
              color: (_page == 0) ? Colors.orange : secondaryColor,
            ),
            label: 'home',
            backgroundColor: primaryColor,
          ),
          BottomNavigationBarItem(
              icon: Icon(
                Icons.map_rounded,
                color: (_page == 1) ? Colors.orange : secondaryColor,
              ),
              label: 'maps',
              backgroundColor: primaryColor),
          BottomNavigationBarItem(
              icon: Icon(
                Icons.sports_score_rounded,
                color: (_page == 2) ? Colors.orange : secondaryColor,
              ),
              label: 'challenge',
              backgroundColor: primaryColor),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.favorite,
              color: (_page == 3) ? Colors.orange : secondaryColor,
            ),
            label: 'favorite',
            backgroundColor: primaryColor,
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.person,
              color: (_page == 4) ? Colors.orange : secondaryColor,
            ),
            label: 'profile',
            backgroundColor: primaryColor,
          ),
        ],
        onTap: navigationTapped,
        currentIndex: _page,
      ),
    );
  }
}
