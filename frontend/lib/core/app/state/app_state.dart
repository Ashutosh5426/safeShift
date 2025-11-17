import 'package:flutter/cupertino.dart';
import 'package:frontend/core/app/local_storage/local_storage.dart';
import 'package:frontend/core/constants/constants.dart';
import 'package:frontend/core/shared_preferences/storage_constants.dart';
import 'package:frontend/feature/authentication/data/models/user_response_model.dart';
import 'package:injectable/injectable.dart';

enum LoggedState { loggedOut, loggedIn }

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

  String get userId => LocalStorage.getString(StorageConstants.userId) ?? '';

  String get username =>
      LocalStorage.getString(StorageConstants.username) ?? '';

  String get email => LocalStorage.getString(StorageConstants.userEmail) ?? '';

  String get profileImage =>
      LocalStorage.getString(StorageConstants.profileImage) ?? '';

  String get userPhoneNo =>
      LocalStorage.getString(StorageConstants.userPhoneNo) ?? '';

  Future<void> logOut() async {
    _loggedInState = LoggedState.loggedOut;

    await LocalStorage.clear(whiteList: []);

    notifyListeners();
  }

  Future<bool> setUserPreferences(UserResponseModel user) async {
    final id = await LocalStorage.setString(StorageConstants.userId, user.id);
    final name = await LocalStorage.setString(
      StorageConstants.username,
      user.name,
    );
    final email = await LocalStorage.setString(
      StorageConstants.userEmail,
      user.email,
    );
    final photo = await LocalStorage.setString(
      StorageConstants.profileImage,
      user.photo ?? '',
    );
    final phone = await LocalStorage.setString(
      StorageConstants.userPhoneNo,
      user.mobileNo ?? '',
    );
    return id && name && email && photo && phone;
  }
}
