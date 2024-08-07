import 'package:flutter/widgets.dart';

import 'package:sportify1/models/user.dart';
import 'package:sportify1/resources/auth_methods.dart';

class UserProvider with ChangeNotifier {
  User? _user;
  final AuthMethods _authMethods = AuthMethods();

  User? get getUser => _user;

  Future<void> refreshUser() async {
    try {
      User user = await _authMethods.getUserDetails();
      _user = user;
      notifyListeners();
    } catch (e) {
      _user = null;
      notifyListeners();
      print("Failed to refresh user: $e");
    }
  }
}