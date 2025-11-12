import 'package:flutter/cupertino.dart';
import 'package:frontend/core/app/local_storage/local_storage.dart';
import 'package:frontend/core/constants/constants.dart';
import 'package:injectable/injectable.dart';

enum LoggedState {
  loggedOut,
  loggedIn,
}

@singleton
class AppState extends ChangeNotifier {
  LoggedState _loggedInState = LoggedState.loggedOut;

  Future<void> logIn() async {
    _loggedInState = LoggedState.loggedIn;
    await LocalStorage.setBool(SHARED_PREFS_ISLOGGEDIN, true);
    notifyListeners();
  }

  LoggedState get loggedInState {
    final isLoggedIn = LocalStorage.getBool(SHARED_PREFS_ISLOGGEDIN) ?? false;
    _loggedInState = isLoggedIn ? LoggedState.loggedIn : LoggedState.loggedOut;
    return _loggedInState;
  }

  Future<void> logOut() async {
    _loggedInState = LoggedState.loggedOut;

    await LocalStorage.clear(
      whiteList: [
      ],
    );

    notifyListeners();
  }
}