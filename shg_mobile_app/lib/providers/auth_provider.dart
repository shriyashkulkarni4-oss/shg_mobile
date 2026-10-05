import 'package:flutter/foundation.dart';

class AuthProvider extends ChangeNotifier {
  String? shgId;
  String? userRole;
  String? userName;

  void setAuthData({required String shgId, required String userRole, required String userName}) {
    this.shgId = shgId;
    this.userRole = userRole;
    this.userName = userName;
    notifyListeners();
  }
  
  void clear() {
    shgId = null;
    userRole = null;
    userName = null;
    notifyListeners();
  }
}
