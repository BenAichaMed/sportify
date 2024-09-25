import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sportify1/screens/challenges_list.dart';
import 'package:sportify1/screens/feed_screen.dart';
import 'package:sportify1/screens/profile_screen.dart';

import '../screens/map_screen.dart';

class MyAppState extends ChangeNotifier {
  String _currentUserUID = FirebaseAuth.instance.currentUser?.uid ?? '';

  MyAppState() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _currentUserUID = user.uid;
      } else {
        _currentUserUID = '';
      }
      notifyListeners();
    });
  }

  String get currentUserUID => _currentUserUID;
}

final MyAppState appState = MyAppState();

const webScreenSize = 600;

List<Widget> homeScreenItems(BuildContext context) {
  return [
    const FeedScreen(),
    const MapScreen(),
    const ChallengesListScreen(),
    const Text('notifications'),
    ProfileScreen(uid: appState.currentUserUID),
  ];
}
